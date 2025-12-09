# Synkronisering 5: Kostpriser fra Business Central

**Metode:** `DoSyncCostPriceFromBusinessCentral`  
**Retning:** Business Central → EasyPOS ⚠️ (MODSAT RETNING!)  
**API Endpoint:** `kmCostprice` (READ-ONLY)  
**Aktiveres via INI:** `[SYNCRONIZE] Costprice from BC=1`

---

## Formål

**Denne synkronisering går MODSAT vej!**

Henter opdaterede kostpriser fra Business Central og opdaterer EasyPOS.

Dette omfatter:
- Hovedvarer markeret med `UPDATE_FROM_BC > 0`
- Alle varianter til hovedvaren
- Kostpris i DKK fra BC → Konverteres til lokal valuta
- Opdatering i ALLE afdelinger
- Håndtering af lagerbeholdning under opdatering

---

## Arbejdsflow

```
1. Hent hovedvarer markeret til kostprisopdatering (UPDATE_FROM_BC > 0)
2. For hver hovedvare (max X per kørsel):
   ├─ Hent ALLE varianter til hovedvaren (batch: 200 ad gangen)
   ├─ For hver variant:
   │  ├─ Hent kostpris fra BC (i DKK)
   │  ├─ For hver afdeling:
   │  │  ├─ Konverter DKK → lokal valuta
   │  │  ├─ Hvis ændret kostpris:
   │  │  │  ├─ Fjern lager (P_STOCKREGULATE)
   │  │  │  ├─ Opdater kostpris (VAREFRVSTR_DETAIL)
   │  │  │  ├─ Gendan lager med ny kostpris
   │  │  │  └─ Log i SLADREHANK
   │  │  └─ Ellers: Skip
   ├─ Marker hovedvare som færdig (UPDATE_FROM_BC = 0)
   └─ Log i WEB_SLADREHANK
3. Log resultat i SLADREHANK
4. Send email ved fejl
```

---

## SQL Query - Hent Hovedvarer til Opdatering

**Kilde:** `UDM.dfm` linje 750-767

```sql
SELECT
    V.PLU_NR,
    
    -- Antal varianter til denne hovedvare
    (SELECT
         COUNT(*)
     FROM VAREFRVSTR VV
     WHERE
         VV.VAREPLU_ID = V.PLU_NR) AS ANTALVV

FROM VARER V
WHERE
    V.UPDATE_FROM_BC > 0
ORDER BY
    V.ANTAL_DETALJER DESC
```

**Note:** 
- `UPDATE_FROM_BC > 0` - Flag sat manuelt eller automatisk
- `ORDER BY ANTAL_DETALJER DESC` - Behandl varer med mange detaljer først

---

## SQL Query - Hent Varianter til Hovedvare (Batch)

**Kilde:** `UDM.pas` linje 755-762 (dynamisk)

```sql
SELECT FIRST :BatchSize SKIP :SkipCount
    VV.V509INDEX 
FROM VAREFRVSTR VV 
WHERE 
    VV.VAREPLU_ID = :PVAREPLU_ID 
ORDER BY 
    VV.V509INDEX
```

**Parametre:**
- `:BatchSize` - 200 (fast)
- `:SkipCount` - 0, 200, 400, ... (incrementer per batch)
- `:PVAREPLU_ID` - Hovedvare PLU nummer

**Batch Iteration:**
```pascal
lTotalRecords := AntalVV;  // Fra første query
lSkipCount := 0;
while (lSkipCount < lTotalRecords) do
begin
  // Hent batch
  // Process batch
  lSkipCount := lSkipCount + 200;
end;
```

---

## Business Central API Call - Hent Kostpriser

**OData Filter Opbygning:**

Fra varianter i batch bygges filter-string:
```
VareId eq '1234567890123' or VareId eq '1234567890124' or ...
```

**Metode:** GET  
**Endpoint:** `/kmCostprice?$filter={filterString}`

**Response:**
```json
{
  "value": [
    {
      "VareId": "1234567890123",
      "UnitCost": 150.50
    },
    {
      "VareId": "1234567890124",
      "UnitCost": 225.00
    }
  ]
}
```

