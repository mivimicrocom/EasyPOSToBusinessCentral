# P_UPDATEITEMS Stored Procedure - Komplet Analyse

**Database:** Kaufmann OCCEASYPOS (Firebird)  
**Analyseret:** 2025-12-09

---

## 📋 Procedure Signatur

```sql
CREATE OR ALTER PROCEDURE P_UPDATEITEMS (
    I_UUID         VARCHAR,     -- Input: UUID af record i CREATEUPDATE_ITEM
    I_MASTER_ID    INTEGER      -- Input: Master batch ID
)
RETURNS (
    O_SUCCES       INTEGER,     -- Output: Success code (0=ok, andet=fejl)
    O_MESSAGE      VARCHAR      -- Output: Besked eller fejlmeddelelse
)
AS
BEGIN
    -- Procedure implementation
    SUSPEND;
END
```

---

## 🎯 Formål

**P_UPDATEITEMS opdaterer eksisterende varer baseret på data i CREATEUPDATE_ITEM tabel.**

Procedure bruges til:
- ✅ Batch import af vare-opdateringer fra eksterne kilder
- ✅ WebOrder system opdateringer
- ✅ Products API (CRUD) opdateringer
- ✅ Manuel data-opdatering via import værktøjer
- ✅ Automatisk opdatering af vare master data

**Vigtigt:** Denne procedure opdaterer BC_UPDATEDATE via VARER_BC_CHANGES trigger - kun hvis felter faktisk ændres!

---

## 📞 Call Chain - Hvem Kalder P_UPDATEITEMS?

### 1. P_CREATEUPDATEITEMS (Primær Orchestrator)

**Formål:** Håndterer både oprettelse og opdatering af varer baseret på TYPE_ felt.

**Call Pattern:**

```sql
-- Scenarie 1: Kun UPDATE
IF (UPPER(:LTYPE_) = 'UPDATE') THEN
BEGIN
    SELECT
        P_UPDATEITEMS.O_SUCCES,
        P_UPDATEITEMS.O_MESSAGE
    FROM P_UPDATEITEMS(:I_UUID, :LID)
    INTO :O_SUCCESS, :O_MESSAGE;
END
```

```sql
-- Scenarie 2: CREATEUPDATE (opdater først, opret derefter)
ELSE IF (UPPER(:LTYPE_) = 'CREATEUPDATE') THEN
BEGIN
    -- Først: Forsøg at opdatere eksisterende
    SELECT
        P_UPDATEITEMS.O_SUCCES,
        P_UPDATEITEMS.O_MESSAGE
    FROM P_UPDATEITEMS(:I_UUID, :LID)
    INTO :O_SUCCESS, :O_MESSAGE;
    
    -- Derefter: Opret hvad der ikke kunne opdateres
    SELECT
        P_CREATEITEMS.O_SUCCES,
        P_CREATEITEMS.O_MESSAGE
    FROM P_CREATEITEMS(:I_UUID, :LID, :O_MESSAGE)
    INTO :O_SUCCESS, :O_MESSAGE;
END
```

**Input til P_UPDATEITEMS:**
- `:I_UUID` - UUID fra CREATEUPDATE_ITEM record
- `:LID` - Master ID fra batch job

---

### 2. P_UPDATEDEPARTMENTVARIANT

**Formål:** Opdaterer variant information på tværs af afdelinger.

**Call Pattern:**
```sql
SELECT
    P_UPDATEITEMS.O_SUCCES,
    P_UPDATEITEMS.O_MESSAGE
FROM P_UPDATEITEMS(:UUID_VAR, :MASTER_ID_VAR)
INTO :SUCCESS_VAR, :MESSAGE_VAR;
```

---

## 🔄 Complete Call Flow

