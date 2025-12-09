# Synkronisering 2: Salgstransaktioner (Sales Transactions)

**Metode:** `DoSyncronizeSalesTransactions`  
**Retning:** EasyPOS → Business Central  
**API Endpoint:** `kmItemSale`  
**Aktiveres via INI:** `[SYNCRONIZE] SalesTransactions=1`

---

## Formål

Synkroniserer alle salgs- og returtransaktioner fra EasyPOS til Business Central.

Dette omfatter:
- Almindeligt salg (ART 0)
- Returer (ART 1)
- Vare, antal, priser
- Butik og kasse information

---

## Arbejdsflow

```
1. Hent salgstransaktioner siden sidste kørsel
2. For hver transaktion:
   ├─ Check om allerede findes i BC (via epId)
   ├─ Hvis ikke: Opret i BC (kmItemSale)
   └─ Marker som eksporteret (EKSPORTERET + 1)
3. Log resultat i SLADREHANK
4. Send email ved fejl
```

---

## SQL Query - Hent Salgstransaktioner

**Kilde:** `UDM.dfm` linje 192-236

```sql
SELECT
    TR.TRANSID AS EPID,
    TR.UAFD_NAVN AS KASSE,
    TR.KOSTPR AS KOSTPRIS,
    TR.EKSPORTERET,
    TR.AFDELING_ID,
    AF.NAVISION_IDX AS BUTIKID,
    TR.SALGSTK AS ANTAL,
    VFS.V509INDEX AS VARIANTID,
    TR.BONNR AS BONNUMMER,
    TR.VAREFRVSTRNR AS VAREID,
    TR.SALGKR AS SALGSPRIS,
    TR.MOMSKR AS MOMSBELOB,
    TR.DATO AS BOGFORINGSDATO
FROM TRANSAKTIONER TR
    INNER JOIN AFDELING AF ON
          (AF.AFDELINGSNUMMER = TR.AFDELING_ID)
    INNER JOIN VAREFRVSTR VFS ON
          (VFS.VAREPLU_ID = TR.VAREFRVSTRNR
          AND VFS.FARVE_NAVN = TR.FARVE_NAVN
          AND VFS.STOERRELSE_NAVN = TR.STOERRELSE_NAVN
          AND VFS.LAENGDE_NAVN = TR.LAENGDE_NAVN)
WHERE
    TR.DATO >= :PFROMDATE
    AND TR.DATO <= :PTODATE
    AND TR.ART IN (0, 1)
    AND (TR.EKSPORTERET = 0 OR TR.EKSPORTERET IS NULL)
ORDER BY
    TR.DATO ASC
```

**Parametre:**
- `:PFROMDATE` - Fra dato (Last run - X dage)
- `:PTODATE` - Til dato (NOW)

**Vigtige noter:**
- `ART IN (0, 1)` - Kun salg og returer
- `ORDER BY TR.DATO ASC` - Kronologisk rækkefølge (vigtigt!)
- `EKSPORTERET = 0 OR IS NULL` - Kun ikke-eksporterede

---

## Data Mapping

### kmItemSale

| EasyPOS Felt | BC Felt | Type | Beregning | Note |
|---|---|---|---|---|
| (Transaction ID) | transId | Integer | Fra GETNAVISION_TRANSID | |
| TRANSID | epId | Integer | Direkte | Unik nøgle |
| BONNR | bonNummer | Integer | Direkte | Bonnummer |
| VAREFRVSTRNR | VareId | String | Direkte | Hovedvare PLU |
| V509INDEX | variantId | String | From JOIN | Stregkode |
| DATO | bogfRingsDato | String | dd-mm-yyyy format | Posteringsdato |
| DATO | salgstidspunkt | String | hh:mm:ss format | Salgstidspunkt |
| SALGSTK | antal | Double | Direkte | Antal solgt |
| MOMSKR | momsbelB | Double | MOMSKR / ANTAL | **Per styk** |
| SALGKR | salgspris | Double | SALGKR / ANTAL | **Per styk** |
| KOSTPR | kostPris | Double | KOSTPR / ANTAL | **Per styk** |
| '0' | gaveKortId | String | Hardcoded | Ikke brugt |
| UAFD_NAVN | kasse | String | Direkte | Kassenavn |
| NAVISION_IDX | butikId | String | From AF JOIN | Butik ID |
| 'Ubehandlet' | lagerStatus | String | Hardcoded | |
| 'Ubehandlet' | finansStatus | String | Hardcoded | |
| NOW | transDato | String | dd-mm-yyyy | |
| NOW | transTid | String | hh:mm:ss | |