**Vigtige noter:**
- `UnitCost` er altid i **DKK**
- Hvis `UnitCost = 0` → Spring over (ingen opdatering)

---

## SQL Query - Hent Afdelinger og Valuta

**Kilde:** `UDM.dfm` linje 790-807

```sql
SELECT
    AFDELING.AFDELINGSNUMMER,
    STAMDATA_PRG_EXT.STDVALUTA,
    VALUTA.TEKST,
    VALUTALINIER.KURS
FROM AFDELING
    INNER JOIN STAMDATA_PRG_EXT ON
          STAMDATA_PRG_EXT.AFDELING_ID = AFDELING.AFDELINGSNUMMER
    INNER JOIN VALUTA ON
          VALUTA.TEKST = STAMDATA_PRG_EXT.STDVALUTA
    INNER JOIN VALUTALINIER ON
          VALUTALINIER.VALUTA_TEKST = VALUTA.TEKST
ORDER BY
    AFDELING.AFDELINGSNUMMER ASC
```

**Returnerer:**
- Alle afdelinger
- Standard valuta per afdeling
- Aktuel kurs (DKK = 100)

---

## SQL Query - Hent Variant Detaljer i Afdeling

**Kilde:** `UDM.dfm` linje 810-839

```sql
SELECT
    VAREFRVSTR_DETAIL.ANTALSTK,
    VAREFRVSTR_DETAIL.FARVE_NAVN,
    VAREFRVSTR_DETAIL.LAENGDE_NAVN,
    VAREFRVSTR_DETAIL.STOERRELSE_NAVN,
    VAREFRVSTR_DETAIL.BEH_KOSTPRIS,
    VAREFRVSTR_DETAIL.SALGSPRISSTK,
    VAREFRVSTR_DETAIL.VEJETKOSTPRISSTK
FROM VAREFRVSTR_DETAIL
WHERE
    VAREFRVSTR_DETAIL.V509INDEX = :PV509INDEX
    AND VAREFRVSTR_DETAIL.AFDELING_ID = :PAFDELING_ID
```

**Parametre:**
- `:PV509INDEX` - Variant stregkode
- `:PAFDELING_ID` - Afdelingsnummer

---

## Valuta Konvertering

**Formel:**
```pascal
LocalCostprice := (BCCostpriceInDKK / KURS) * 100
```

**Eksempel:**
```
BC Kostpris (DKK): 150.00
Afdeling valuta: SEK
Kurs: 68 (DKK/SEK rate)

Local kostpris = (150.00 / 68) * 100 = 220.59 SEK
```

**Afrunding:**
```pascal
if FormatFloat('#,#0', LocalCostprice) = FormatFloat('#,#0', CurrentCostprice) then
  // Skip - ingen ændring med heltal-præcision
```

---

## Kostpris Opdatering Proces

### 1. Fjern Lager (P_STOCKREGULATE)

**Stored Procedure:** `P_STOCKREGULATE`

```sql
SELECT * FROM P_STOCKREGULATE(
    :Barcode,        -- Variant stregkode
    :Department,     -- Afdelingsnummer
    '',              -- Ingen leverandør
    60999,           -- System bruger
    :Timestamp,      -- NOW
    :TransID,        -- 10000000 + TRUNC(NOW)
    :Quantity * -1,  -- NEGATIV (fjern lager)
    :OldCostprice,   -- Gammel kostpris
    :Saleprice,      -- Salgspris (uændret)
    'Removing stock to regulate costprice',
    'regulate'
)
```

**Formål:** Fjern beholdning for at kunne ændre kostpris.

### 2. Opdater Kostpris

```sql
UPDATE VAREFRVSTR_DETAIL 
SET
    VAREFRVSTR_DETAIL.VEJETKOSTPRISSTK = :PVEJETKOSTPRISSTK,
    SIDSTEKOBSSTK = 1,
    SIDSTEKOSTPRSTK = :PVEJETKOSTPRISSTK
WHERE
    VAREFRVSTR_DETAIL.V509INDEX = :PV509INDEX
    AND VAREFRVSTR_DETAIL.AFDELING_ID = :PAFDELING_ID
```

**Felter:**
- `VEJETKOSTPRISSTK` - Ny vejet kostpris
- `SIDSTEKOBSSTK` - Seneste købsmængde (1)
- `SIDSTEKOSTPRSTK` - Seneste købskostpris