```
┌─────────────────────────────────────────┐
│  External System (WebOrder, Import)    │
└─────────────────┬───────────────────────┘
                  │
                  │ Indsætter records i
                  ▼
┌─────────────────────────────────────────┐
│  CREATEUPDATE_ITEM tabel                │
│  - UUID (unik identifier)               │
│  - TYPE_ ('CREATE','UPDATE','CREATEUPD')│
│  - Vare data felter                     │
└─────────────────┬───────────────────────┘
                  │
                  │ Trigger af batch job
                  ▼
┌─────────────────────────────────────────┐
│  P_CREATEUPDATEITEMS                    │
│  (Orchestrator)                         │
└─────────────────┬───────────────────────┘
                  │
         ┌────────┴────────┐
         │                 │
         ▼                 ▼
┌──────────────┐   ┌──────────────┐
│ TYPE_=UPDATE │   │ TYPE_=       │
│              │   │ CREATEUPDATE │
└──────┬───────┘   └──────┬───────┘
       │                  │
       │                  │ 1. Først UPDATE
       │                  ├──────────┐
       │                  │          │
       ▼                  ▼          │
┌─────────────────────────────────┐ │
│  P_UPDATEITEMS                  │ │
│  - Finder vare via barcode/EAN  │◄┘
│  - Opdaterer VARER felter       │
│  - BC_UPDATEDATE via triggers   │
│  - Returnerer success/error     │
└─────────────────┬───────────────┘
                  │
                  │ Hvis TYPE_=CREATEUPDATE
                  │ og vare ikke fundet:
                  ▼
         ┌─────────────────┐
         │  P_CREATEITEMS  │
         │  - Opretter vare│
         └─────────────────┘
```

---

## 📊 Input Data (CREATEUPDATE_ITEM Tabel)

P_UPDATEITEMS læser fra CREATEUPDATE_ITEM tabel:

| Felt | Type | Formål |
|---|---|---|
| UUID | VARCHAR | Unik identifier for denne record |
| MASTER_ID | INTEGER | Batch job ID |
| TYPE_ | VARCHAR | 'UPDATE' eller 'CREATEUPDATE' |
| BARCODE | VARCHAR | Stregkode til at finde vare |
| EANNUMBER | VARCHAR | EAN nummer til at finde vare |
| DESCRIPTION | VARCHAR | Ny varebeskrivelse |
| DESCRIPTION2 | VARCHAR | Beskrivelse 2 |
| DESCRIPTION3 | VARCHAR | Beskrivelse 3 |
| CATEGORY1 | VARCHAR | Kategori 1 (landekode) |
| CATEGORY2 | VARCHAR | Kategori 2 (vægt) |
| ... | ... | Mange flere felter |

---

## 🔧 Hvad Opdaterer P_UPDATEITEMS?

### VARER Tabel (Hovedvare)

```sql
UPDATE VARER SET
    VARER.BC_UPDATEDATE = 'NOW',      -- ALTID opdateret!
    VARER.VARENAVN1 = :LDESCRIPTION,
    VARER.VARENAVN2 = :LDESCRIPTION2,
    VARER.VARENAVN3 = :LDESCRIPTION3,
    VARER.KATEGORI1 = :LCATEGORY1,
    VARER.KATEGORI2 = :LCATEGORY2,
    VARER.KATEGORI3 = :LCATEGORY3,
    VARER.KATEGORI4 = :LCATEGORY4,
    VARER.KATEGORI5 = :LCATEGORY5,
    VARER.VARETEKSTER = :LLONGDESCRIPTION,
    VARER.SERVICEYDELSE = :LSERVICE,
    VARER.ETIKETANTAL = :LLABELQUANTITY,
    VARER.WEBVARER = :LWEBITEM,
    VARER.SPERRET = :LSPERRET,
    VARER.INTRASTAT = :LTARRIF_INTRASTAT,
    VARER.SEASON = :LSEASON,
    VARER.GENDER = :LGENDER,
    VARER.WEIGHT = :LWEIGHT,
    VARER.COUNTRY_OF_ORIGION = :LCOUNTRYOFORIGION,
    VARER.QUALITY = :LQUALITY
WHERE VARER.PLU_NR = :ITEMPLU_NR;
```

