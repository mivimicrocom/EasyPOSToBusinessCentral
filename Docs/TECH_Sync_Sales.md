# Teknisk Dokumentation: Salgs Synkronisering (Sales Transactions)

**Retning:** EasyPOS → Business Central  
**Metode:** `DoSyncronizeSalesTransactions`  
**API Endpoint:** `kmItemSale` (POST)  
**Trigger:** `EKSPORTERET = 0` (eller NULL) i `TRANSAKTIONER` tabel  

---

## Oversigt

Synkroniserer alle salgstransaktioner fra EasyPOS kasseapparater til Business Central. Hver salgslinje (bon-linje) fra en kunde-transaktion eksporteres individuelt med pris, moms, rabat og tidsstempel.

### Kørselsflow

```
Start DoSyncronizeSalesTransactions
    ↓
Læs INI konfiguration ([SalesTransaction])
    ↓
Hent Transaction ID fra GETNAVISION_TRANSID(1)
    ↓
Beregn dato-interval (Last run + Days to look for records)
    ↓
Hent salg hvor ART IN (0,1) og EKSPORTERET = 0
    ↓
For hver salgslinje:
    ├─ Check om EPID findes i BC (GET kmItemSale)
    ├─ Hvis NEJ: POST salgslinje til BC
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

### Hent salgstransaktioner til synkronisering

```sql
SELECT
    TR.TRANSID AS EPID,
    TR.BONNR AS Bonnummer,
    TR.BOGFDATO AS BOGFORINGSDATO,
    TR.PLU_NR AS VareID,
    TR.SALGSTK AS Antal,
    TR.SAMLETMOMS AS MomsBelob,
    TR.SAMLETPRIS AS Salgspris,
    TR.KOSTPRSTK * TR.SALGSTK AS KostPris,
    TR.RABATSTK,
    TR.EKSPORTERET,
    TR.EKSTERN AS Ekstern,
    TR.MOMS AS MomsSats,
    TR.AFDNR AS Afdeling,
    TR.RABATPCT,
    TR.MASKINE AS Kasse,
    TR.FAKTURANR,
    TR.S_OPDAGTIL,
    TR.S_LEVTIL,
    COALESCE(TR.V509INDEX, '') AS VariantID,
    COALESCE(A.NAVISION_IDX, '') AS ButiksID,
    COALESCE(VV.LAENGDE_NAVN, '') AS LaengdeNavn
FROM 
    TRANSAKTIONER TR
    LEFT JOIN AFDELING A ON TR.AFDNR = A.AFDELINGSNUMMER
    LEFT JOIN VAREFRVSTR VV ON TR.V509INDEX = VV.V509INDEX
WHERE
    TR.ART IN (0, 1)                    -- Salg (0=normal, 1=returvare)
    AND TR.BOGFDATO >= :PStartDato
    AND TR.BOGFDATO <= :PSlutDato
    AND (TR.EKSPORTERET >= 0 OR TR.EKSPORTERET IS NULL)
ORDER BY
    TR.TRANSID