### 3. Gendan Lager (P_STOCKREGULATE)

```sql
SELECT * FROM P_STOCKREGULATE(
    :Barcode,
    :Department,
    '',
    60999,
    :Timestamp,
    :TransID,        -- 11000000 + TRUNC(NOW)
    :Quantity,       -- POSITIV (gendan lager)
    :NewCostprice,   -- NY kostpris fra BC
    :Saleprice,
    'Adding stock to regulate costprice',
    'regulate'
)
```

**Formål:** Gendan beholdning med ny kostpris.

### 4. Log i SLADREHANK

```sql
INSERT INTO SLADREHANK (
    DATO, ART, LEVNAVN, KOSTPR,
    FARVE_NAVN, STOERRELSE_NAVN, LAENGDE_NAVN,
    EKSPEDIENT, VAREFRVSTRNR, VAREGRPID,
    BONTEXT, AFDELING_ID, UAFD_NAVN
) VALUES (
    :PDATO,
    209,  -- Kostpris ændret
    '',
    :PKOSTPR,  -- NY kostpris
    :PFARVE_NAVN,
    :PSTOERRELSE_NAVN,
    :PLAENGDE_NAVN,
    60999,  -- System bruger
    :PVAREFRVSTRNR,  -- Hovedvare
    'OLD_PRICE > NEW_PRICE',  -- Før > Efter
    'Kostpris ændret på variant via Business Central',
    :PAFDELING_ID,
    '',
    'Alle undergrupper'
)
```

---

## SQL Query - Marker Hovedvare som Færdig

```sql
UPDATE VARER 
SET UPDATE_FROM_BC = 0 
WHERE PLU_NR = :PPLU_NR
```

**Parametre:**
- `:PPLU_NR` - Hovedvare PLU nummer

**Timing:** Efter ALLE varianter er behandlet succesfuldt.

---

## Log i WEB_SLADREHANK

**Kilde:** `UDM.dfm` linje 848-889

```sql
INSERT INTO WEB_SLADREHANK (
    HVAD, HVEM, HVOR, DATO_STEMPEL, SQLSETNING
) VALUES (
    'EasyPOS to BC Windows Service',
    'EasyPOS to BC Windows Service',
    'EasyPOS to BC Windows Service',
    :DATO_STEMPEL,
    :SQLSETNING  -- Detaljeret log af hele processen
)
```

**SQLSETNING indeholder:**
```
Checking head item 12345 with 50 variants in Business Central. Item in this cycle: 1
  Iteration 1. Handling 200 variants. Skipping 0
  FilterValue VareId eq '1234567890123' or VareId eq '1234567890124'...
  Response: {...}
  Returned records from BC 2
Variant 1234567890123 number 1
  Set costprice to 150.50 on variant 1234567890123 in department 001
  Costprice from Business Central is 150.50 on variant 1234567890123...
```

---

## Konfiguration (INI Fil)

```ini
[SYNCRONIZE]
Costprice from BC=1        ; Aktivér synkronisering

[Costprice]
Items to handle per cycle=50  ; Max hovedvarer per kørsel
```

**Vigtig note om begrænsning:**

```pascal
NumberOfItemsToHandle := iniFile.ReadInteger('Costprice', 'Items to handle per cycle', 50);
```

**Formål:** Undgå timeout ved store opdateringer.

---

## Tracing Log (SLADREHANK)

**Note:** Ingen automatisk SLADREHANK for hele rutinen.  
Kun per variant (ART 209).

---

## Fejlhåndtering

### Logfiler

**Normal log:**
- `[LogFolder]\Log_Costprice[YYYYMMDD].txt` (separate log!)

**Fejl log:**
- `[LogFolder]\UpdateCostpriceErrors.txt`

**SQL debug:**
- `[LogFolder]\SQL\ItemsUpdateCostprice.SQL`
- `[LogFolder]\SQL\FetchBarcodeToHeadItem.SQL`
- `[LogFolder]\SQL\FetchVariantInDepartment.SQL`
- `[LogFolder]\SQL\UpdateCostPriceOnVariant.SQL`
- `[LogFolder]\SQL\InsertTracingLog.SQL`

