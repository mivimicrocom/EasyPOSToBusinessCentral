# Teknisk Dokumentation: Flytnings Synkronisering (Movements)

**Retning:** EasyPOS → Business Central  
**Metode:** `DoSyncronizeMovemmentsTransaction`  
**API Endpoint:** `kmItemMove` (POST)  
**Trigger:** `EKSPORTERET = 0` (eller NULL), `ART = 14`  

---

## Oversigt

Synkroniserer alle lagerflytninger mellem butikker/afdelinger fra EasyPOS til Business Central. Dette omfatter interne overførsler, svind, regulering og omplacering af varer.

### Kørselsflow

```
Start DoSyncronizeMovemmentsTransaction
    ↓
Læs INI konfiguration ([MovementsTransaction])
    ↓
Hent Transaction ID fra GETNAVISION_TRANSID(1)
    ↓
Beregn dato-interval (Last run + Days to look for records)
    ↓
Hent flytninger hvor ART = 14 og EKSPORTERET = 0
    ↓
For hver flytning:
    ├─ Check om EPID findes i BC (GET kmItemMove)
    ├─ Hvis NEJ: POST flytning til BC
    └─ Marker som eksporteret (EKSPORTERET = EKSPORTERET + 1)
    ↓
Opdater Last run timestamp i INI
    ↓
Log resultat til SLADREHANK
    ↓
Slut
```

---

## Database Query

### Hent flytningstransaktioner til synkronisering

```sql
SELECT
    TR.TRANSID AS EPID,
    TR.FLYT_ID AS FlytningsID,
    TR.PLU_NR AS VareID,
    COALESCE(TR.V509INDEX, '') AS VariantID,
    TR.BOGFDATO AS BOGFORINGSDATO,
    AFD_FRA.NAVISION_IDX AS FraButik,
    AFD_TIL.NAVISION_IDX AS TilButik,
    CAST(TR.SALGSTK AS INTEGER) AS ANTAL,
    TR.KOSTPRSTK * TR.SALGSTK AS KostPris,
    TR.EKSPORTERET
FROM
    TRANSAKTIONER TR
    LEFT JOIN AFDELING AFD_FRA ON TR.AFDNR = AFD_FRA.AFDELINGSNUMMER
    LEFT JOIN AFDELING AFD_TIL ON TR.AFDNR_FRABUTIK_TIL = AFD_TIL.AFDELINGSNUMMER
WHERE
    TR.ART = 14                         -- Flytninger
    AND TR.BOGFDATO >= :PStartDato
    AND TR.BOGFDATO <= :PSlutDato
    AND (TR.EKSPORTERET >= 0 OR TR.EKSPORTERET IS NULL)
ORDER BY
    TR.TRANSID
```

**Parametre:**
- `:PStartDato` - Sidste kørsel minus X dage
- `:PSlutDato` - Nu

**ART kode:**
- `14` = Lagerflytning

---

## Data Mapping (TkmItemMove)

| BC Felt | EasyPOS Felt | Type | Beregning | Beskrivelse |
|---------|--------------|------|-----------|-------------|
| `transId` | Transaction ID | Integer | Fra SP | Unikt ID for denne synk |
| `flytningsId` | `TRANSAKTIONER.FLYT_ID` | String | - | Flytnings ID (gruppering) |
| `VareId` | `TRANSAKTIONER.PLU_NR` | String | - | Varenummer (hovedvare) |
| `variantId` | `TRANSAKTIONER.V509INDEX` | String | - | Variant stregkode |
| `epId` | `TRANSAKTIONER.TRANSID` | Integer | - | EasyPOS Transaction ID |
| `bogfRingsDato` | `TRANSAKTIONER.BOGFDATO` | String | dd-mm-yyyy | Bogføringsdato |
| `fraButik` | `AFD_FRA.NAVISION_IDX` | String | Lookup | Fra butik (BC ID) |
| `tilButik` | `AFD_TIL.NAVISION_IDX` | String | Lookup | Til butik (BC ID) |
| `antal` | `TRANSAKTIONER.SALGSTK` | Integer | TRUNC() | Antal flyttet (heltal) |
| `kostPris` | Beregnet | Double | `KostPris / Antal` | Kostpris per stk |

### Særlige Beregninger

**Antal - CAST til Integer:**
```sql
CAST(TR.SALGSTK AS INTEGER)
```

Alternativt i Delphi:
```pascal
lkmItemMove.antal := TRUNC(QFetchMovementsTransactions.FieldByName('Antal').AsFloat);
```

**Kostpris per stk:**
```pascal
if (Antal <> 0) then
  kostPris := KostPris / Antal
else
  kostPris := 0;
```

---

## Business Central API Calls

### 1. Check om flytning findes (GET)

**Endpoint:** `GET /kmItemMove?$filter=epid eq {transId}`

**Formål:** Undgå duplikater

**Response:**
- Count = 0: Flytning findes ikke → POST ny
- Count > 0: Flytning findes → Skip

### 2. Opret ny flytning (POST)

**Endpoint:** `POST /kmItemMove`

**Body:**
```json
{
  "transId": 123456,
  "flytningsId": "FLY20260219001",
  "VareId": "1001",
  "variantId": "1001-XL-BLUE",
  "epId": 987654,
  "bogfRingsDato": "19-02-2026",
  "fraButik": "SHOP001",
  "tilButik": "SHOP002",
  "antal": 10,
  "kostPris": 50.00
}
```

**Success Response:** 201 Created

---

## Marker som Eksporteret

```sql
UPDATE TRANSAKTIONER 
SET EKSPORTERET = :PEksporteret 
WHERE 
    ART IN (14) 
    AND TRANSID = :PTransID 
    AND (EKSPORTERET >= 0 OR EKSPORTERET IS NULL)
```