**Vigtig beregning:**
```pascal
if (Antal <> 0) then
begin
  momsbelB := MomsBelob / Antal;
  salgspris := Salgspris / Antal;
  kostPris := KostPris / Antal;
end
else
begin
  // Alle = 0 hvis antal er 0
end
```

---

## SQL Query - Marker som Eksporteret

```sql
UPDATE Transaktioner 
SET Eksporteret = :PEksporteret 
WHERE 
    art IN (0, 1) 
    AND TransID = :PTransID 
    AND (EKSPORTERET >= 0 OR EKSPORTERET IS NULL)
```

**Parametre:**
- `:PEksporteret` - Gamle værdi + 1
- `:PTransID` - EasyPOS Transaction ID

**Note:** Tæller op, så gentagne synk kan spores.

---

## Business Central API Calls

### 1. Check om transaktion eksisterer

**Metode:** GET  
**Endpoint:** `/kmItemSale?$filter=epId eq {epId}`

**Response:**
- 200 OK med `value: []` = Findes IKKE
- 200 OK med `value: [{...}]` = Findes ALLEREDE (skip)

### 2. Opret salgstransaktion

**Metode:** POST  
**Endpoint:** `/kmItemSale`  
**Content-Type:** application/json

**Request Body Eksempel:**
```json
{
  "transId": 1234567,
  "epId": 98765,
  "bonNummer": 12345,
  "VareId": "10001",
  "variantId": "1234567890123",
  "bogfRingsDato": "08-12-2025",
  "salgstidspunkt": "14:23:45",
  "antal": 2.0,
  "momsbelB": 49.95,
  "salgspris": 249.75,
  "kostPris": 150.00,
  "gaveKortId": "0",
  "kasse": "Kasse 1",
  "butikId": "SHOP01",
  "lagerStatus": "Ubehandlet",
  "finansStatus": "Ubehandlet",
  "transDato": "09-12-2025",
  "transTid": "13:45:30"
}
```

**Status Codes:**
- 200/201 OK - Succes
- 503 Service Unavailable - BC overbelastet (trigger delay)
- 4xx/5xx - Fejl (log og email)

---

## Konfiguration (INI Fil)

```ini
[SYNCRONIZE]
SalesTransactions=1        ; Aktivér synkronisering

[SalesTransaction]
Last run=42000.5           ; Sidste succesfulde kørsel (TDateTime)
Days to look for records=5 ; Lookback periode
Last time sync to BC was tried=42000.6  ; Sidste forsøg
```

**Vigtig note om periode:**

```pascal
// Beregning i koden:
lDateAndTimeOfLastRun := iniFile.ReadDateTime('SalesTransaction', 'Last run', NOW - lDaysToLookAfterRecords);
lFromDateAndTime := lDateAndTimeOfLastRun - lDaysToLookAfterRecords;
lToDateAndTime := NOW;
```

**Resultat:** Faktisk periode = Last run - X dage til NOW  
**Formål:** Sikre at ingen records overses ved midlertidige fejl

---

## Tracing Log (SLADREHANK)

### Ved Succes

```sql
ART = 3005  -- 3000 + 5
BONTEXT = 'Salg synk. med Business Central OK (Service) (DD-MM-YY HH:MM - DD-MM-YY HH:MM)'
LEVNAVN = 'TransID: Vare: [TransactionID]'
```

### Ved Fejl

```sql
ART = 3006  -- 3000 + 6
BONTEXT = 'Salgstransaktioner IKKE sykroniseret med Business Central (Servive)'
```

---

## Fejlhåndtering

### Logfiler

**Normal log:**
- `[LogFolder]\Log[YYYYMMDD].txt`