```

**Parametre:**
- `:PStartDato` - Sidste kørsel minus X dage
- `:PSlutDato` - Nu

**ART koder:**
- `0` = Normal salg
- `1` = Returvare

---

## Data Mapping (TkmItemSale)

| BC Felt | EasyPOS Felt | Type | Beregning | Beskrivelse |
|---------|--------------|------|-----------|-------------|
| `transId` | Transaction ID | Integer | Fra SP | Unikt ID for denne synk |
| `epId` | `TRANSAKTIONER.TRANSID` | Integer | - | EasyPOS Transaction ID (PK) |
| `bonNummer` | `TRANSAKTIONER.BONNR` | Integer | - | Bonnummer |
| `VareId` | `TRANSAKTIONER.PLU_NR` | String | - | Varenummer (hovedvare) |
| `variantId` | `TRANSAKTIONER.V509INDEX` | String | - | Variant stregkode/barcode |
| `bogfRingsDato` | `TRANSAKTIONER.BOGFDATO` | String | dd-mm-yyyy | Bogføringsdato |
| `salgstidspunkt` | `TRANSAKTIONER.BOGFDATO` | String | hh:mm:ss | Salgstidspunkt |
| `antal` | `TRANSAKTIONER.SALGSTK` | Double | - | Antal solgt |
| `momsbelB` | Beregnet | Double | `MomsBelob / Antal` | Moms per stk |
| `salgspris` | Beregnet | Double | `Salgspris / Antal` | Salgspris per stk (inkl moms) |
| `kostPris` | Beregnet | Double | `KostPris / Antal` | Kostpris per stk |
| `rabatstk` | `TRANSAKTIONER.RABATSTK` | Double | - | Rabat per stk |
| `ekstern` | `TRANSAKTIONER.EKSTERN` | Integer | - | Ekstern markering |
| `momsSats` | `TRANSAKTIONER.MOMS` | Double | - | Momssats (%) |
| `afdeling` | `TRANSAKTIONER.AFDNR` | String | - | Afdeling/butik nummer |
| `rabatpct` | `TRANSAKTIONER.RABATPCT` | Double | - | Rabat procent |
| `kasse` | `TRANSAKTIONER.MASKINE` | String | - | Kasse/maskine ID |
| `fakturaId` | `TRANSAKTIONER.FAKTURANR` | String | - | Faktura nummer (hvis relevant) |
| `solgtTil` | `TRANSAKTIONER.S_OPDAGTIL` | String | - | Solgt til kunde |
| `leverttil` | `TRANSAKTIONER.S_LEVTIL` | String | - | Leveret til adresse |
| `butik` | `AFDELING.NAVISION_IDX` | String | Lookup | BC butiks ID |
| `laengdeNavn` | `VAREFRVSTR.LAENGDE_NAVN` | String | Lookup | Variant længde/størrelse |

### Særlige Beregninger

**Når Antal ≠ 0:**
```pascal
momsbelB := MomsBelob / Antal
salgspris := Salgspris / Antal  
kostPris := KostPris / Antal
```

**Når Antal = 0:** (edge case - returnering)
```pascal
momsbelB := 0
salgspris := 0
kostPris := 0
```

---

## Business Central API Calls

### 1. Check om salgslinje findes (GET)

**Endpoint:** `GET /kmItemSale?$filter=epId eq {transId}`

**Formål:** Undgå duplikater - check om EPID allerede eksisterer i BC

**Response:**
- Count = 0: Salgslinje findes ikke → POST ny
- Count > 0: Salgslinje findes allerede → Skip (allerede synkroniseret)

### 2. Opret ny salgslinje (POST)

**Endpoint:** `POST /kmItemSale`

**Body:**
```json
{
  "transId": 123456,
  "epId": 987654,
  "bonNummer": 1234,
  "VareId": "1001",
  "variantId": "1001-XL-BLUE",
  "bogfRingsDato": "19-02-2026",
  "salgstidspunkt": "14:23:15",
  "antal": 2.0,
  "momsbelB": 49.80,
  "salgspris": 199.00,
  "kostPris": 50.00,
  "rabatstk": 0.0,
  "ekstern": 0,
  "momsSats": 25.0,
  "afdeling": "001",
  "rabatpct": 0.0,
  "kasse": "KASSE01",
  "fakturaId": "",
  "solgtTil": "John Doe",
  "leverttil": "Main Street 123",
  "butik": "SHOP001",
  "laengdeNavn": "XL"
}
```

**Success Response:** 201 Created

---

## Marker som Eksporteret

Efter succesfuld POST til BC markeres transaktionen:

```sql
UPDATE TRANSAKTIONER 
SET EKSPORTERET = :PEksporteret 
WHERE 
    ART IN (0,1) 
    AND TRANSID = :PTransID 
    AND (EKSPORTERET >= 0 OR EKSPORTERET IS NULL)
```

**Parametre:**
- `:PEksporteret` = Nuværende EKSPORTERET + 1
- `:PTransID` = EPID

**Vigtigt:** EKSPORTERET incrementeres (ikke bare sat til 1) så man kan se hvor mange gange en linje er synkroniseret.

---

## Fejlhåndtering

### Fejlscenarier

| Fejl | HTTP Code | Handling |
|------|-----------|----------|
| POST fejler | 4xx/5xx | Log fejl, send email, fortsæt med næste |
| Duplikat (GET finder eksisterende) | 200 | Skip POST, marker stadig som eksporteret |
| BC Rate limiting | 503 | Gem timestamp, stop synk |
| Database UPDATE fejl | Exception | Log fejl, fortsæt (linje vil gensynkes) |

### Error Log

**Fil:** `Log[YYYYMMDD]_Sales_Error.txt`

**Format:**
```
Unexpected error when inserting sales transaction in Business Central.
  EP ID: 987654
  Code: 500
  Message: Internal Server Error - [detaljer]

