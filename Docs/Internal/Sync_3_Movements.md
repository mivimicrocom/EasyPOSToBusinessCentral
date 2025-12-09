# Synkronisering 3: Flytningstransaktioner (Movement Transactions)

**Metode:** `DoSyncronizeMovemmentsTransaction`  
**Retning:** EasyPOS → Business Central  
**API Endpoint:** `kmItemMove`  
**Aktiveres via INI:** `[SYNCRONIZE] MovementsTransactions=1`

---

## Formål

Synkroniserer vareflytninger mellem butikker fra EasyPOS til Business Central.

Dette omfatter:
- Afgange fra én butik (PAKKELINJE 1 og 5)
- Tilgang til anden butik (oprettes separat i BC)
- Vare, antal, kostpris
- Fra/Til butik information

---

## Arbejdsflow

```
1. Hent flytningstransaktioner siden sidste kørsel
2. For hver transaktion:
   ├─ Check om allerede findes i BC (via epId)
   ├─ Hvis ikke: Opret i BC (kmItemMove)
   └─ Marker som eksporteret (EKSPORTERET + 1)
3. Log resultat i SLADREHANK
4. Send email ved fejl
```

---

## SQL Query - Hent Flytningstransaktioner

**Kilde:** `UDM.dfm` linje 317-365

```sql
SELECT
    TR.EKSPORTERET,
    TR.TRANSID AS EPID,
    TR.BONNR AS FLYTNINGSID,
    TR.DATO AS BOGFORINGSDATO,
    TR.TILBUTIK AS TILBUTIK2,
    
    -- Lookup BC ID for modtager butik
    (SELECT
         NAVISION_IDX
     FROM AFDELING
     WHERE
         AFDELINGSNUMMER = TR.TILBUTIK) AS TILBUTIK,
    
    TR.AFDELING_ID AS FRABUTIK2,
    AF.NAVISION_IDX AS FRABUTIK,
    TR.VAREFRVSTRNR AS VAREID,
    VFS.V509INDEX AS VARIANTID,
    TR.SALGSTK AS ANTAL,
    TR.KOSTPR AS KOSTPRIS

FROM TRANSAKTIONER TR
    INNER JOIN AFDELING AF ON
          (AF.AFDELINGSNUMMER = TR.AFDELING_ID)
    LEFT JOIN VAREFRVSTR VFS ON
          (VFS.VAREPLU_ID = TR.VAREFRVSTRNR
          AND VFS.FARVE_NAVN = TR.FARVE_NAVN
          AND VFS.STOERRELSE_NAVN = TR.STOERRELSE_NAVN
          AND VFS.LAENGDE_NAVN = TR.LAENGDE_NAVN)
WHERE
    TR.DATO >= :PFROMDATE
    AND TR.DATO <= :PTODATE
    AND TR.ART IN (14)
    AND TR.PAKKELINJE IN (1, 5)  /* Kun afgange */
    AND (TR.EKSPORTERET = 0 OR TR.EKSPORTERET IS NULL)
ORDER BY
    TR.DATO ASC
```

**Parametre:**
- `:PFROMDATE` - Fra dato (Last run - X dage)
- `:PTODATE` - Til dato (NOW)

**Vigtige noter:**
- `ART = 14` - Flytningstransaktioner
- `PAKKELINJE IN (1, 5)` - **Kun afgange!** (ikke tilgange)
- `LEFT JOIN` på VAREFRVSTR (kan mangle hvis variant ikke eksisterer)
- Subquery for TILBUTIK lookup

---

## Data Mapping

### kmItemMove

| EasyPOS Felt | BC Felt | Type | Beregning | Note |
|---|---|---|---|---|
| (Transaction ID) | transId | Integer | Fra GETNAVISION_TRANSID | |
| BONNR | flytningsId | String | Direkte | Flytnings ID |
| VAREFRVSTRNR | VareId | String | Direkte | Hovedvare PLU |
| V509INDEX | variantId | String | From JOIN | Stregkode |
| TRANSID | epId | Integer | Direkte | Unik nøgle |
| DATO | bogfRingsDato | String | dd-mm-yyyy format | Posteringsdato |
| NAVISION_IDX (fra) | fraButik | String | From AF JOIN | Afsender butik BC ID |
| NAVISION_IDX (til) | tilButik | String | From subquery | Modtager butik BC ID |
| SALGSTK | antal | Integer | **TRUNC()** | Afrundet ned |
| KOSTPR | kostPris | Double | KOSTPR / ANTAL | **Per styk** |
| '0' | status | String | Hardcoded | Ubehandlet |
| NOW | transDato | String | dd-mm-yyyy | |
| NOW | transTid | String | hh:mm:ss | |

**Vigtig afrunding:**
```pascal
// Antal må være heltal for flytninger
lkmItemMove.antal := TRUNC(QFetchMovementsTransactions.FieldByName('Antal').AsFloat);
```

**Kostpris beregning:**
```pascal
if (Antal <> 0) then
  kostPris := KostPris / Antal
else
  kostPris := 0;
```

---

## SQL Query - Marker som Eksporteret

```sql
UPDATE Transaktioner 
SET Eksporteret = :PEksporteret 
WHERE 
    art IN (14) 
    AND TransID = :PTransID 
    AND (EKSPORTERET >= 0 OR EKSPORTERET IS NULL)
```

**Parametre:**
- `:PEksporteret` - Gamle værdi + 1
- `:PTransID` - EasyPOS Transaction ID

---

## Business Central API Calls

### 1. Check om flytning eksisterer

