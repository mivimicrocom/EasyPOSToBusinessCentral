# Teknisk Dokumentation: Finans Synkronisering (Financial Records)

**Retning:** EasyPOS → Business Central  
**Metode:** `DoSyncronizeFinansCialRecords`  
**API Endpoint:** `kmCashstatement` (POST)  
**Trigger:** `BEHANDLET = 0` (eller NULL) i `POSTERINGER` tabel  

---

## Oversigt

Synkroniserer alle finansposter (kassekladde, Z-rapporter, betalingsformer) fra EasyPOS til Business Central. Dette omfatter omsætning, debitorposteringer, bankindbetalinger, gavekort, tilgodesedler og andre økonomiske transaktioner.

### Kørselsflow

```
Start DoSyncronizeFinansCialRecords
    ↓
Læs INI konfiguration ([FinancialRecords])
    ↓
Hent Transaction ID fra GETNAVISION_TRANSID(1)
    ↓
Beregn dato-interval (Last run + Days to look for records)
    ↓
Hent posteringer hvor BEHANDLET = 0
    ↓
For hver postering:
    ├─ Check om ID findes i BC (GET kmCashstatement)
    ├─ Hvis NEJ:
    │   ├─ Map PostType til BC type (0=Finans, 1=Debitor, 2=Bank)
    │   ├─ POST til BC
    │   └─ Skriv til eksportfil (optional logging)
    └─ Marker som behandlet (BEHANDLET = BEHANDLET + 1)
    ↓
Opdater Last run timestamp i INI
    ↓
Log resultat til SLADREHANK
    ↓
Slut
```

---

## Database Query

### Hent finansposteringer til synkronisering

```sql
SELECT
    P.ID,
    P.DATO,
    P.TEKST,
    P.POSTTYPE,
    P.KONTONR,
    P.BELOB,
    P.BILAGSNR,
    P.AFDELING_ID,
    P.SORTERING,
    A.AFDELINGSNUMMER AS Afdeling,
    UA.NAVN AS UAfd_Navn
FROM
    POSTERINGER P
    LEFT JOIN AFDELING A ON P.AFDELING_ID = A.ID
    LEFT JOIN UNDERAFDELING UA ON P.UNDERAFDELING_ID = UA.ID
WHERE
    P.DATO >= :PStartDato
    AND P.DATO <= :PSlutDato
    AND (P.BEHANDLET = 0 OR P.BEHANDLET IS NULL)
ORDER BY
    P.ID
```

**Parametre:**
- `:PStartDato` - Sidste kørsel minus X dage
- `:PSlutDato` - Nu

---

## PostType Mapping

EasyPOS `POSTERINGER.POSTTYPE` mappes til Business Central `type_`:

| PostType | EP Betydning | BC Type | BC Betydning | Kommentar |
|----------|--------------|---------|--------------|-----------|
| `0` | Finans/Omsætning | `'0'` | Finans | Standard finanspost |
| `1` | Debitor | `'1'` | Debitor | Kundepostering |
| `2` | Bank | `'2'` | Bank | Bankpostering |
| `3` | Indbetaling | `'1'` | Debitor | Kundeind betaling |
| `4` | Udbetaling | `'0'` | Finans | Standard, **men** hvis KontoNr='86123444' → Type='2' (Bank) |
| `5` | Afrunding | `'0'` | Finans | Kasseafrunding |
| `7` | Difference | `'0'` | Finans | Kassedifference |
| `8` | Forskydning | `'0'` | Finans | Tidsforskydning |
| `21` | A conto | `'1'` | Debitor | A conto betaling |
| `22` | Tilgodeseddel | `'0'` | Finans | Både udstedt/modtaget |
| `23` | Gavekort | `'0'` | Finans | Både udstedt/modtaget |
| `25` | Fragt | `'0'` | Finans | Fragtomkostning |
| `99` | Internt afd. salg | `'0'` | Finans | Intern handel |

### Speciel Logik

**Udbetaling (PostType = 4):**
```pascal
if (PostType = 4) then
begin
  type_ := '0';  // Finans
  if (KontoNr = '86123444') then
    type_ := '2';  // ⚠️ Specifik kunde-hack: Bank i stedet
end;
```

**Tilgodeseddel (PostType = 22):**
```pascal
if (PostType = 22) then
begin
  if (Sortering = 50) then
    // Modtaget tilgodeseddel
    type_ := '0';
  else
    // Udstedt tilgodeseddel
    type_ := '0';
end;
```

**Gavekort (PostType = 23):**
```pascal
if (PostType = 23) then
begin
  if (Sortering = 120) then
    // Modtaget gavekort
    type_ := '0';
  else
    // Udstedt gavekort
    type_ := '0';
end;
```