### Error Scenarios

#### 1. Fejl ved GET fra BC

**Event ID:** 3503  
**Handling:**
- Log fejl
- Stop behandling af denne hovedvare
- Hovedvare markeres IKKE som færdig
- Fortsæt til næste hovedvare

#### 2. Fejl ved lager-regulering

**Handling:**
- Rollback transaction
- Hovedvare markeres IKKE som færdig
- Retry ved næste kørsel

#### 3. Fejl ved kostpris-opdatering

**Handling:**
- Rollback transaction
- Lager-status kan være inkonsistent!
- Manuel korrektion kan være nødvendig

### Email Notifikation

**Sendes IKKE automatisk** for kostpris-fejl!  
Kun logging.

---

## Specielle Situationer

### UnitCost = 0 fra BC

```pascal
if (UnitCost = 0) then
  // Skip - ingen opdatering
```

**Rationale:** 0-kostpris er sandsynligvis ikke gyldig.

### Ingen kostpris-ændring

```pascal
if FormatFloat('#,#0', LocalNewCostprice) = FormatFloat('#,#0', LocalOldCostprice) then
  // Skip
```

**Optimering:** Undgå unødvendige lager-reguleringer.

### Nul beholdning (ANTALSTK = 0)

```pascal
if (AntalStk <> 0) then
begin
  DoRemoveStock();
  DoSetCostPrice();
  DoSetStock();
end
else
begin
  DoSetCostPrice();  // Kun opdater pris
end
```

**Optimering:** Spring lager-reguleringer over.

### Manglende variant i afdeling

Hvis `VAREFRVSTR_DETAIL` ikke findes:
- Query returnerer ingen records
- Spring over denne afdeling
- Fortsæt til næste

---

## Performance

### Optimering

1. **Batch processing:**
   - 200 varianter ad gangen fra BC
   - Reducerer antal API calls

2. **Cycle limit:**
   - Max X hovedvarer per kørsel
   - Forhindrer timeout

3. **Early skip:**
   - UnitCost = 0 → Skip
   - Ingen ændring → Skip

### Forventede Tider

**Hovedvare med 500 varianter i 3 afdelinger:**
- 3 batches á 200 = 3 BC API calls
- 500 * 3 = 1500 variant-opdateringer
- ~5-10 minutter

**50 hovedvarer med gennemsnit 100 varianter:**
- ~30-60 minutter

---

## Debug Tips

### Manuelt markér vare til opdatering

```sql
UPDATE VARER 
SET UPDATE_FROM_BC = 1 
WHERE PLU_NR = '12345';
```

### Check kostpriser i BC

```
GET /kmCostprice?$filter=VareId eq '1234567890123'
```

### SQL Trace

Mange SQL filer genereres - se `[LogFolder]\SQL\`

### Kontrollér valutakurs

```sql
SELECT * FROM VALUTALINIER WHERE VALUTA_TEKST = 'SEK';
```

Kurs skal være aktuel!

---

## Dependencies

### Database Tabeller
- VARER (UPDATE_FROM_BC flag)
- VAREFRVSTR (varianter)
- VAREFRVSTR_DETAIL (afdelings-priser og lager)
- AFDELING (afdelinger)
- STAMDATA_PRG_EXT (afdeling valuta)
- VALUTA (valuta master)
- VALUTALINIER (valutakurser)
- SLADREHANK (variant tracing)
- WEB_SLADREHANK (proces log)

### Business Central Tables
- kmCostprice (READ-ONLY)

### Stored Procedures
- P_STOCKREGULATE (lager regulering)

---

## Risici og Advarsler

⚠️ **KRITISK:** Denne rutine manipulerer direkte med lagerbeholdning!

**Potentielle problemer:**
1. **Fejl midtvejs** → Lager fjernet men ikke gendannet
2. **Valutakurs fejl** → Forkert kostpris beregnet
3. **Concurrent access** → Race condition med andet lager-arbejde

**Anbefalinger:**
- Kør UDEN for åbningstid
- Test grundigt i test-miljø
- Backup før store opdateringer
- Overvåg logs nøje

---

## Changelog

| Dato | Ændring |
|---|---|
| 2025-12-09 | Dokumentation oprettet |
