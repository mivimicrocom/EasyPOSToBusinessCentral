# Teknisk Dokumentation: Vare Synkronisering (Items)

**Retning:** EasyPOS → Business Central  
**Metode:** `DoSyncronizeItems`  
**API Endpoint:** `kmItem` (POST)  
**Trigger:** `BC_UPDATEDATE` felt i `VARER` tabel  

---

## Oversigt

Synkroniserer hovedvarer (head items) og varianter fra EasyPOS til Business Central. Denne synkronisering er afgørende for at holde produktkataloget opdateret på tværs af begge systemer.

### Kørselsflow

```
Start DoSyncronizeItems
    ↓
Læs INI konfiguration ([Items] sektion)
    ↓
Hent Transaction ID fra GETNAVISION_TRANSID(1)
    ↓
Beregn dato-interval (Last run + Days to look for records)
    ↓
Hent varer hvor BC_UPDATEDATE ligger i intervallet
    ↓
For hver hovedvare:
    ├─ Check om hovedvare findes i BC (GET)
    ├─ Hvis NEJ: POST hovedvare til BC
    ├─ Marker hovedvare som eksporteret
    └─ For hver variant til hovedvaren:
        ├─ Check om variant findes i BC (GET)
        ├─ Hvis NEJ: POST variant til BC
        └─ Marker variant som eksporteret
    ↓
Opdater Last run timestamp i INI
    ↓
Log resultat til SLADREHANK
    ↓
Slut
```

---

## Database Queries

### Hent hovedvarer til synkronisering

```sql
SELECT DISTINCT
    V.PLU_NR AS VareID,
    V.VARENAVN1 AS Beskrivelse,
    V.KATEGORI1 AS Model,
    V.KOSTPRIS AS KostPris,
    V.SALGSPRIS1 AS SalgsPris,
    V.LEVKODE AS LeverandorKode,
    V.KATEGORI2 AS Varegruppe,
    V.VARENAVN2,
    V.VARENAVN3,
    V.INTRASTAT,
    V.ORIGIN_COUNTRY AS Country,
    V.ALT_VARE_NR,
    V.NETTOVGT AS Weigth,
    V.WEBVARER,
    L.NAVN AS leverid,
    VG.NAVN AS varegrpid
FROM 
    VARER V
    LEFT JOIN LEVERANDOR L ON V.LEVKODE = L.KODE
    LEFT JOIN VAREGRUPPE VG ON V.KATEGORI2 = VG.KODE
WHERE 
    V.BC_UPDATEDATE >= :PStartDato 
    AND V.BC_UPDATEDATE <= :PSlutDato
    AND V.PLU_NR NOT LIKE '%-%'  -- Kun hovedvarer (ikke varianter)
ORDER BY 
    V.PLU_NR
```

**Parametre:**
- `:PStartDato` - Sidste kørsel minus X dage (fra INI)
- `:PSlutDato` - Nu

### Hent varianter til en hovedvare

```sql
SELECT 
    VV.V509INDEX AS VariantID,
    VV.VAREPLU_ID AS VareID,
    VV.LAENGDE_NAVN AS Laengde,
    VV.EANNUMMER AS EAN,
    VV.FAERDIGVARER_LAGER AS AntalStk,
    VVD.VEJETKOSTPRISSTK,
    VVD.SALGSPRISSTK AS SalgsPrisStk,
    VV.LEVNR AS Leverandoerensvarenummer
FROM 
    VAREFRVSTR VV
    LEFT JOIN VAREFRVSTR_DETAIL VVD 
        ON VV.V509INDEX = VVD.V509INDEX 
        AND VVD.AFDELING_ID = :PDepartment
WHERE 
    VV.VAREPLU_ID = :PVAREPLU_ID
ORDER BY 
    VV.V509INDEX
```

**Parametre:**
- `:PVAREPLU_ID` - Hovedvarens PLU_NR
- `:PDepartment` - Afdeling (fra INI)

---

## Data Mapping - Hovedvare (TkmItem)

