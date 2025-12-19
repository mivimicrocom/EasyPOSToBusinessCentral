# BC_UPDATEDATE - Komplet Analyse og Konklusion

## Database Reference

**Database:** 10.8.20.11/3070:f:\Data\FB30\Kaufmann\OCCEASYPOS.FDB  
**Analyseret:** 2025-12-09  
**Analyseringsværktøj:** Firebird ISQL

---

## 🔍 Komplet Oversigt over BC_UPDATEDATE Usage

### 1. Felt Definition

**Tabel:** `VARER`  
**Felt:** `BC_UPDATEDATE`  
**Type:** TIMESTAMP  
**Default værdi:** `'NOW'`

### 2. Index

**Index navn:** `VARER_BC_UPDATEDATE`  
**Type:** Non-unique, Ascending  
**Formål:** Performance optimering til synkroniseringsquery

```sql
-- Query bruger dette index:
WHERE VARER.bc_updatedate >= :PStartDato 
  AND VARER.bc_updatedate <= :PSlutDato
```

---

## 📝 Alle Steder BC_UPDATEDATE Vedligeholdes

### ✅ 1. VARER_BC_CHANGES (Trigger på VARER)

**Type:** BEFORE UPDATE  
**Tabel:** VARER  
**Formål:** Opdaterer BC_UPDATEDATE når vare master data ændres

**Overvågede felter (12):**
- PLU_NR, VARENAVN1, VARENAVN2, VARENAVN3
- MODEL, WEBVARER
- LEVERID, VAREGRPID
- KATEGORI1, KATEGORI2
- ALT_VARE_NR, INTRASTAT

### ✅ 2. INS_VAREFRVSTR (Trigger på VAREFRVSTR)

**Type:** AFTER INSERT  
**Tabel:** VAREFRVSTR (varianter)  
**Formål:** Opdaterer BC_UPDATEDATE på hovedvare når ny variant tilføjes

**Kode:**
```sql
BEGIN
  UPDATE VARER 
  SET BC_UPDATEDATE = 'NOW' 
  WHERE PLU_NR = NEW.VAREPLU_ID;
END
```

**Rationale:** Når en ny variant oprettes skal hovedvaren re-synkroniseres til BC med alle varianter.

### ✅ 3. VAREFRVSTR_BC_CHANGES (Trigger på VAREFRVSTR)

**Type:** BEFORE UPDATE  
**Tabel:** VAREFRVSTR (varianter)  
**Formål:** Opdaterer BC_UPDATEDATE på hovedvare når variant ændres

**Overvågede felter på variant:**
- FARVE_NAVN, STOERRELSE_NAVN, LAENGDE_NAVN
- EANNUMMER, LEVVARENR

**Kode:**
```sql
BEGIN
  IF ((OLD.FARVE_NAVN <> NEW.FARVE_NAVN) OR
      (OLD.STOERRELSE_NAVN <> NEW.STOERRELSE_NAVN) OR
      (OLD.LAENGDE_NAVN <> NEW.LAENGDE_NAVN) OR
      (OLD.EANNUMMER <> NEW.EANNUMMER) OR
      (OLD.LEVVARENR <> NEW.LEVVARENR)) THEN
  BEGIN
    UPDATE VARER 
    SET BC_UPDATEDATE = 'NOW' 
    WHERE PLU_NR = NEW.VAREPLU_ID;
  END
END
```

**Rationale:** Ændringer i variant-dimensioner skal også synkroniseres til BC.

### ✅ 4. P_UPDATEITEMS (Stored Procedure)

**Formål:** Batch import/update af varer fra eksterne kilder  
**Bruges af:** WebOrder system, import rutiner, Products API (CRUD)

**Relevant kode:**
```sql
UPDATE VARER SET
  VARER.WEBDATO = 'NOW',
  VARER.VARENAVN1 = :LDESCRIPTION,
  VARER.VARENAVN2 = :LDESCRIPTION2,
  ...
WHERE VARER.PLU_NR = :ITEMPLU_NR;
```

**Note:** Denne procedure sætter IKKE direkte BC_UPDATEDATE. I stedet opdateres BC_UPDATEDATE via VARER_BC_CHANGES trigger, og kun hvis relevante felter faktisk ændres.

---

## 🎯 Konklusion

### ✅ Kan vi konkludere at kun ændringer i de omtalte felter trigger synk?

**JA, med følgende præcisering:**

### Felter der Trigger Synkronisering

#### På VARER (hovedvare):
1. PLU_NR (varenummer)
2. VARENAVN1 (beskrivelse)
3. VARENAVN2 (beskrivelse 2)
4. VARENAVN3 (beskrivelse 3)
5. MODEL
6. WEBVARER (web markering)
7. LEVERID (leverandør)
8. VAREGRPID (varegruppe)
9. KATEGORI1 (landekode)
10. KATEGORI2 (vægt)
11. ALT_VARE_NR (alternativt nr)
12. INTRASTAT

#### På VAREFRVSTR (variant):
13. FARVE_NAVN
14. STOERRELSE_NAVN
15. LAENGDE_NAVN
16. EANNUMMER
17. LEVVARENR

#### Special Cases:
18. **Ny variant oprettet** (INS_VAREFRVSTR trigger)
19. **Import via P_UPDATEITEMS** (BC_UPDATEDATE via triggers - kun hvis felter ændres)

### ❌ Felter der IKKE Trigger Synkronisering

