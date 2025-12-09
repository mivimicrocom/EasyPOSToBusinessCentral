# Synkronisering 4: Finansposter (Financial Records)

**Metode:** `DoSyncronizeFinansCialRecords`  
**Retning:** EasyPOS → Business Central  
**API Endpoint:** `kmCashstatement`  
**Aktiveres via INI:** `[SYNCRONIZE] FinancialRecords=1`

---

## Formål

Synkroniserer kassekladde og finansposter fra EasyPOS til Business Central.

Dette omfatter:
- Omsætning og fragt
- Debitor betalinger/tilgodehavender
- Indbetalinger og udbetalinger
- Afrunding og differencer
- Forskydninger mellem konti
- Aconto betalinger
- Tilgodesedler og gavekort

---

## Arbejdsflow

```
1. Hent finansposter siden sidste kørsel
2. For hver post:
   ├─ Check om allerede findes i BC (via ID)
   ├─ Hvis ikke:
   │  ├─ Map PostType til BC Type (0=Finans, 1=Debitor, 2=Bank)
   │  ├─ Opret i BC (kmCashstatement)
   │  └─ Gem til eksport-fil (CSV)
   ├─ Marker som eksporteret (BEHANDLET + 1)
   └─ Opdater Last run til seneste dato
3. Log resultat i SLADREHANK
4. Send email ved fejl
```

---

## SQL Query - Hent Finansposter

**Kilde:** `UDM.dfm` linje 38-90

```sql
SELECT
    POSTERINGER.AFDELING_ID,
    POSTERINGER.UAFD_GRP_NAVN,
    POSTERINGER.UAFD_NAVN,
    POSTERINGER.DATO,
    POSTERINGER.ID,
    POSTERINGER.BEHANDLET,
    POSTERINGER.KONTOTYPE,
    POSTERINGER.KONTONR,
    POSTERINGER.BILAGSNR,
    CAST('' AS VARCHAR(30)) AS BILAGSNR2,
    POSTERINGER.AFDELING,
    POSTERINGER.MODKONTO,
    
    -- Tekst med valuta-information hvis relevant
    CASE WHEN POSTERINGER.VALUTA = 0 THEN
        POSTERINGER.TEKST
    ELSE 
        POSTERINGER.TEKST || ' (' || 
        ROUND((POSTERINGER.BELOB / POSTERINGER.VALUTA) * 100, 2) || ')'
    END AS TEKST,
    
    POSTERINGER.BELOB,
    POSTERINGER.MOMSKODE,
    POSTERINGER.MODBILAG,
    POSTERINGER.VALUTA,
    POSTERINGER.VALUTAKODE,
    POSTERINGER.POSTTYPE,
    POSTERINGER.SORTERING

FROM POSTERINGER
WHERE
    POSTERINGER.BELOB <> 0
    AND POSTERINGER.DATO >= :PSTARTDATO
    AND POSTERINGER.DATO <= :PSLUTDATO
    AND POSTERINGER.BEHANDLET = 0
    AND CHAR_LENGTH(POSTERINGER.AFDELING_ID) = 3
ORDER BY
    POSTERINGER.DATO ASC
```

**Parametre:**
- `:PSTARTDATO` - Fra dato
- `:PSLUTDATO` - Til dato (NOW)

**Vigtige filtre:**
- `BELOB <> 0` - Spring over nul-poster
- `BEHANDLET = 0` - Kun ikke-eksporterede
- `CHAR_LENGTH(AFDELING_ID) = 3` - Kun gyldige afdelinger

---

## PostType Mapping (Kritisk!)

**EasyPOS PostType → BC Type:**

| PostType | EasyPOS Navn | BC Type | BC Type Navn | Konto/ID Felt |
|---|---|---|---|---|
| 0 | Finans | '0' | Finans | KontoNr |
| 25 | Fragt | '0' | Finans | KontoNr |
| 1 | Debitor | '1' | Debitor | KontoNr (debitor nr) |
| 3 | Indbetalinger | '1' | Debitor | KontoNr (debitor nr) |
| 4 | Udbetalinger | '0' | Finans | KontoNr (finanskonto) |
| 4 + KontoNr=86123444 | Udbetalinger (special) | '2' | Bank | '86123444' |
| 5 | Afrunding | '0' | Finans | KontoNr |
| 7 | Differencer | '0' | Finans | KontoNr |
| 8 | Forskydning | '0' | Finans | KontoNr |
| 21 | Aconto | '1' | Debitor | KontoNr (debitor nr) |
| 22 (SORTERING=50) | Tilgodeseddel modtaget | '0' | Finans | KontoNr |
| 22 (andre) | Tilgodeseddel udstedt | '0' | Finans | KontoNr |
| 23 (SORTERING=120) | Gavekort modtaget | '0' | Finans | KontoNr |
| 23 (andre) | Gavekort udstedt | '0' | Finans | KontoNr |
| 99 | Internt afdelingssalg | '0' | Finans | KontoNr |

