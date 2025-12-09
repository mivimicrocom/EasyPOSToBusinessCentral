# Synkronisering 1: Varer (Items)

**Metode:** `DoSyncronizeItems`  
**Retning:** EasyPOS → Business Central  
**API Endpoint:** `kmItem`  
**Aktiveres via INI:** `[SYNCRONIZE] Items=1`

---

## Formål

Synkroniserer varestamdata fra EasyPOS til Business Central. Dette omfatter:
- Hovedvarer (PLU numre)
- Varianter (stregkoder med farve, størrelse, længde)
- Priser (kost- og salgspriser fra valgt afdeling)
- Leverandør- og varegruppe-information
- Tekniske data (IntraStat, landekode, vægt)

---

## Arbejdsflow

```
1. Hent varer ændret siden sidste kørsel
2. For hver hovedvare:
   ├─ Opret hovedvare i BC (kmItem)
   ├─ Marker hovedvare som eksporteret
   └─ For hver variant til hovedvaren:
      ├─ Opret variant i BC (kmItem)
      ├─ [DEAKTIVERET] Opret variant-relation (kmVariantId)
      └─ Marker variant som eksporteret
3. Log resultat i SLADREHANK
4. Send email ved fejl
```

---

## SQL Query - Hent Varer

### Query Type: Dynamic (opbygges i kode)

**Kilde:** `UDM.pas` linje 2110-2260

```sql
SELECT DISTINCT
    -- Hoved varenummer
    VARER.plu_nr AS VAREID,
    
    -- Date of creation or last change
    VARER.bc_updatedate,
    
    -- Barcode (stregkode)
    VAREFRVSTR.V509INDEX AS VARIANTID,
    
    -- Variant dimensioner
    VAREFRVSTR.FARVE_NAVN AS FARVE,
    VAREFRVSTR.STOERRELSE_NAVN AS STORRELSE,
    VAREFRVSTR.LAENGDE_NAVN AS LAENGDE,
    
    -- Variant identifikation
    VAREFRVSTR.EANNUMMER,
    VAREFRVSTR.LEVVARENR,
    
    -- Varebeskrivelser
    VARER.VARENAVN1 AS BESKRIVELSE,
    VARER.ALT_VARE_NR,
    VARER.VARENAVN2,
    VARER.VARENAVN3,
    VARER.MODEL AS MODEL,
    
    -- Leverandør
    LEVERANDOERER.V509INDEX AS LEVERANDORKODE,
    VARER.LEVERID,
    
    -- Markering
    VARER.WEBVARER,
    
    -- Varegruppe
    VAREGRUPPER.V509INDEX AS VAREGRUPPE,
    VARER.VAREGRPID,
    
    -- Tekniske felter
    VARER.KATEGORI1 AS COUNTRY,
    VARER.KATEGORI2 AS WEIGTH,
    VARER.INTRASTAT,
    
    -- Kostpris fra valgt afdeling
    (SELECT
         VAREFRVSTR_DETAIL.VEJETKOSTPRISSTK
     FROM VAREFRVSTR_DETAIL
     WHERE
         VAREFRVSTR_DETAIL.v509index = VAREFRVSTR.v509index
         AND VAREFRVSTR_DETAIL.AFDELING_ID = :PAFDELING_ID) AS KOSTPRIS,
    
    -- Salgspris fra valgt afdeling
    (SELECT
         VAREFRVSTR_DETAIL.SALGSPRISSTK
     FROM VAREFRVSTR_DETAIL
     WHERE
         VAREFRVSTR_DETAIL.v509index = VAREFRVSTR.v509index
         AND VAREFRVSTR_DETAIL.AFDELING_ID = :PAFDELING_ID) AS SALGSPRIS

FROM VARER
    INNER JOIN VAREFRVSTR ON
          (VAREFRVSTR.VAREPLU_ID = VARER.plu_nr)
    INNER JOIN LEVERANDOERER ON
          (LEVERANDOERER.NAVN = VARER.leverid)
    INNER JOIN VAREGRUPPER ON
          (VAREGRUPPER.NAVN = VARER.varegrpid)
WHERE
    VARER.bc_updatedate >= :PStartDato 
    AND VARER.bc_updatedate <= :PSlutDato
ORDER BY
    VARER.plu_nr,
    VAREFRVSTR.v509index
```

**Parametre:**
- `:PAFDELING_ID` - Afdelingsnummer for pris-lookup (fra INI: `[Items] Department`)
- `:PStartDato` - Fra dato (Last run)
- `:PSlutDato` - Til dato (NOW)

---

## Data Mapping

### Hovedvare (kmItem for Head Item)