| BC Felt | EasyPOS Felt | Type | Beskrivelse |
|---------|--------------|------|-------------|
| `transId` | Transaction ID | Integer | Unikt ID for denne synk |
| `VareId` | `VARER.PLU_NR` | String | Varenummer (hovedvare ID) |
| `beskrivelse` | `VARER.VARENAVN1` | String(50) | Varebeskrivelse |
| `model` | `VARER.KATEGORI1` | String(50) | Model/kategori 1 |
| `kostPris` | `VARER.KOSTPRIS` | Double | Kostpris |
| `salgspris` | `VARER.SALGSPRIS1` | Double | Salgspris |
| `leverandRKode` | `VARER.LEVKODE` | String | Leverandørkode |
| `varegruppe` | `VARER.KATEGORI2` | String | Varegruppe |
| `status` | `'0'` | String | Altid '0' |
| `transDato` | `NOW` (dd-mm-yyyy) | String | Dato for synkronisering |
| `transTid` | `NOW` (hh:mm:ss) | String | Tidspunkt for synkronisering |
| `tariffNo` | `VARER.INTRASTAT` | String | Toldtarifnummer |
| `countryRegionOfOriginCode` | `VARER.ORIGIN_COUNTRY` | String | Oprindelsesland |
| `Varenavn2` | `VARER.VARENAVN2` | String | Ekstra beskrivelse 2 |
| `Varenavn3` | `VARER.VARENAVN3` | String | Ekstra beskrivelse 3 |
| `LeverandRnavn` | `LEVERANDOR.NAVN` | String | Leverandørnavn (lookup) |
| `Varegruppenavn` | `VAREGRUPPE.NAVN` | String | Varegruppenavn (lookup) |
| `Alternativtvarenummer` | `VARER.ALT_VARE_NR` | String | Alternativt varenummer |
| `netWeight` | `VARER.NETTOVGT` | Double | Nettovægt (default 1 hvis tom) |
| `WEBVare` | `VARER.WEBVARER <> 0` | Boolean | Er webvare? |
| `Farve` | `''` | String | Altid tom (kun på variant) |
| `Storrelse` | `''` | String | Altid tom (kun på variant) |
| `Laengde` | `''` | String | Altid tom (kun på variant) |
| `EANNummer` | `''` | String | Altid tom (kun på variant) |
| `Leverandoerensvarenummer` | `''` | String | Altid tom (kun på variant) |

---

## Data Mapping - Variant (TkmVariantId)

| BC Felt | EasyPOS Felt | Type | Beskrivelse |
|---------|--------------|------|-------------|
| `transId` | Transaction ID + 1 | Integer | Unikt ID (hovedvare ID + 1) |
| `VariantId` | `VAREFRVSTR.V509INDEX` | String | Stregkode/barcode |
| `VareId` | `VAREFRVSTR.VAREPLU_ID` | String | Reference til hovedvare |
| `Laengde` | `VAREFRVSTR.LAENGDE_NAVN` | String | Længde (f.eks. "XL", "42") |
| `EANNummer` | `VAREFRVSTR.EANNUMMER` | String | EAN barcode |
| `AntalStk` | `VAREFRVSTR.FAERDIGVARER_LAGER` | Integer | Lagerbeholdning |
| `VejetKostPrisStk` | `VAREFRVSTR_DETAIL.VEJETKOSTPRISSTK` | Double | Kostpris per stk |
| `SalgsPrisStk` | `VAREFRVSTR_DETAIL.SALGSPRISSTK` | Double | Salgspris per stk |
| `Leverandoerensvarenummer` | `VAREFRVSTR.LEVNR` | String | Leverandørens varenummer |
| `transDato` | `NOW` (dd-mm-yyyy) | String | Dato for synkronisering |
| `transTid` | `NOW` (hh:mm:ss) | String | Tidspunkt for synkronisering |

---

## Business Central API Calls

### 1. Check om hovedvare findes (GET)

**Endpoint:** `GET /kmItem?$filter=VareId eq '{vareId}'`

**Formål:** Undgå duplikater - check om hovedvare allerede eksisterer i BC

**Response:**
- Count = 0: Hovedvare findes ikke → POST ny
- Count > 0: Hovedvare findes allerede → Skip

### 2. Opret ny hovedvare (POST)

**Endpoint:** `POST /kmItem`