**Fejl log:**
- `[LogFolder]\SalestransactionErrors.txt`
- Omdøbes ved fejl til: `Error_Salgstransaktioner_ddmmyyyy_hhmmss.txt`

**SQL debug:**
- `[LogFolder]\SQL\SalesTransactions.SQL`

### Error Scenarios

#### 1. Fejl ved GET (check eksistens)

**Event ID:** 3203  
**Handling:**
- Log fejl
- Stop yderligere behandling
- Send email
- Retry ved næste kørsel

#### 2. Fejl ved POST (oprettelse)

**Event ID:** 3202  
**Handling:**
- Log fejl med JSON payload
- Transaktion markeres IKKE som eksporteret
- Stop yderligere behandling
- Send email
- Retry ved næste kørsel

#### 3. Fejl ved markering som eksporteret

**Event ID:** 3201  
**Handling:**
- Log database fejl
- Transaktion ER oprettet i BC men IKKE markeret
- Vil blive sprunget over ved næste kørsel (findes allerede)
- OK - ingen data-tab

### Email Notifikation

**Sendes når:** RoutineCanceled = TRUE

**Indhold:**
- Emne: "EasyPOS-BC Sync Error - Salgstransaktioner"
- Tekst: "Der skete en fejl ved synkronisering af salgstransaktioner til Business Central"
- Vedhæftning: Fejl-logfil

---

## Specielle Situationer

### Returer (ART = 1)

Håndteres identisk med almindeligt salg:
- Negativt antal
- Negative beløb
- Samme data struktur

### Nul-antal transaktioner

```pascal
if (Antal <> 0) then
  // Normal beregning per styk
else
  // Alle priser = 0
```

**Formål:** Undgå division by zero

### Variant-lookup fejl

Hvis `VAREFRVSTR` ikke findes:
- Query returnerer INGEN records
- Transaktion synkroniseres ikke
- Retry ved næste kørsel

**Løsning:** Ret variant-data i EasyPOS

---

## Performance

### Optimering

1. **Kronologisk sortering:**
   - `ORDER BY TR.DATO ASC`
   - Sikrer at `Last run` altid kan sættes til seneste record

2. **Early abort:**
   - Stopper ved første fejl
   - Undgår spild af API calls

3. **Incremental update:**
   - Kun ikke-eksporterede records
   - Lookback window for sikkerhed

### Forventede Tider

- 1000 transaktioner: ~5-10 minutter
- Afhænger af BC API responstid
- Network latency kan påvirke

---

## Monitoring

### Success Indicators

```
Log: "Iteration done succesfull"
INI: [SalesTransaction] Last run opdateret
SLADREHANK: ART = 3005
Email: Ingen
```

### Failure Indicators

```
Log: "Iteration done with errors"
INI: Last run IKKE opdateret
SLADREHANK: ART = 3006
Email: Sendt med fejl-logfil
```

### Retry Behavior

Ved fejl:
1. Gemmer `Last time sync to BC was tried`
2. Beholder gammel `Last run` værdi
3. Næste kørsel starter fra samme punkt
4. Gentager indtil success

---

## Debug Tips

### Test mode

```ini
[PROGRAM]
TestRoutine=1    ; Ingen faktisk eksport, kun logging
```

### SQL Trace

```sql
-- Query gemmes automatisk
[LogFolder]\SQL\SalesTransactions.SQL
```

### Manuel re-sync

```sql
-- Reset eksport-flag for specifik periode
UPDATE TRANSAKTIONER 
SET EKSPORTERET = 0 
WHERE 
    ART IN (0, 1)
    AND DATO >= '2025-12-01'
    AND DATO <= '2025-12-31';
```

### Check duplicates i BC

```
GET /kmItemSale?$filter=epId eq 98765
```

Skulle returnere max 1 record.

---

## Dependencies

### Database Tabeller
- TRANSAKTIONER (transaktioner)
- AFDELING (butikker)
- VAREFRVSTR (varianter til lookup)
- SLADREHANK (tracing log)

### Business Central Tables
- kmItemSale

### Stored Procedures
- GETNAVISION_TRANSID (transaction ID generator)

---

## Changelog

| Dato | Ændring |
|---|---|
| 2025-12-09 | Dokumentation oprettet |