---

## Data Mapping (TkmCashstatement)

| BC Felt | EasyPOS Felt | Type | Beskrivelse |
|---------|--------------|------|-------------|
| `transId` | Transaction ID | Integer | Unikt ID for denne synk |
| `epId` | `POSTERINGER.ID` | Integer | Posteringens ID (PK) |
| `transDato` | `NOW` | String (dd-mm-yyyy) | Synk dato |
| `transTid` | `NOW` | String (hh:mm:ss) | Synk tidspunkt |
| `bogfRingsDato` | `POSTERINGER.DATO` | String (dd-mm-yyyy) | Bogføringsdato |
| `kasseOpgRelsestidspunkt` | - | String | Tom (ikke brugt) |
| `text` | `POSTERINGER.TEKST` | String(50) | Beskrivelse (max 50 tegn) |
| `type_` | Beregnet | String | '0'=Finans, '1'=Debitor, '2'=Bank |
| `id` | `POSTERINGER.KONTONR` | String | Kontonummer eller debitornummer |
| `bilagsnummer` | `POSTERINGER.BILAGSNR` | String | Bilagsnummer |
| `afdeling` | `AFDELING.AFDELINGSNUMMER` | String | Afdeling/butik |
| `kasse` | `UNDERAFDELING.NAVN` | String | Kasse/maskine navn |
| `belB` | `POSTERINGER.BELOB` | Double | Beløb |
| `butik` | Beregnet | String | BC butiks ID (fra GetButiksID) |
| `status` | `'0'` | String | Altid '0' |

### GetButiksID Function

```sql
SELECT NAVISION_IDX 
FROM AFDELING 
WHERE AFDELINGSNUMMER = :P1
```

Returnerer BC butiks ID for given afdeling.

---

## Business Central API Calls

### 1. Check om posterining findes (GET)

**Endpoint:** `GET /kmCashstatement?$filter=epId eq {id}`

**Response:**
- Count = 0: Postering findes ikke → POST ny
- Count > 0: Postering findes → Skip

### 2. Opret ny postering (POST)

**Endpoint:** `POST /kmCashstatement`

**Body - Finans (type = '0'):**
```json
{
  "transId": 123456,
  "epId": 45678,
  "transDato": "19-02-2026",
  "transTid": "15:30:00",
  "bogfRingsDato": "19-02-2026",
  "kasseOpgRelsestidspunkt": "",
  "text": "Dagsomsætning",
  "type_": "0",
  "id": "1000",
  "bilagsnummer": "Z20260219",
  "afdeling": "001",
  "kasse": "KASSE01",
  "belB": 15750.50,
  "butik": "SHOP001",
  "status": "0"
}
```

**Body - Debitor (type = '1'):**
```json
{
  "transId": 123457,
  "epId": 45679,
  "transDato": "19-02-2026",
  "transTid": "15:31:00",
  "bogfRingsDato": "19-02-2026",
  "text": "Faktura betaling",
  "type_": "1",
  "id": "CUST001",
  "bilagsnummer": "FAK12345",
  "afdeling": "001",
  "kasse": "KONTOR",
  "belB": -5000.00,
  "butik": "SHOP001",
  "status": "0"
}
```

**Body - Bank (type = '2'):**
```json
{
  "transId": 123458,
  "epId": 45680,
  "transDato": "19-02-2026",
  "transTid": "15:32:00",
  "bogfRingsDato": "19-02-2026",
  "text": "Kortbetaling",
  "type_": "2",
  "id": "86123444",
  "bilagsnummer": "KORT-001",
  "afdeling": "001",
  "kasse": "KASSE01",
  "belB": 1250.00,
  "butik": "SHOP001",
  "status": "0"
}
```

**Success Response:** 201 Created

---

## Marker som Behandlet

```sql
UPDATE POSTERINGER 
SET BEHANDLET = BEHANDLET + 1 
WHERE 
    POSTERINGER.ID = :PID
```

**Parametre:**
- `:PID` = Posteringens ID

**Vigtigt:** BEHANDLET incrementeres så man kan se retry attempts.

---

## Eksport Logfil (Optional)

Servicen kan skrive eksporterede posteringer til tekstfil:

**Fil:** `[LOGFILEFOLDER]\FinansEksport\EkspFinancialRecordsToBC[YYYYMMDDHH].Txt`

**Format:** CSV med semikolon delimiter

**Header:**
```
EpID;TransID;TransDato;TransTid;BogføringsDato;BogføringsTid;Bilagsnummer;Tekst;Type;ID;Maskine;Afdeling;Butik;Beløb
```

