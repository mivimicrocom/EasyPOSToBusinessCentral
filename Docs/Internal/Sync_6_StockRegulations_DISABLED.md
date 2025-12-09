# Synkronisering 6: Lagerreguleringer (Stock Regulations)

**Status:** ❌ **DEAKTIVERET**  
**Metode:** `DoSyncronizeStockRegulationTransaction` (Udkommenteret)  
**Retning:** EasyPOS → Business Central  
**API Endpoint:** `kmItemAccess`  
**Aktiveres via INI:** `[SYNCRONIZE] StockRegulationsTransactions=0`

---

## ⚠️ VIGTIG NOTE

**Denne synkronisering er IKKE aktiv!**

Koden er fuldstændig udkommenteret i `UDM.pas` linje ~2970-3255.

Hvis aktiveret i INI fil vil systemet logge:
```
"Syncronize Stock regulations Transaction: DOES NOT EXISTS"
```

---

## Historisk Formål

Ville have synkroniseret lagertilgange fra EasyPOS til Business Central.

Dette ville have omfattet:
- Lagertilgange (ART 11)
- Samlet beløb per lagertilgang
- Leverandør information
- Butik information

---

## SQL Query - Hent Lagertilgange (Udkommenteret)

**Kilde:** `UDM.dfm` linje 374-426 (stadig i DFM!)

```sql
SELECT
    TR.DATO AS Bogforingsdato,
    Afd.NAVISION_IDX AS ButikID,
    tr.BONNR AS LagerTilgangsNummer,
    tr.LEVNAVN,
    
    -- Lookup leverandør kode
    (SELECT
         l.V509INDEX
     FROM leverandoerer l
     WHERE
         l.navn = tr.levnavn) AS LeverandorKode,
    
    -- Lookup leverandør navn
    (SELECT
         l.Navn
     FROM leverandoerer l
     WHERE
         l.navn = tr.levnavn) AS LeverandorNavn,
    
    tr.Eksporteret,
    
    -- Samlet kostpris for tilgangen
    SUM(tr.KostPr) AS Belob

FROM Transaktioner tr
    INNER JOIN Afdeling Afd ON 
          (Afd.AFDELINGSNUMMER = tr.AFDELING_ID)
WHERE
    tr.dato >= :PFromDate 
    AND tr.art = 11
    AND tr.dato <= :PToDate
    AND (tr.EKSPORTERET = 0 OR tr.EKSPORTERET IS NULL)
GROUP BY
    LeverandorKode,
    LeverandorNavn,
    LeverandorNavn,
    LagerTilgangsNummer,
    ButikID,
    Bogforingsdato,
    Eksporteret
ORDER BY
    Bogforingsdato,
    LagerTilgangsNummer
```

**Parametre:**
- `:PFromDate` - Fra dato
- `:PToDate` - Til dato

**Vigtige noter:**
- `ART = 11` - Lagertilgange
- `GROUP BY` - Samler alle linjer per tilgang
- `SUM(KostPr)` - Total beløb

---

## Data Mapping (Ville Have Været)

### kmItemAccess

| EasyPOS Felt | BC Felt | Type | Note |
|---|---|---|---|
| (Transaction ID) | transId | Integer | Fra GETNAVISION_TRANSID |
| NAVISION_IDX | butikId | String | Butik ID |
| V509INDEX | leverandRKode | String | Leverandør kode |
| BONNR | lagertilgangsnummer | String | Tilgangsnummer |
| DATO | bogfRingsDato | String | dd-mm-yyyy format |
| SUM(KOSTPR) | belB | Double | Total beløb |
| '0' | status | String | Ubehandlet |
| FALSE | tilbagefRt | Boolean | Ikke retur |
| NOW | transDato | String | dd-mm-yyyy |
| NOW | transTid | String | hh:mm:ss |

---

## Business Central API Calls (Ville Have Været)

### 1. Check om tilgang eksisterer

**Metode:** GET  
**Endpoint:** `/kmItemAccess?$filter=lagertilgangsnummer eq '{nr}' and leverandRKode eq '{lev}' and butikId eq '{butik}' and bogfRingsDato eq '{dato}'`

**Note:** Kompleks nøgle med 4 felter!

### 2. Opret lagertilgang

**Metode:** POST  
**Endpoint:** `/kmItemAccess`

**Request Body Eksempel:**
```json
{
  "transId": 1234567,
  "butikId": "SHOP01",
  "leverandRKode": "LEV001",
  "lagertilgangsnummer": "LT12345",
  "bogfRingsDato": "08-12-2025",
  "belB": 15000.50,
  "status": "0",
  "tilbagefRt": false,
  "transDato": "09-12-2025",
  "transTid": "13:45:30"
}
```

---