**Vigtigt:** `BC_UPDATEDATE = 'NOW'` sættes ALTID - også hvis ingen andre felter ændres!

---

## 🎯 Find Vare Logik

P_UPDATEITEMS kan finde vare på 3 måder:

### 1. Via Article (Varenummer)
```sql
SELECT PLU_NR, MODEL, LEVERID, VAREGRPID
FROM VARER
WHERE VARER.PLU_NR = :LARTICLE
INTO :ITEMPLU_NR, :ITEMMODEL, :ITEMLEVERID, :ITEMVAREGRPID;
```

### 2. Via Brand + Itemgroup + Model
```sql
SELECT PLU_NR, MODEL, LEVERID, VAREGRPID
FROM VARER
WHERE 
    VARER.LEVERID = :LBRAND AND
    VARER.VAREGRPID = :LITEMGROUP AND
    VARER.MODEL = :LMODEL
INTO :ITEMPLU_NR, :ITEMMODEL, :ITEMLEVERID, :ITEMVAREGRPID;
```

### 3. Via Barcode eller EAN Number
```sql
SELECT VARER.PLU_NR, VARER.MODEL, VARER.LEVERID, VARER.VAREGRPID
FROM VARER
    INNER JOIN VAREFRVSTR ON VAREFRVSTR.VAREPLU_ID = VARER.PLU_NR
        AND (VAREFRVSTR.V509INDEX = :LBARCODE OR 
             VAREFRVSTR.EANNUMMER = :LEANNUMBER)
INTO :ITEMPLU_NR, :ITEMMODEL, :ITEMLEVERID, :ITEMVAREGRPID;
```

**Prioritet:**
1. Artikel (hvis angivet)
2. Brand+Itemgroup+Model (hvis angivet)
3. Barcode/EAN (hvis angivet)

---

## ✅ Success/Error Codes

| O_SUCCES | Betydning |
|---|---|
| 0 | Success - vare opdateret |
| 1 | Vare ikke fundet (kan oprettes af P_CREATEITEMS) |
| 255 | Fejl i opdatering |
| 254 | UUID ikke fundet eller ugyldig |

---

## 🔍 Eksempel på Kald

### Fra P_CREATEUPDATEITEMS

```sql
-- Input parametre fra CREATEUPDATE_ITEM tabel
DECLARE VARIABLE I_UUID VARCHAR = 'f47ac10b-58cc-4372-a567-0e02b2c3d479';
DECLARE VARIABLE LID INTEGER = 12345;

-- Output parametre
DECLARE VARIABLE O_SUCCESS INTEGER;
DECLARE VARIABLE O_MESSAGE VARCHAR;

-- Kald
SELECT
    P_UPDATEITEMS.O_SUCCES,
    P_UPDATEITEMS.O_MESSAGE
FROM P_UPDATEITEMS(:I_UUID, :LID)
INTO :O_SUCCESS, :O_MESSAGE;

-- Check resultat
IF (:O_SUCCESS = 0) THEN
    -- Success
ELSE
    -- Fejl eller vare ikke fundet
```

---

## 📝 Logging og Tracing

P_UPDATEITEMS logger til:

### CREATEUPDATE_ITEMS Tabel
```sql
UPDATE CREATEUPDATE_ITEMS SET
    CREATEUPDATE_ITEMS.ACTION_ = :LACTION_,          -- Hvad blev gjort
    CREATEUPDATE_ITEMS.HANDLED = :LHANDLED           -- Status (1=opdateret)
WHERE CREATEUPDATE_ITEMS.ID = :LID;
```

**HANDLED værdier:**
- `1` = Head item opdateret
- `10` = Variant opdateret
- `11` = Både head item og variant opdateret

---

## ⚠️ Vigtige Noter

### BC_UPDATEDATE Påvirkning