**Body:**
```json
{
  "transId": 123456,
  "VareId": "1001",
  "beskrivelse": "T-shirt Basic",
  "model": "Tøj",
  "kostPris": 50.00,
  "salgspris": 199.00,
  "leverandRKode": "LEV001",
  "varegruppe": "TSHIRT",
  "status": "0",
  "transDato": "19-02-2026",
  "transTid": "10:00:00",
  "tariffNo": "6109100010",
  "countryRegionOfOriginCode": "DK",
  ...
}
```

**Success Response:** 201 Created

### 3. Check om variant findes (GET)

**Endpoint:** `GET /kmVariantId?$filter=VariantId eq '{barcode}'`

**Formål:** Undgå duplikater - check om variant allerede eksisterer i BC

### 4. Opret ny variant (POST)

**Endpoint:** `POST /kmVariantId`

**Body:**
```json
{
  "transId": 123457,
  "VariantId": "1001-XL-BLUE",
  "VareId": "1001",
  "Laengde": "XL",
  "EANNummer": "5701234567890",
  "AntalStk": 10,
  "VejetKostPrisStk": 50.00,
  "SalgsPrisStk": 199.00,
  "Leverandoerensvarenummer": "TSHIRT-XL-BLU",
  "transDato": "19-02-2026",
  "transTid": "10:00:00"
}
```

**Success Response:** 201 Created

---

## Fejlhåndtering

### Fejlscenarier

| Fejl | HTTP Code | Handling |
|------|-----------|----------|
| Hovedvare POST fejler | 4xx/5xx | Stop variant-synk for denne vare, log fejl, fortsæt med næste hovedvare |
| Variant POST fejler | 4xx/5xx | Log fejl, fortsæt med næste variant |
| BC Rate limiting | 503 | Gem timestamp, vent til næste kørsel |
| Database fejl | Exception | Log fejl, send email, stop synk |

### Error Log

**Fil:** `Log[YYYYMMDD]_Items_Error.txt`

**Format:**
```
Unexpected error when inserting head item in Business Central.
  Head item number: 1001
  Code: 500
  Message: Internal Server Error - [detaljer]
  
Unexpected error when inserting variant in Business Central.
  Variant ID: 1001-XL
  Code: 400
  Message: Bad Request - [detaljer]
```

### Windows Event Log

**Event IDs:**
- `3101` - Fejl ved hovedvare POST
- `3102` - Fejl ved variant POST
- `3103` - Generel Items synk fejl

### Email Notifikation

Sendes ved fejl med attached logfil.

---

## Tracing Log (SLADREHANK)

```sql
INSERT INTO SLADREHANK (
    DATO,           -- NOW
    ART,            -- 3001 (success) / 3002 (error)
    BONTEXT,        -- Beskrivelse
    BETXT1,         -- Transaction ID
    BETXT2,         -- Antal hovedvarer
    BETXT3,         -- Antal varianter
    BETXT4          -- Fejltæller
) VALUES (
    NOW,
    3001,
    'Items synced to BC successfully',
    '123456',
    '15',
    '87',
    '0'
)
```

---

## INI Konfiguration

### [SYNCRONIZE] Sektion

```ini
[SYNCRONIZE]
Items=1    ; 1=aktiveret, 0=deaktiveret
```

### [Items] Sektion

```ini
[Items]
Last run=45000.9123456              ; Auto-opdateres efter succes
Days to look for records=5           ; Hvor langt tilbage der søges
Department=001                       ; Afdeling til variant-priser
```

**Last run format:** Delphi TDateTime (floating point)

---

## Performance Overvejelser

### Typiske Kørselsstatistikker

- **Hovedvarer per kørsel:** 10-50 varer
- **Varianter per hovedvare:** 5-20 varianter
- **Total tid:** 2-5 minutter (afhængig af BC response tid)
- **BC API calls:** 2 per hovedvare + 2 per variant (GET + POST)

### Optimeringer

1. **Skip eksisterende:** GET check før POST reducerer duplikater
2. **Batch ikke implementeret:** Hver vare/variant håndteres individuelt
3. **Transaction ID:** Unikt per synk for sporbarhed
4. **Error stop:** Hvis hovedvare fejler, springes varianter over

### Flaskehalse