**Særlig regel for udbetalinger:**
```pascal
if (PostType = 4) then
begin
  type_ := '0';  // Finans
  if (KontoNr = '86123444') then
    type_ := '2';  // Bank (special case)
end;
```

---

## Data Mapping

### kmCashstatement

| EasyPOS Felt | BC Felt | Type | Mapping | Note |
|---|---|---|---|---|
| (Transaction ID) | transId | Integer | Fra GETNAVISION_TRANSID | |
| ID | epId | Integer | Direkte | Unik nøgle |
| NOW | transDato | String | dd-mm-yyyy | Transaction date |
| NOW | transTid | String | hh:mm:ss | Transaction time |
| DATO | bogfRingsDato | String | dd-mm-yyyy | Posteringsdato |
| DATO | kasseOpgRelsestidspunkt | String | hh:mm:ss | Kassekladde tid |
| BILAGSNR | bilagsnummer | String | Direkte | Bilagsnummer |
| TEKST | text | String | Max 50 chars | Tekst (truncated) |
| (Se mapping) | type_ | String | Fra PostType | 0/1/2 |
| KONTONR | id | String | Trim() | Konto/Debitor nr |
| UAFD_NAVN | kasse | String | Direkte | Kassenavn |
| AFDELING | afdeling | String | Direkte | Afdelingsnavn |
| BELOB | belB | Double | Direkte | Beløb |
| (Se funktion) | butik | String | Via GetButiksID() | BC Butik ID |
| '0' | status | String | Hardcoded | Ubehandlet |

**GetButiksID Funktion:**
```sql
SELECT NAVISION_IDX 
FROM AFDELING 
WHERE AFDELINGSNUMMER = :PAfdeling_ID
```

---

## Eksport til CSV Fil

**Fil:** `[LogFolder]\FinansEksport\EkspFinancialRecordsToBC[YYYYMMDDHH].txt`

**Format:** Semikolon-separeret

**Kolonner:**
```
EpID;TransID;TransDato;TransTid;BogføringsDato;BogføringsTid;Bilagsnummer;
Tekst;Type;ID;Maskine;Afdeling;Butik;Beløb
```

**Eksempel:**
```
12345;1234567;09-12-2025;13:45:30;08-12-2025;14:23:00;BIL001;
Salg kontant;0;1000;Kasse 1;001;SHOP01;1250.50
```

**Formål:** Backup og sporbarhed af eksporterede poster.

---

## SQL Query - Marker som Eksporteret

```sql
UPDATE Posteringer 
SET Behandlet = Behandlet + 1 
WHERE Posteringer.id = :PID
```

**Parametre:**
- `:PID` - Posteringens ID

**Note:** Tæller op ved hver eksport (sporbarhed).

---

## Business Central API Calls

### 1. Check om post eksisterer

**Metode:** GET  
**Endpoint:** `/kmCashstatement?$filter=epId eq {ID}`

**Response:**
- 200 OK med `value: []` = Findes IKKE
- 200 OK med `value: [{...}]` = Findes ALLEREDE (skip)

### 2. Opret finanspost

**Metode:** POST  
**Endpoint:** `/kmCashstatement`  
**Content-Type:** application/json

**Request Body Eksempel (Finans):**
```json
{
  "transId": 1234567,
  "epId": 12345,
  "transDato": "09-12-2025",
  "transTid": "13:45:30",
  "bogfRingsDato": "08-12-2025",
  "kasseOpgRelsestidspunkt": "14:23:00",
  "bilagsnummer": "BIL001",
  "text": "Salg kontant",
  "type_": "0",
  "id": "1000",
  "kasse": "Kasse 1",
  "afdeling": "001",
  "butik": "SHOP01",
  "belB": 1250.50,
  "status": "0"
}
```

**Request Body Eksempel (Debitor):**
```json
{
  ...
  "text": "Debitor betaling",
  "type_": "1",
  "id": "10001",
  ...
}
```

---

## Konfiguration (INI Fil)

```ini
[SYNCRONIZE]
FinancialRecords=1         ; Aktivér synkronisering

[FinancialRecords]
Last run=42000.5           ; Sidste succesfulde post's dato
Days to look for records=5 ; Lookback periode
Last time sync to BC was tried=42000.6
```

**Vigtigt:**

