# BC_UPDATEDATE Audit Logging - Simple Implementation

**Formål:** Log ALLE ændringer til BC_UPDATEDATE feltet i WEB_SLADREHANK

**Dato:** 18. december 2025  
**Version:** 1.0 - Simpel version

---

## 📋 Krav

Når BC_UPDATEDATE ændres på VARER tabellen, log:

| Felt | Værdi |
|------|-------|
| HVAD | "BC UpdateDate changed" |
| HVEM | Nuværende bruger (CURRENT_USER) |
| HVOR | Program/forbindelse (hvis muligt) |
| DATO_STEMPEL | NOW (automatisk) |
| SQLSETNING | Engelsk besked med PLU_NR og tidsstempler |

---

## 📝 SQLSETNING Format

```
User [USERNAME]
at [TIMESTAMP]
from connection [APPLICATION]
changed BC_UPDATEDATE on item [PLU_NR]
from [OLD_VALUE]
to [NEW_VALUE]
```

**Eksempel:**
```
User SYSDBA
at 2025-12-18 15:30:45
from connection IBExpert.exe
changed BC_UPDATEDATE on item 12345
from 2025-12-17 10:00:00
to 2025-12-18 15:30:45
```

---

## 🔧 Implementation - 1 Trigger

Vi skal kun lave **ÉN trigger** på VARER tabellen.

### VARER_BC_UPDATEDATE_LOG

**Type:** AFTER UPDATE  
**Position:** 31 (efter VARER_BC_CHANGES på position 30)

```sql
CREATE OR ALTER TRIGGER VARER_BC_UPDATEDATE_LOG FOR VARER
ACTIVE AFTER UPDATE POSITION 31
AS
DECLARE VARIABLE L_APP_NAME VARCHAR(50);
DECLARE VARIABLE L_AUDIT_MSG VARCHAR(8000);
BEGIN
  /* Only log if BC_UPDATEDATE actually changed */
  IF (OLD.BC_UPDATEDATE IS DISTINCT FROM NEW.BC_UPDATEDATE) THEN
  BEGIN
    
    /* Try to get application name from monitoring */
    /* MON$REMOTE_PROCESS can be up to 255 chars, but HVOR is only 50 */
    SELECT FIRST 1 RIGHT(MON$REMOTE_PROCESS, 50)
    FROM MON$ATTACHMENTS 
    WHERE MON$ATTACHMENT_ID = CURRENT_CONNECTION
    INTO :L_APP_NAME;
    
    /* Default to 'Unknown' if not found */
    IF (L_APP_NAME IS NULL) THEN
      L_APP_NAME = 'Unknown';
    
    /* Build audit message */
    /* Use ASCII_CHAR for Firebird 3 Dialect 1 compatibility */
    L_AUDIT_MSG = 
        'User ' || CURRENT_USER || 
        ' at ' || CAST(CURRENT_TIMESTAMP AS VARCHAR(30)) || ASCII_CHAR(13) || ASCII_CHAR(10) ||
        'from connection ' || L_APP_NAME || ASCII_CHAR(13) || ASCII_CHAR(10) ||
        'changed BC_UPDATEDATE on item ' || NEW.PLU_NR || ASCII_CHAR(13) || ASCII_CHAR(10) ||
        'from ' || CAST(OLD.BC_UPDATEDATE AS VARCHAR(30)) || ASCII_CHAR(13) || ASCII_CHAR(10) ||
        'to ' || CAST(NEW.BC_UPDATEDATE AS VARCHAR(30));
    
    /* Insert audit record - ID sættes automatisk */
    INSERT INTO WEB_SLADREHANK (
        HVAD,
        HVEM,
        HVOR,
        SQLSETNING
    ) VALUES (
        'BC UpdateDate changed',
        CURRENT_USER,
        :L_APP_NAME,
        :L_AUDIT_MSG
    );
  END
END^
```

---

## ✅ Det Er Det!

Denne ene trigger fanger:

✅ **Direkte opdateringer** af BC_UPDATEDATE  
✅ **Indirekte opdateringer** via VARER_BC_CHANGES trigger (når VARENAVN1, MODEL, etc. ændres)  
✅ **Variant-forårsagede opdateringer** fra VAREFRVSTR_BC_CHANGES trigger  
✅ **Ny variant** fra INS_VAREFRVSTR trigger  

**Hvorfor?** Fordi alle disse ændringer opdaterer VARER.BC_UPDATEDATE, og vores trigger aktiveres på VARER AFTER UPDATE.

---

## 🧪 Test

### 1. Opret Trigger

```sql
-- Kør trigger koden ovenfor
```

### 2. Test Direkte Opdatering

```sql
UPDATE VARER 
SET VARENAVN1 = 'Test'
WHERE PLU_NR = '12345';
```

### 3. Check Log

```sql
SELECT * FROM WEB_SLADREHANK
WHERE HVAD = 'BC UpdateDate changed'
ORDER BY DATO_STEMPEL DESC
FETCH FIRST 1 ROW ONLY;
```

**Forventet resultat:**
```
HVAD: BC UpdateDate changed
HVEM: SYSDBA
HVOR: IBExpert.exe
DATO_STEMPEL: 2025-12-18 15:30:45
SQLSETNING: User SYSDBA
at 2025-12-18 15:30:45
from connection IBExpert.exe
changed BC_UPDATEDATE on item 12345
from 2025-12-17 10:00:00
to 2025-12-18 15:30:45
```

---

## 📊 Eksempel Queries

### Se seneste ændringer

```sql
SELECT 
    HVEM,
    HVOR,
    DATO_STEMPEL,
    SQLSETNING
FROM WEB_SLADREHANK
WHERE HVAD = 'BC UpdateDate changed'
ORDER BY DATO_STEMPEL DESC
FETCH FIRST 20 ROWS ONLY;
```

### Find ændringer for specifik vare

```sql
SELECT * FROM WEB_SLADREHANK
WHERE HVAD = 'BC UpdateDate changed'
  AND SQLSETNING CONTAINING 'item 12345'
ORDER BY DATO_STEMPEL DESC;
```

### Antal ændringer per dag

```sql
SELECT 
    CAST(DATO_STEMPEL AS DATE) AS DATO,
    COUNT(*) AS ANTAL_AENDRINGER
FROM WEB_SLADREHANK
WHERE HVAD = 'BC UpdateDate changed'
GROUP BY CAST(DATO_STEMPEL AS DATE)
ORDER BY DATO DESC;
```

### Hvem ændrer mest?

```sql
SELECT 
    HVEM,
    COUNT(*) AS ANTAL,
    MAX(DATO_STEMPEL) AS SENESTE
FROM WEB_SLADREHANK
WHERE HVAD = 'BC UpdateDate changed'
  AND DATO_STEMPEL >= DATEADD(-7 DAY TO CURRENT_TIMESTAMP)
GROUP BY HVEM
ORDER BY ANTAL DESC;
```

---

## 🧹 Oprydning

### Slet gamle logs (ældre end 90 dage)

```sql
DELETE FROM WEB_SLADREHANK
WHERE HVAD = 'BC UpdateDate changed'
  AND DATO_STEMPEL < DATEADD(-90 DAY TO CURRENT_TIMESTAMP);
```

---

## ⚠️ Bemærk

### HVOR Feltet

Hvis `MON$REMOTE_PROCESS` ikke kan læses (permissions), vil HVOR altid være "Unknown".

**Løsning hvis det er et problem:**

```sql
-- Giv alle adgang til monitoring tabeller
GRANT SELECT ON MON$ATTACHMENTS TO PUBLIC;
```

### Performance

- Minimal overhead (kun når BC_UPDATEDATE faktisk ændres)
- AFTER UPDATE trigger holder ikke locks
- Forventet ca. 50-270 log entries per dag

---

## 📁 Filer

| Fil | Beskrivelse |
|-----|-------------|
| `README.md` | Denne fil - alt du behøver |
| `TRIGGER.sql` | Komplet trigger kode (se næste fil) |

---

**Komplet og simpel! Én trigger, intet bøvl.**