**VIGTIGT:** P_UPDATEITEMS sætter IKKE direkte BC_UPDATEDATE.

I stedet opdateres BC_UPDATEDATE **via VARER_BC_CHANGES trigger**, som kun aktiveres når relevante felter faktisk ændres.

Dette betyder:
- ✅ Varen vil kun blive synkroniseret til BC hvis faktiske vare-felter ændres
- ✅ Kun ændringer i de 17 overvågede felter trigger BC_UPDATEDATE
- ⚡ Intelligent og effektiv synkronisering - undgår "tomme" opdateringer

### Error Handling

P_UPDATEITEMS har robuste try/except blokke:
```sql
BEGIN
    -- Update logic
EXCEPTION
    WHEN ANY DO
    BEGIN
        :O_SUCCESS = 255;
        :O_MESSAGE = 'Error: ' || SQLSTATE || ' - ' || GDSCODE;
    END
END
```

### Performance

- Bruger indices på PLU_NR, V509INDEX, EANNUMMER
- Optimeret til batch processing
- Kan håndtere tusindvis af records

---

## 🔗 Relaterede Procedures

| Procedure | Relation | Formål |
|---|---|---|
| P_CREATEUPDATEITEMS | Kalder P_UPDATEITEMS | Orchestrator for batch jobs |
| P_CREATEITEMS | Søster-procedure | Opretter nye varer |
| P_UPDATEDEPARTMENTVARIANT | Kalder P_UPDATEITEMS | Variant opdateringer |
| P_CREATEUPDATE_ITEMS_START | Initialiserer | Starter batch job |
| P_CREATEUPDATE_ITEMS_STOP | Afslutter | Slutter batch job |

---

## 📊 Typisk Use Case Flow

### WebOrder Import

```
1. WebOrder system modtager nye vare-opdateringer
   ↓
2. Data indsættes i CREATEUPDATE_ITEM med TYPE_='CREATEUPDATE'
   ↓
3. Batch job starter og kalder P_CREATEUPDATEITEMS
   ↓
4. P_CREATEUPDATEITEMS kalder P_UPDATEITEMS med UUID
   ↓
5. P_UPDATEITEMS finder vare via EAN/barcode
   ↓
6. VARER opdateres med nye data
   ↓
7. BC_UPDATEDATE sættes til NOW
   ↓
8. Vare markeres som HANDLED=1
   ↓
9. Hvis vare ikke fundet: P_CREATEITEMS kaldes
   ↓
10. EP_TO_BC synkroniserer vare til Business Central
```

---

## 🛠️ Debug Tips

### Check om procedure blev kaldt
```sql
SELECT * FROM CREATEUPDATE_ITEMS
WHERE HANDLED > 0
ORDER BY ID DESC;
```

### Find fejlede opdateringer
```sql
SELECT * FROM CREATEUPDATE_ITEMS
WHERE HANDLED = 0
  AND BATCH_STATUS = 255;
```

### Trace BC_UPDATEDATE opdateringer
```sql
SELECT PLU_NR, VARENAVN1, BC_UPDATEDATE
FROM VARER
WHERE BC_UPDATEDATE > DATEADD(-1 HOUR TO CURRENT_TIMESTAMP)
ORDER BY BC_UPDATEDATE DESC;
```

---

## 📚 Se Også

- [BC_UPDATEDATE_Complete_Analysis.md](BC_UPDATEDATE_Complete_Analysis.md) - Database analyse
- [BC_UPDATEDATE_Application_Overview.md](../BC_UPDATEDATE_Application_Overview.md) - Bruger guide
- CREATEUPDATE_ITEM tabel struktur
- P_CREATEITEMS procedure dokumentation

---

**Dokumenteret:** 2025-12-09  
**Database:** Kaufmann OCCEASYPOS  
**Procedure:** P_UPDATEITEMS  
**Kaldet af:** P_CREATEUPDATEITEMS, P_UPDATEDEPARTMENTVARIANT