```pascal
// Last run opdateres EFTER HVER succesfuld post:
iniFile.WriteDateTime('FinancialRecords', 'Last run', 
  QFetchFinancialRecords.FieldByName('Dato').AsDateTime);
```

**Resultat:** Ved fejl midtvejs kan næste kørsel fortsætte fra sidste succesfulde post.

---

## Tracing Log (SLADREHANK)

### Ved Succes

```sql
ART = 3015  -- 3000 + 15
BONTEXT = 'Finansposter synkroniseret til Business Central OK (Service)'
```

### Ved Fejl

```sql
ART = 3016  -- 3000 + 16
BONTEXT = 'Finansposter IKKE synkroniseret med Business Central (Servive)'
```

---

## Fejlhåndtering

### Logfiler

**Normal log:**
- `[LogFolder]\Log[YYYYMMDD].txt`

**Fejl log:**
- `[LogFolder]\FinancialErrors.txt`
- Omdøbes ved fejl til: `Error_Finansposter_ddmmyyyy_hhmmss.txt`

**Eksport log (CSV):**
- `[LogFolder]\FinansEksport\EkspFinancialRecordsToBC[YYYYMMDDHH].txt`

**SQL debug:**
- `[LogFolder]\SQL\FinancialRecords.SQL`

### Error Scenarios

#### 1. Fejl ved GET (check eksistens)

**Event ID:** 3403  
**Handling:**
- Log fejl
- Stop yderligere behandling
- Send email

#### 2. Fejl ved POST (oprettelse)

**Event ID:** Ingen specifik (generel fejl)  
**Handling:**
- Log fejl med JSON payload
- Post markeres IKKE som behandlet
- Stop yderligere behandling
- Send email

#### 3. Fejl ved markering som behandlet

**Event ID:** 3402  
**Handling:**
- Log database fejl
- Post ER oprettet i BC
- Vil blive sprunget over ved næste kørsel (OK)

### Email Notifikation

**Sendes når:** RoutineCanceled = TRUE

**Indhold:**
- Emne: "EasyPOS-BC Sync Error - Finansposter"
- Tekst: "Der skete en fejl ved synkronisering af finansposter til Business Central"
- Vedhæftning: Fejl-logfil

---

## Specielle Situationer

### Valuta-håndtering

Hvis `VALUTA <> 0`:
```sql
TEKST || ' (' || ROUND((BELOB / VALUTA) * 100, 2) || ')'
```

**Eksempel:**
- BELOB = 1000
- VALUTA = 8
- Resultat: "Betaling (12500.00)"

### Tekst-trunkering

```pascal
if (length(Tekst) > 50) then
  text := Copy(Tekst, 1, 50)
else
  text := Tekst;
```

**Formål:** BC felt er max 50 tegn.

### Gavekort og tilgodesedler

**Modtaget (indløst):**
- SORTERING = 50 (tilgodeseddel) eller 120 (gavekort)
- Type = '0' (Finans)
- Krediteres kunde

**Udstedt:**
- Alle andre SORTERING værdier
- Type = '0' (Finans)
- Debiteres kunde

### Special case: Konto 86123444

Konverteres fra Finans (0) til Bank (2):
```pascal
if (id = '86123444') then
  type_ := '2';
```

**Formål:** Specifik kunde-aftale (Kaufmann?).

---

## Performance

### Optimering

1. **Incremental update:**
   - `Last run` opdateres løbende
   - Ved fejl fortsætter næste kørsel fra sidste succesfulde

2. **Early abort:**
   - Stopper ved første fejl

3. **Kronologisk sortering:**
   - `ORDER BY DATO ASC`

### Forventede Tider

- 500 finansposter: ~3-8 minutter
- Afhænger af BC API responstid

---

## Debug Tips

### Test mode

```ini
[PROGRAM]
TestRoutine=1
```

### SQL Trace

```sql
[LogFolder]\SQL\FinancialRecords.SQL
```

### Manuel re-sync

```sql
-- Reset behandling-flag
UPDATE POSTERINGER 
SET BEHANDLET = 0 
WHERE 
    DATO >= '2025-12-01'
    AND DATO <= '2025-12-31'
    AND BELOB <> 0;
```

### Check eksport fil

```
[LogFolder]\FinansEksport\EkspFinancialRecordsToBC[YYYYMMDDHH].txt
```

---

## Dependencies

### Database Tabeller
- POSTERINGER
- AFDELING (for butik lookup)
- SLADREHANK

### Business Central Tables
- kmCashstatement

### Stored Procedures
- GETNAVISION_TRANSID

---

## Changelog

| Dato | Ændring |
|---|---|
| 2025-12-09 | Dokumentation oprettet |