- BC API response tid (typisk 100-500ms per request)
- Antal varianter per hovedvare (mange varianter = lang tid)
- Database locks (begrænset, kun ved UPDATE Eksporteret)

---

## BC_UPDATEDATE Trigger Logik

Varer markeres til synkronisering når `BC_UPDATEDATE` opdateres:

### Trigger: VARER_BC_CHANGES

**Aktiveres ved UPDATE af følgende felter:**
- `VARENAVN1`, `VARENAVN2`, `VARENAVN3`
- `KATEGORI1`, `KATEGORI2`
- `LEVKODE`, `INTRASTAT`, `ORIGIN_COUNTRY`
- `KOSTPRIS`, `SALGSPRIS1`
- `NETTOVGT`, `ALT_VARE_NR`, `WEBVARER`

**Action:** Sætter `BC_UPDATEDATE = CURRENT_TIMESTAMP`

### Trigger: VAREFRVSTR_BC_CHANGES

**Aktiveres ved UPDATE af variant-felter:**
- `LAENGDE_NAVN` (længde/størrelse)
- `EANNUMMER` (EAN barcode)
- `V509INDEX` (stregkode)
- `LEVNR` (leverandørens varenummer)

**Action:** Sætter `BC_UPDATEDATE = CURRENT_TIMESTAMP` på hovedvaren

### Manuel Force

```sql
-- Force synk af specifik vare
UPDATE VARER 
SET BC_UPDATEDATE = CURRENT_TIMESTAMP 
WHERE PLU_NR = '1001';
```

---

## Debug Tips

### Test Mode

```ini
[PROGRAM]
TestRoutine=1    ; Ingen data eksporteres til BC
```

I test mode:
- Alle queries køres
- JSON bygges
- Log skrives
- Men ingen POST til BC
- Ingen Eksporteret update

### SQL Log Filer

Queries gemmes til disk (hvis `SQLLogFileFolder` er sat):
- `FetchItems.SQL` - Hovedvare query
- `FetchVariantsToHeadItem.SQL` - Variant query

### Log Monitoring

```bash
# Tail main log
tail -f C:\Logs\EasyPOS_BC\Log20260219.txt

# Check for errors
findstr "ERROR" C:\Logs\EasyPOS_BC\Log20260219.txt
findstr "Items" C:\Logs\EasyPOS_BC\Log20260219_Items_Error.txt
```

### Common Issues

**Problem:** Vare synkroniseres ikke

**Check:**
1. Er `BC_UPDATEDATE` opdateret?
   ```sql
   SELECT PLU_NR, BC_UPDATEDATE 
   FROM VARER 
   WHERE PLU_NR = '1001';
   ```
2. Ligger datoen i intervallet? (Last run +/- Days to look for records)
3. Er `Items=1` i INI [SYNCRONIZE]?
4. Er varen en hovedvare? (PLU_NR må ikke indeholde '-')

**Problem:** Variant synkroniseres ikke

**Check:**
1. Blev hovedvaren synkroniseret korrekt? (Check log)
2. Findes variant i `VAREFRVSTR`?
3. Har variant data i `VAREFRVSTR_DETAIL` for den relevante afdeling?

---

## Dependencies

### Database Tabeller
- `VARER` - Hovedvarer
- `VAREFRVSTR` - Varianter
- `VAREFRVSTR_DETAIL` - Variant priser/lager per afdeling
- `LEVERANDOR` - Leverandører (lookup)
- `VAREGRUPPE` - Varegrupper (lookup)
- `SLADREHANK` - Tracing log

### Stored Procedures
- `GETNAVISION_TRANSID(1)` - Hent unikt Transaction ID

### Business Central Endpoints
- `kmItem` - Hovedvare CRUD
- `kmVariantId` - Variant CRUD

---

## Se Også

- [README.md](../README.md) - Projekt oversigt
- [Sync_Overview.md](Sync_Overview.md) - Alle synkroniseringer
- [BC_UPDATEDATE_Application_Overview.md](BC_UPDATEDATE_Application_Overview.md) - Trigger dokumentation
- [Internal/Sync_1_Items.md](Internal/Sync_1_Items.md) - Detaljeret intern dokumentation