## SQL Query - Marker som Eksporteret (Ville Have Været)

```sql
UPDATE Transaktioner t 
SET t.Eksporteret = :PEksporteret
WHERE
    t.art = 11 
    AND t.bonnr = :PBOnNr 
    AND t.dato = :PDato 
    AND t.levnavn = :PLevNavn 
    AND t.afdeling_id = :PAfdeling_ID 
    AND (t.EKSPORTERET >= 0 OR t.EKSPORTERET IS NULL)
```

**Parametre:**
- `:PEksporteret` - Ny værdi (gamle + 1)
- `:PBOnNr` - Lagertilgangsnummer
- `:PDato` - Dato
- `:PLevNavn` - Leverandørnavn
- `:PAfdeling_ID` - Afdelings ID

**Note:** Opdaterer ALLE linjer i tilgangen (GROUP BY effekt).

---

## Konfiguration (Ville Have Været)

```ini
[SYNCRONIZE]
StockRegulationsTransactions=0  ; SKAL være 0 (deaktiveret)

[StockRegulation]
Last run=42000.5
Days to look for records=5
Last time sync to BC was tried=42000.6
```

---

## Tracing Log (Ville Have Været)

### Ved Succes

```sql
ART = 3007  -- 3000 + 7
BONTEXT = 'Tilg synk. med til Business Central OK (Service) ...'
```

### Ved Fejl

```sql
ART = 3008  -- 3000 + 8
BONTEXT = 'Tilgangstransaktioner IKKE sykroniseret med Business Central (Servive)'
```

---

## Fejlhåndtering (Ville Have Været)

### Logfiler

**Fejl log:**
- `[LogFolder]\StockRegulationstransactionErrors.txt`
- Ville omdøbes til: `Error_Tilgangstransaktioner_ddmmyyyy_hhmmss.txt`

**SQL debug:**
- `[LogFolder]\SQL\StockRegulationsTransactions.SQL`

### Email Notifikation

Ville sende email ved fejl med emne:
"EasyPOS-BC Sync Error - tilgangstransaktioner"

---

## Hvorfor Deaktiveret?

**Mulige årsager:**

1. **Business logik i BC:**
   - BC håndterer måske lagertilgange anderledes
   - Alternativ proces via kørsler/batch jobs

2. **Kompleks nøgle:**
   - 4-felts nøgle er fejltilbøjelig
   - Kan give duplikater eller manglende matches

3. **Gruppering:**
   - `GROUP BY` samler linjer
   - Mister detail-information
   - BC vil måske have linje-niveau data

4. **Timing:**
   - Lagertilgange skal måske synkes anderledes
   - Måske via anden integration

---

## Genaktivering (IKKE Anbefalet)

**Hvis man ALLIGEVEL vil aktivere:**

### 1. Fjern udkommentering

I `UDM.pas` linje ~2970-3255:
- Fjern `//` fra alle linjer
- Test GRUNDIGT!

### 2. Aktivér i INI

```ini
[SYNCRONIZE]
StockRegulationsTransactions=1
```

### 3. Test scenarie

```sql
-- Opret test lagertilgang
INSERT INTO TRANSAKTIONER (
    ART, BONNR, DATO, LEVNAVN, AFDELING_ID, KOSTPR, ...
) VALUES (
    11, 'TEST001', CURRENT_DATE, 'TestLev', '001', 1000, ...
);
```

### 4. Overvåg logs

```
[LogFolder]\Log[YYYYMMDD].txt
[LogFolder]\SQL\StockRegulationsTransactions.SQL
```

---

## Alternative Løsninger

**I stedet for denne synkronisering:**

1. **Manuel batch i BC:**
   - Import lagertilgange via CSV
   - Kør batch job i BC

2. **Real-time ved tilgang:**
   - Hook direkte i EasyPOS ved lagertilgang
   - POST direkte til BC

3. **Konsolidering:**
   - Lav en samlet "lager-movements" synk
   - Kombinér ART 11, 14, etc.

---

## Dependencies (Hvis Aktiv)

### Database Tabeller
- TRANSAKTIONER (ART = 11)
- AFDELING (butik lookup)
- LEVERANDOERER (leverandør lookup)
- SLADREHANK (tracing)

### Business Central Tables
- kmItemAccess

### Stored Procedures
- GETNAVISION_TRANSID

---

## Konklusion

**Status:** Deaktiveret og skal forblive deaktiveret.

**Anbefaling:**
- Undlad at aktivere uden grundig analyse
- Konsulter BC team først
- Find årsag til deaktivering før re-implementation

---

## Changelog

| Dato | Ændring |
|---|---|
| (Ukendt) | Kode udkommenteret og deaktiveret |
| 2025-12-09 | Dokumentation oprettet |