**Eksempel:**
```
45678;123456;19-02-2026;15:30:00;19-02-2026;00:00:00;Z20260219;Dagsomsætning;0;1000;KASSE01;001;SHOP001;15.750,50
45679;123457;19-02-2026;15:31:00;19-02-2026;00:00:00;FAK12345;Faktura betaling;1;CUST001;KONTOR;001;SHOP001;-5.000,00
```

---

## Fejlhåndtering

### Fejlscenarier

| Fejl | HTTP Code | Handling |
|------|-----------|----------|
| POST fejler | 4xx/5xx | Log fejl, send email, fortsæt |
| Duplikat | 200 | Skip POST, marker som behandlet |
| Type mapping fejl | - | Log warning, brug default '0' |
| UPDATE fejl | Exception | Log fejl, fortsæt (gensynkes) |

### Error Log

**Fil:** `Log[YYYYMMDD]_Financial_Error.txt`

**Format:**
```
Unexpected error when inserting financial record in Business Central.
  EP ID: 45678
  Code: 500
  Message: Internal Server Error

Unexpected error when marking financial record exported in EasyPOS
  EP ID: 45678
  Message: [exception]
```

### Windows Event Log

**Event IDs:**
- `3402` - Fejl ved POST til BC
- `3403` - Fejl ved marking behandlet

---

## Tracing Log (SLADREHANK)

```sql
INSERT INTO SLADREHANK (
    DATO,
    ART,            -- 3015 (success) / 3016 (error)
    BONTEXT,
    BETXT1,         -- Transaction ID
    BETXT2,         -- Antal posteringer
    BETXT3,
    BETXT4
) VALUES (
    NOW,
    3015,
    'Financial records synced to BC',
    '123456',
    '127',
    '',
    ''
)
```

---

## INI Konfiguration

```ini
[SYNCRONIZE]
FinancialRecords=1    ; 1=aktiveret, 0=deaktiveret

[FinancialRecords]
Last run=45000.7                 ; Auto-opdateres
Days to look for records=5
```

---

## Performance Overvejelser

### Typiske Kørselsstatistikker

- **Posteringer per dag:** 100-500 linjer
- **Tid per linje:** ~200ms
- **Total tid:** 3-8 minutter
- **Kritikalitet:** HØJ - vigtig for regnskab!

### Økonomisk Impact

⚠️ **Denne synk er KRITISK for økonomi:**
- Z-rapporter (dagsomsætning)
- Betalingsformer (kontant, kort, MobilePay)
- Debitorposteringer
- Bankindbetalinger

Fejl betyder manglende regnskabsposter i BC!

---

## Debug Tips

### Test Mode

```ini
[PROGRAM]
TestRoutine=1
```

### Verificer Posteringer

```sql
-- Find ikke-behandlede posteringer
SELECT ID, POSTTYPE, TEKST, BELOB, DATO
FROM POSTERINGER 
WHERE (BEHANDLET = 0 OR BEHANDLET IS NULL)
  AND DATO >= CURRENT_DATE - 7
ORDER BY DATO;

-- PostType fordeling
SELECT POSTTYPE, COUNT(*) AS Antal, SUM(BELOB) AS TotalBelob
FROM POSTERINGER
WHERE DATO >= CURRENT_DATE - 7
GROUP BY POSTTYPE
ORDER BY POSTTYPE;

-- Find bank-konvertering (PostType=4, KontoNr=86123444)
SELECT * FROM POSTERINGER
WHERE POSTTYPE = 4 
  AND KONTONR = '86123444'
  AND DATO >= CURRENT_DATE - 7;
```

### Common Issues

**Problem:** Posteringer synkroniseres ikke

**Check:**
1. Er `BEHANDLET = 0` eller NULL?
2. Er `FinancialRecords=1` i INI?
3. Ligger dato i intervallet?

**Problem:** Forkert type i BC

**Check:** PostType mapping - se tabel ovenfor. Er der speciel logik (konto 86123444)?

---

## Dependencies

### Database Tabeller
- `POSTERINGER` - Finansposteringer
- `AFDELING` - Butikker (for NAVISION_IDX)
- `UNDERAFDELING` - Kasser/maskiner
- `SLADREHANK` - Tracing log

### Stored Procedures
- `GETNAVISION_TRANSID(1)`

### Business Central Endpoints
- `kmCashstatement` - Finansposter CRUD

---

## Se Også

- [README.md](../README.md) - Projekt oversigt
- [TECH_Sync_Sales.md](TECH_Sync_Sales.md) - Salg
- [TECH_Sync_Costprice.md](TECH_Sync_Costprice.md) - Kostpriser
- [Internal/Sync_4_Financial.md](Internal/Sync_4_Financial.md) - Detaljeret dokumentation