| EasyPOS Felt | BC Felt | Type | Maks Længde | Note |
|---|---|---|---|---|
| PLU_NR | VareId | String | | Unik nøgle |
| VARENAVN1 | beskrivelse | String | 50 | Truncated |
| MODEL | model | String | 50 | Truncated |
| KOSTPRIS | kostPris | Double | | Fra valgt afdeling |
| SALGSPRIS | salgspris | Double | | Fra valgt afdeling |
| LEVERANDORKODE | leverandRKode | String | | V509INDEX |
| VAREGRUPPE | varegruppe | String | | V509INDEX |
| NOW | transDato | String | | dd-mm-yyyy |
| NOW | transTid | String | | hh:mm:ss |
| INTRASTAT | tariffNo | String | | |
| KATEGORI1 | countryRegionOfOriginCode | String | | |
| VARENAVN2 | Varenavn2 | String | | |
| VARENAVN3 | Varenavn3 | String | | |
| LEVERID | LeverandRnavn | String | | Navn |
| VAREGRPID | Varegruppenavn | String | | Navn |
| '' | Farve | String | | Tom for hovedvare |
| '' | Storrelse | String | | Tom for hovedvare |
| '' | Laengde | String | | Tom for hovedvare |
| '' | EANNummer | String | | Tom for hovedvare |
| '' | Leverandoerensvarenummer | String | | Tom for hovedvare |
| ALT_VARE_NR | Alternativtvarenummer | String | | |
| KATEGORI2 | netWeight | Double | | Default 1 hvis invalid |
| WEBVARER | WEBVare | Boolean | | <> 0 |
| (Transaction ID) | transId | Integer | | Fra GETNAVISION_TRANSID |
| '0' | status | String | | Ubehandlet |

### Variant (kmItem for Variant)

Samme felter som hovedvare, MEN:

| EasyPOS Felt | BC Felt | Forskel |
|---|---|---|
| V509INDEX | VareId | **STREGKODE** i stedet for PLU_NR |
| FARVE_NAVN | Farve | **Udfyldt** |
| STOERRELSE_NAVN | Storrelse | **Udfyldt** |
| LAENGDE_NAVN | Laengde | **Udfyldt** |
| EANNUMMER | EANNummer | **Udfyldt** |
| LEVVARENR | Leverandoerensvarenummer | **Udfyldt** |

### Variant Relation (kmVariantId) - ❌ DEAKTIVERET

> **Note:** Per 11-09-2024 ønskes data IKKE længere i kmVariant table.  
> Kode er deaktiveret (linje 1991-1993)

Ville have indeholdt:
- transId
- VareId (hovedvare PLU)
- variantId (stregkode)
- Farve, stRrelse, lNgde
- status, transDato, transTid

---

## SQL Query - Marker som Eksporteret

### Hovedvare

```sql
UPDATE Varer 
SET Eksporteret = Eksporteret + 1 
WHERE Plu_Nr = :PV
```

**Parametre:**
- `:PV` - Hovedvare PLU nummer

### Variant

```sql
UPDATE VareFrvStr 
SET Eksporteret = Eksporteret + 1 
WHERE V509Index = :PV
```

**Parametre:**
- `:PV` - Variant stregkode

---

## Business Central API Calls

### 1. Check om vare eksisterer

**Metode:** GET  
**Endpoint:** `/kmItem?$filter=VareId eq '{VareId}'`

**Response:**
- 200 OK med `value: []` = Vare findes IKKE
- 200 OK med `value: [{...}]` = Vare findes ALLEREDE

### 2. Opret hovedvare

**Metode:** POST  
**Endpoint:** `/kmItem`  
**Content-Type:** application/json

**Request Body:**
```json
{
  "transId": 1234567,
  "VareId": "12345",
  "beskrivelse": "Vare beskrivelse",
  "model": "Model ABC",
  "kostPris": 100.50,
  "salgspris": 199.95,
  "leverandRKode": "LEV001",
  "varegruppe": "VG01",
  "status": "0",
  "transDato": "09-12-2025",
  "transTid": "13:45:30",
  "tariffNo": "12345678",
  "countryRegionOfOriginCode": "DK",
  "Varenavn2": "",
  "Varenavn3": "",
  "LeverandRnavn": "Leverandør A/S",
  "Varegruppenavn": "Varegruppe 1",
  "Farve": "",
  "Storrelse": "",
  "Laengde": "",
  "EANNummer": "",
  "Leverandoerensvarenummer": "",
  "Alternativtvarenummer": "ALT123",
  "netWeight": 1.5,
  "WEBVare": false
}
```

### 3. Opret variant

Samme som hovedvare, men med:
```json
{
  "VareId": "1234567890123",  // Stregkode i stedet
  "Farve": "Rød",
  "Storrelse": "M",
  "Laengde": "Normal",
  "EANNummer": "1234567890123",
  "Leverandoerensvarenummer": "LEV-VAR-001"
}
```

---

## Konfiguration (INI Fil)

```ini
[SYNCRONIZE]
Items=1                    ; Aktivér synkronisering

[Items]
Last run=42000.5           ; Sidste succesfulde kørsel (TDateTime)
Days to look for records=5 ; Hvor mange dage tilbage hvis Last run mangler
Department=001             ; Afdeling til pris-lookup
Last time sync to BC was tried=42000.6  ; Sidste forsøg (også fejlede)
```