**Parametre:**
- `:PEksporteret` = Nuværende EKSPORTERET + 1
- `:PTransID` = EPID

---

## Flytningstyper

I EasyPOS kan flytninger være forskellige typer baseret på `FLYT_ID`:

| Type | Beskrivelse | Fra/Til |
|------|-------------|---------|
| **Intern transfer** | Flytning mellem butikker | Butik A → Butik B |
| **Svind** | Kassation/svind | Butik → (tom) |
| **Regulering** | Lagerjustering | (tom) → Butik |
| **Omplacering** | Intern omflytning | Afd. 1 → Afd. 2 (samme butik) |

**Gruppering:** Alle linjer med samme `FLYT_ID` hører til samme flytning.

---

## Fejlhåndtering

### Fejlscenarier

| Fejl | HTTP Code | Handling |
|------|-----------|----------|
| POST fejler | 4xx/5xx | Log fejl, send email, fortsæt |
| Duplikat | 200 | Skip POST, marker som eksporteret |
| BC Rate limiting | 503 | Stop synk |
| Database UPDATE fejl | Exception | Log fejl, fortsæt (vil gensynkes) |

### Error Log

**Fil:** `Log[YYYYMMDD]_Movements_Error.txt`

**Format:**
```
Unexpected error when inserting movement transaction in Business Central.
  EP ID: 987654
  Code: 500
  Message: Internal Server Error

Unexpected error when marking movement transaction exported in EasyPOS
  EP ID: 987654
  Message: [exception]
```

### Windows Event Log

**Event IDs:**
- `3301` - Fejl ved POST til BC
- `3302` - Fejl ved marking eksporteret
- `3303` - Generel Movements synk fejl

---

## Tracing Log (SLADREHANK)

```sql
INSERT INTO SLADREHANK (
    DATO,
    ART,            -- 3011 (success) / 3012 (error)
    BONTEXT,
    BETXT1,         -- Transaction ID
    BETXT2,         -- Antal flytninger
    BETXT3,
    BETXT4
) VALUES (
    NOW,
    3011,
    'Movement transactions synced to BC',
    '123456',
    '47',
    '',
    ''
)
```

---

## INI Konfiguration

```ini
[SYNCRONIZE]
MovementsTransactions=1    ; 1=aktiveret, 0=deaktiveret

[MovementsTransaction]
Last run=45000.6               ; Auto-opdateres
Days to look for records=5
```

---

## Performance Overvejelser

### Typiske Kørselsstatistikker

- **Flytninger per dag:** 50-200 linjer
- **Tid per linje:** ~200ms
- **Total tid:** 3-7 minutter
- **Kritikalitet:** Medium (ikke kritisk som salg, men vigtigt for lagerstyring)

### Optimeringer

1. **Duplikat check:** GET før POST
2. **Integer casting:** Reducerer datatype issues
3. **Batch ikke implementeret**

---

## Debug Tips

### Test Mode

```ini
[PROGRAM]
TestRoutine=1
```

### Verificer Flytninger

```sql
-- Find ikke-eksporterede flytninger
SELECT COUNT(*) 
FROM TRANSAKTIONER 
WHERE ART = 14 
  AND (EKSPORTERET = 0 OR EKSPORTERET IS NULL)
  AND BOGFDATO >= CURRENT_DATE - 7;

-- Find flytninger grupperet på FLYT_ID
SELECT FLYT_ID, COUNT(*) AS AntalLinjer, SUM(SALGSTK) AS TotalAntal
FROM TRANSAKTIONER
WHERE ART = 14 
  AND BOGFDATO >= CURRENT_DATE - 7
GROUP BY FLYT_ID
ORDER BY FLYT_ID;

-- Verificer butikker
SELECT DISTINCT 
    TR.AFDNR,
    AFD_FRA.NAVISION_IDX AS FraButik,
    TR.AFDNR_FRABUTIK_TIL,
    AFD_TIL.NAVISION_IDX AS TilButik
FROM TRANSAKTIONER TR
LEFT JOIN AFDELING AFD_FRA ON TR.AFDNR = AFD_FRA.AFDELINGSNUMMER
LEFT JOIN AFDELING AFD_TIL ON TR.AFDNR_FRABUTIK_TIL = AFD_TIL.AFDELINGSNUMMER
WHERE TR.ART = 14
  AND TR.BOGFDATO >= CURRENT_DATE - 1;
```

### Common Issues

**Problem:** Flytning synkroniseres ikke

**Check:**
1. Er `EKSPORTERET = 0` eller NULL?
2. Er `ART = 14`?
3. Er `MovementsTransactions=1` i INI?
4. Har både fra og til butik et NAVISION_IDX?

**Problem:** Antal er forkert i BC

**Check:** Er SALGSTK et heltal? Hvis decimal bruges TRUNC() til at runde ned.

---

## Dependencies

### Database Tabeller
- `TRANSAKTIONER` - Flytningstransaktioner
- `AFDELING` - Butikker (lookup for NAVISION_IDX)
- `SLADREHANK` - Tracing log

### Stored Procedures
- `GETNAVISION_TRANSID(1)`

### Business Central Endpoints
- `kmItemMove` - Flytninger CRUD

---

## Se Også

- [README.md](../README.md) - Projekt oversigt
- [TECH_Sync_Sales.md](TECH_Sync_Sales.md) - Salg synkronisering
- [TECH_Sync_Financial.md](TECH_Sync_Financial.md) - Finansposter
- [Internal/Sync_3_Movements.md](Internal/Sync_3_Movements.md) - Detaljeret dokumentation