**Metode:** GET  
**Endpoint:** `/kmItemMove?$filter=epid eq {epId}`

**Response:**
- 200 OK med `value: []` = Findes IKKE
- 200 OK med `value: [{...}]` = Findes ALLEREDE (skip)

### 2. Opret flytningstransaktion

**Metode:** POST  
**Endpoint:** `/kmItemMove`  
**Content-Type:** application/json

**Request Body Eksempel:**
```json
{
  "transId": 1234567,
  "flytningsId": "FLY123",
  "VareId": "10001",
  "variantId": "1234567890123",
  "epId": 98765,
  "bogfRingsDato": "08-12-2025",
  "fraButik": "SHOP01",
  "tilButik": "SHOP02",
  "antal": 10,
  "kostPris": 150.50,
  "status": "0",
  "transDato": "09-12-2025",
  "transTid": "13:45:30"
}
```

---

## Konfiguration (INI Fil)

```ini
[SYNCRONIZE]
MovementsTransactions=1    ; Aktivér synkronisering

[MovementsTransaction]
Last run=42000.5           ; Sidste succesfulde kørsel (TDateTime)
Days to look for records=5 ; Lookback periode
Last time sync to BC was tried=42000.6  ; Sidste forsøg
```

**Periode beregning:**

```pascal
lFromDateAndTime := lDateAndTimeOfLastRun - lDaysToLookAfterRecords;
lToDateAndTime := NOW;
```

---

## Tracing Log (SLADREHANK)

### Ved Succes

```sql
ART = 3011  -- 3000 + 11
BONTEXT = 'Flyt synk. til Business Central OK (Service) DD-MM-YY HH:MM - DD-MM-YY HH:MM'
```

### Ved Fejl

```sql
ART = 3012  -- 3000 + 12
BONTEXT = 'Flytningstransaktioner IKKE sykroniseret med Business Central (Servive)'
```

---

## Fejlhåndtering

### Logfiler

**Normal log:**
- `[LogFolder]\Log[YYYYMMDD].txt`

**Fejl log:**
- `[LogFolder]\MovementstransactionErrors.txt`
- Omdøbes ved fejl til: `Error_Flytningstransaktioner_ddmmyyyy_hhmmss.txt`

**SQL debug:**
- `[LogFolder]\SQL\MovementsTransactions.SQL`

### Error Scenarios

#### 1. Fejl ved GET (check eksistens)

**Event ID:** 3303  
**Handling:**
- Log fejl
- Stop yderligere behandling
- Send email

#### 2. Fejl ved POST (oprettelse)

**Event ID:** 3302  
**Handling:**
- Log fejl med JSON payload
- Transaktion markeres IKKE som eksporteret
- Stop yderligere behandling
- Send email

#### 3. Fejl ved markering som eksporteret

**Event ID:** 3301  
**Handling:**
- Log database fejl
- Transaktion ER oprettet i BC men IKKE markeret
- Vil blive sprunget over ved næste kørsel (OK)

### Email Notifikation

**Sendes når:** RoutineCanceled = TRUE

**Indhold:**
- Emne: "EasyPOS-BC Sync Error - Flytningstransaktioner"
- Tekst: "Der skete en fejl ved synkronisering af flytningstransaktioner til Business Central"
- Vedhæftning: Fejl-logfil

---

## Specielle Situationer

### Kun afgange synkroniseres

**PAKKELINJE:**
- 1 = Afgang (synkroniseres)
- 5 = Afgang (synkroniseres)
- Andre værdier = Tilgang (IKKE synkroniseret)

**Rationale:** BC opretter automatisk tilgang når afgang modtages.

### Manglende variant

```sql
LEFT JOIN VAREFRVSTR VFS ...
```

Hvis variant ikke findes:
- VARIANTID = NULL
- Transaktion synkroniseres alligevel
- BC skal kunne håndtere NULL variant

### Manglende butik

Hvis TILBUTIK ikke findes i AFDELING:
- Subquery returnerer NULL
- Transaktion synkroniseres med NULL tilButik
- Vil sandsynligvis fejle i BC

**Løsning:** Ret butik-data før synk

---

## Performance

### Optimering

1. **Kronologisk sortering:**
   - `ORDER BY TR.DATO ASC`
   - Sikrer korrekt `Last run` opdatering

2. **Early abort:**
   - Stopper ved første fejl

3. **LEFT JOIN:**
   - Tillader manglende varianter

### Forventede Tider

- 500 flytningstransaktioner: ~3-7 minutter
- Afhænger af BC API responstid

---

## Debug Tips

### Test mode

```ini
[PROGRAM]
TestRoutine=1    ; Ingen faktisk eksport
```

### SQL Trace

```sql
-- Query gemmes automatisk
[LogFolder]\SQL\MovementsTransactions.SQL
```

### Manuel re-sync

```sql
-- Reset eksport-flag for flytninger
UPDATE TRANSAKTIONER 
SET EKSPORTERET = 0 
WHERE 
    ART = 14
    AND PAKKELINJE IN (1, 5)
    AND DATO >= '2025-12-01';
```

### Verificer i BC

```
GET /kmItemMove?$filter=flytningsId eq 'FLY123'
```

---

## Dependencies

### Database Tabeller
- TRANSAKTIONER
- AFDELING (både for fra og til butik)
- VAREFRVSTR (optional)
- SLADREHANK

### Business Central Tables
- kmItemMove

### Stored Procedures
- GETNAVISION_TRANSID

---

## Changelog

| Dato | Ændring |
|---|---|
| 2025-12-09 | Dokumentation oprettet |