---

## Tracing Log (SLADREHANK)

### Ved Succes

```sql
INSERT INTO SLADREHANK (
    DATO, ART, BONTEXT, LEVNAVN, 
    AFDELING_ID, UAFD_NAVN, UAFD_GRP_NAVN,
    EKSPEDIENT, VAREFRVSTRNR, VAREGRPID
) VALUES (
    NOW,
    3001,  -- 3000 + 1 (Items success)
    'Eksport af vare til Business Central OK (Service). ',
    'TransID: Vare: 1234567',
    '001',
    '',
    '',
    '99999',
    '',
    ''
)
```

### Ved Fejl

```sql
... ART = 3002 ...  -- 3000 + 2
... BONTEXT = 'Eksport af vare til Business Central IKKE OK (Service). ' ...
```

---

## Fejlhåndtering

### Logfiler

**Normal log:**
- `[LogFolder]\Log[YYYYMMDD].txt`

**Fejl log:**
- `[LogFolder]\ItemsErrors.txt`
- Omdøbes ved fejl til: `Error_Varer_ddmmyyyy_hhmmss.txt`

**SQL debug:**
- `[LogFolder]\SQL\Items.SQL`

### Error Scenarios

#### 1. Fejl ved indsættelse af hovedvare

**Event ID:** 3101  
**Handling:**
- Log fejl til ItemsErrors.txt
- Stop behandling af varianter
- Fortsæt til næste hovedvare
- Send email ved afslutning

#### 2. Fejl ved indsættelse af variant

**Event ID:** 3103  
**Handling:**
- Log fejl til ItemsErrors.txt
- Variant markeres IKKE som eksporteret
- Hovedvare ER allerede markeret
- Send email ved afslutning

#### 3. HTTP Status 503 (Service Unavailable)

**Handling:**
- Gem tidspunkt i `FLastDateTimeForStatusCode503`
- Stop yderligere eksport i denne kørsel
- Forsøg igen ved næste timer-trigger
- Email notifikation

### Email Notifikation

**Sendes når:** `lErrorCounter > 0` ved afslutning

**Indhold:**
- Emne: "EasyPOS-BC Sync Error - Varer"
- Tekst: "Der skete en fejl ved synkronisering af varer til Business Central"
- Vedhæftning: Omdøbt fejl-logfil

---

## Performance

### Optimering

1. **Query optimering:**
   - Bruger DISTINCT for at undgå duplikater
   - ORDER BY på hovedvare først, derefter variant
   - Subqueries til pris-lookup (kunne optimeres med JOIN)

2. **Batch processing:**
   - Behandler alle records i én query
   - Separate transactions for eksport-markering

3. **Incremental sync:**
   - Kun varer ændret siden sidste kørsel (`VARER.bc_updatedate`)

### Forventede Tider

- 100 hovedvarer med 500 varianter: ~2-5 minutter
- Afhænger af BC API responstid
- Network latency kan påvirke betydeligt

---

## Kendte Issues

### 1. Variant-relation deaktiveret
**Status:** By design (per 11-09-2024)  
**Årsag:** BC ønsker ikke data i kmVariantId table

### 2. Pris-lookup med subquery
**Impact:** Potentiel performance issue ved mange varianter  
**Løsning:** Kunne optimeres med JOIN i stedet

### 3. Manglende rollback ved partial fejl
**Issue:** Hvis variant fejler, er hovedvare allerede markeret som eksporteret  
**Konsekvens:** Variant må synkes manuelt eller ved reset af hovedvare

---

## Debug Tips

### Test mode

```ini
[PROGRAM]
TestRoutine=1    ; Ingen faktisk eksport, kun logging
```

### SQL Trace

Queries gemmes automatisk i:
```
[LogFolder]\SQL\Items.SQL
```

### Manuel re-sync

```sql
-- Reset eksport-flag for specifik hovedvare
UPDATE VARER 
SET EKSPORTERET = 0, 
    bc_updatedate = CURRENT_TIMESTAMP 
WHERE PLU_NR = '12345';

-- Reset for alle varianter til hovedvare
UPDATE VAREFRVSTR 
SET EKSPORTERET = 0 
WHERE VAREPLU_ID = '12345';
```

---

## Dependencies

### Database Tabeller
- VARER (hovedvarer)
- VAREFRVSTR (varianter)
- VAREFRVSTR_DETAIL (afdelings-specifikke priser)
- LEVERANDOERER (leverandører)
- VAREGRUPPER (varegrupper)
- SLADREHANK (tracing log)

### Business Central Tables
- kmItem (både hoved og varianter)
- ~~kmVariantId~~ (deaktiveret)

### Stored Procedures
- GETNAVISION_TRANSID (transaction ID generator)

---

## Changelog

| Dato | Ændring |
|---|---|
| 2024-09-11 | Deaktiveret kmVariantId sync |
| 2025-12-09 | Dokumentation oprettet |