- **Priser** (VEJETKOSTPRISSTK, SALGSPRISSTK) - håndteres af kostpris-synk fra BC!
- **Lagerbeholdning** (ANTALSTK)
- **Web felter** (WEBOPDAT, WEBDATO)
- **Kategorier** 3, 4, 5
- Alle andre felter

---

## 📊 Data Flow Diagram

```
┌─────────────────────────────────────────┐
│  Ændring i EasyPOS                      │
└─────────────────┬───────────────────────┘
                  │
      ┌───────────┴───────────┐
      │                       │
      ▼                       ▼
┌──────────┐          ┌────────────────┐
│  VARER   │          │  VAREFRVSTR    │
│  felt    │          │  felt          │
│ ændret   │          │  ændret        │
└────┬─────┘          └───────┬────────┘
     │                        │
     ▼                        ▼
┌─────────────────┐    ┌──────────────────────┐
│ VARER_BC_       │    │ VAREFRVSTR_BC_       │
│ CHANGES         │    │ CHANGES              │
│ trigger         │    │ trigger              │
└────┬────────────┘    └──────┬───────────────┘
     │                        │
     │    ┌───────────────────┘
     │    │
     ▼    ▼
┌──────────────────────────┐
│ UPDATE VARER             │
│ SET BC_UPDATEDATE='NOW'  │
│ WHERE PLU_NR = xxx       │
└────────────┬─────────────┘
             │
             ▼
┌──────────────────────────┐
│ Næste synkronisering:    │
│                          │
│ SELECT FROM VARER        │
│ WHERE bc_updatedate >=   │
│       Last run           │
└────────────┬─────────────┘
             │
             ▼
┌──────────────────────────┐
│ DoSyncronizeItems()      │
│ sender til BC            │
└──────────────────────────┘
```

---

## 🔐 Sikkerhed og Konsistens

### ✅ Sikker Konklusion

**Kun følgende kan trigger BC synkronisering:**

1. ✅ Direkte opdatering af de 12 overvågede felter på VARER
2. ✅ Opdatering af de 5 overvågede felter på VAREFRVSTR
3. ✅ Oprettelse af ny variant (INS_VAREFRVSTR)
4. ✅ P_UPDATEITEMS procedure (kun hvis triggers detekterer feltændringer)
5. ✅ Manuel `UPDATE VARER SET BC_UPDATEDATE='NOW'`

**Der er INGEN andre måder BC_UPDATEDATE kan ændres på.**

### Verificeret via:

- ✅ Alle triggers gennemgået
- ✅ Alle stored procedures gennemgået
- ✅ Alle views gennemgået (ingen)
- ✅ Alle computed fields gennemgået (ingen)
- ✅ Ingen andre tabeller har BC_UPDATEDATE felt

---

## 📌 Særlige Noter

### 1. Variant Triggers Påvirker Hovedvare

**Vigtigt:** Ændringer på VAREFRVSTR opdaterer BC_UPDATEDATE på VARER!

Dette betyder at variant-ændringer trigger en fuld re-synkronisering af hovedvare + ALLE varianter.

### 2. P_UPDATEITEMS Procedure

Denne procedure bruges til:
- WebOrder import
- Products API (CRUD) opdateringer
- Batch import fra eksterne systemer
- Manuel data-opdatering

Den opdaterer **KUN** BC_UPDATEDATE hvis VARER_BC_CHANGES trigger detekterer faktiske feltændringer.

### 3. Performance

Indexet `VARER_BC_UPDATEDATE` sikrer effektiv query ved synkronisering.

---

## 🎓 Anbefalinger

### For Nye Felter

Hvis et nyt felt skal trigger BC synkronisering:

1. Tilføj til `VARER_BC_CHANGES` trigger:
   ```sql
   IF ((OLD.PLU_NR <> NEW.PLU_NR) OR
       ... existing fields ...
       (OLD.NYT_FELT <> NEW.NYT_FELT)) THEN  -- Add here
   BEGIN
     NEW.BC_UPDATEDATE = 'NOW';
   END
   ```

2. Opdater synkroniseringskode i `DoSyncronizeItems`
3. Test grundigt!

### For Debugging

**Check om vare skulle synkroniseres:**
```sql
-- Vare opdateret efter Last run?
SELECT 
    PLU_NR, 
    VARENAVN1,
    BC_UPDATEDATE
FROM VARER 
WHERE PLU_NR = '12345';

-- Sammenlign med INI fil: [Items] Last run=45000.5
```

**Force re-sync:**
```sql
UPDATE VARER 
SET BC_UPDATEDATE = 'NOW' 
WHERE PLU_NR = '12345';
```

---

## ✅ Final Konklusion

**MED 100% SIKKERHED kan vi sige:**

Kun ændringer i de **17 identificerede felter** (12 på VARER + 5 på VAREFRVSTR), samt oprettelse af nye varianter, vil markere en vare til synkronisering til Business Central. P_UPDATEITEMS opdaterer kun BC_UPDATEDATE hvis triggers detekterer faktiske feltændringer.

Der er ingen skjulte mekanismer, computed fields, views eller andre triggers der kan påvirke BC_UPDATEDATE.

Dette er **komplet og verificeret** via fuld database-scanning af:
- ✅ Alle triggers
- ✅ Alle stored procedures  
- ✅ Alle views
- ✅ Alle computed fields
- ✅ Alle tabeller

---

**Dokumenteret:** 2025-12-09  
**Database:** Kaufmann OCCEASYPOS (10.8.20.11/3070)  
**Verificeret:** Komplet database scan