Unexpected error when marking sale transaction exported in EasyPOS
  EP ID: 987654
  Message: [database exception]
```

### Windows Event Log

**Event IDs:**
- `3201` - Fejl ved POST til BC
- `3202` - Fejl ved marking eksporteret i EasyPOS
- `3203` - Generel Sales synk fejl

---

## Tracing Log (SLADREHANK)

```sql
INSERT INTO SLADREHANK (
    DATO,           -- NOW
    ART,            -- 3005 (success) / 3006 (error)
    BONTEXT,        -- Beskrivelse
    BETXT1,         -- Transaction ID
    BETXT2,         -- Antal eksporterede salgslinjer
    BETXT3,         -- Empty
    BETXT4          -- Empty
) VALUES (
    NOW,
    3005,
    'Sales transactions synced to BC',
    '123456',
    '247',
    '',
    ''
)
```

---

## INI Konfiguration

```ini
[SYNCRONIZE]
SalesTransactions=1    ; 1=aktiveret, 0=deaktiveret

[SalesTransaction]
Last run=45000.6123456              ; Auto-opdateres efter succes
Days to look for records=5           ; Hvor langt tilbage der søges
```

---

## Performance Overvejelser

### Typiske Kørselsstatistikker

- **Salgslinjer per dag:** 500-2000 linjer (afhængig af butiksstørrelse)
- **Tid per linje:** ~200ms (GET + POST)
- **Total tid:** 5-10 minutter for 1000 linjer
- **BC API calls:** 2 per salgslinje (GET + POST hvis ny)

### Kritisk for Drift

⚠️ **Denne synk er KRITISK** - skal køre dagligt minimum!

Hvis salg ikke synkroniseres:
- Manglende omsætning i BC
- Forkert lagerbeholdning
- Manglende regnskabsdata

### Optimeringer

1. **Duplikat check:** GET før POST reducerer load ved gensynk
2. **Increment EKSPORTERET:** Sporbarhed af retry attempts
3. **Batch ikke implementeret:** Hver linje individuelt
4. **Stop ved 503:** Undgår BC overload

---

## Debug Tips

### Test Mode

```ini
[PROGRAM]
TestRoutine=1    ; Ingen data eksporteres
```

### Verificer Salg

```sql
-- Find ikke-eksporterede salg
SELECT COUNT(*) 
FROM TRANSAKTIONER 
WHERE ART IN (0,1) 
  AND (EKSPORTERET = 0 OR EKSPORTERET IS NULL)
  AND BOGFDATO >= CURRENT_DATE - 7;

-- Find salg eksporteret flere gange (retry indikator)
SELECT TRANSID, EKSPORTERET 
FROM TRANSAKTIONER 
WHERE EKSPORTERET > 1 
ORDER BY EKSPORTERET DESC;
```

### Common Issues

**Problem:** Salg synkroniseres ikke

**Check:**
1. Er `EKSPORTERET = 0` eller NULL?
2. Er `ART` = 0 eller 1?
3. Er `SalesTransactions=1` i INI?
4. Ligger dato i intervallet?

**Problem:** Duplikater i BC

**Løsning:** GET check burde forhindre dette, men hvis det sker:
```sql
-- Find duplikater i EasyPOS
SELECT TRANSID, COUNT(*) 
FROM TRANSAKTIONER 
WHERE EKSPORTERET > 1 
GROUP BY TRANSID;
```

I BC skal duplikater slettes manuelt via API eller BC interface.

---

## Dependencies

### Database Tabeller
- `TRANSAKTIONER` - Salgslinjer
- `AFDELING` - Butikker/afdelinger (lookup for NAVISION_IDX)
- `VAREFRVSTR` - Varianter (lookup for LAENGDE_NAVN)
- `SLADREHANK` - Tracing log

### Stored Procedures
- `GETNAVISION_TRANSID(1)` - Hent unikt Transaction ID

### Business Central Endpoints
- `kmItemSale` - Salgstransaktioner CRUD

---

## Se Også

- [README.md](../README.md) - Projekt oversigt
- [TECH_Sync_Items.md](TECH_Sync_Items.md) - Vare synkronisering
- [TECH_Sync_Movements.md](TECH_Sync_Movements.md) - Flytninger
- [Internal/Sync_2_Sales.md](Internal/Sync_2_Sales.md) - Detaljeret intern dokumentation
