# BC_UPDATEDATE Felt Analyse

## Database Forbindelse

**Database:** 10.8.20.11/3070:f:\Data\FB30\Kaufmann\OCCEASYPOS.FDB  
**Analyseret:** 2025-12-09

---

## Felt Definition

**Tabel:** VARER  
**Felt:** BC_UPDATEDATE  
**Default værdi:** `'NOW'`

Dette felt får automatisk værdien `CURRENT_TIMESTAMP` når en ny record oprettes.

---

## Trigger der Vedligeholder BC_UPDATEDATE

### ✅ VARER_BC_CHANGES (BEFORE UPDATE)

**Type:** BEFORE UPDATE (Type 3)  
**Formål:** Opdaterer BC_UPDATEDATE når specifikke felter ændres

**Kode:**
```sql
BEGIN
  /*This trigger is made to Kaufmann*/
  /*It can maybe be used to future Business central integrations*/
  
  IF ((OLD.PLU_NR <> NEW.PLU_NR) OR
      (OLD.VARENAVN1 <> NEW.VARENAVN1) OR
      (OLD.VARENAVN2 <> NEW.VARENAVN2) OR
      (OLD.VARENAVN3 <> NEW.VARENAVN3) OR
      (OLD.MODEL <> NEW.MODEL) OR
      (OLD.WEBVARER <> NEW.WEBVARER) OR
      (OLD.LEVERID <> NEW.LEVERID) OR
      (OLD.VAREGRPID <> NEW.VAREGRPID) OR
      (OLD.KATEGORI1 <> NEW.KATEGORI1) OR
      (OLD.KATEGORI2 <> NEW.KATEGORI2) OR
      (OLD.ALT_VARE_NR <> NEW.ALT_VARE_NR) OR
      (OLD.INTRASTAT <> NEW.INTRASTAT)) THEN
  BEGIN
    NEW.BC_UPDATEDATE = 'NOW';
  END
END
```

**Overvågede Felter:**
1. ✅ PLU_NR - Varenummer (primær nøgle)
2. ✅ VARENAVN1 - Varenavn
3. ✅ VARENAVN2 - Varenavn 2
4. ✅ VARENAVN3 - Varenavn 3
5. ✅ MODEL - Model
6. ✅ WEBVARER - Web vare markering
7. ✅ LEVERID - Leverandør ID
8. ✅ VAREGRPID - Varegruppe ID
9. ✅ KATEGORI1 - Kategori 1 (landekode)
10. ✅ KATEGORI2 - Kategori 2 (vægt)
11. ✅ ALT_VARE_NR - Alternativt varenummer
12. ✅ INTRASTAT - IntraStat nummer

**Note fra koden:** "This trigger is made to Kaufmann. It can maybe be used to future Business central integrations"

---

## Sammenhæng med Synkronisering

### DoSyncronizeItems Query

**Fra dokumentation (Sync_1_Items.md):**

```sql
SELECT DISTINCT
    VARER.plu_nr AS VAREID,
    VARER.bc_updatedate,
    ...
FROM VARER
    INNER JOIN VAREFRVSTR ON (VAREFRVSTR.VAREPLU_ID = VARER.plu_nr)
    ...
WHERE
    VARER.bc_updatedate >= :PStartDato 
    AND VARER.bc_updatedate <= :PSlutDato
ORDER BY
    VARER.plu_nr,
    VAREFRVSTR.v509index
```

**Flow:**
1. Bruger ændrer en af de 12 overvågede felter i EasyPOS
2. Trigger `VARER_BC_CHANGES` opdaterer `BC_UPDATEDATE = NOW`
3. Næste gang synkroniseringen kører:
   - Varen fanges af `WHERE VARER.bc_updatedate >= Last run`
   - Varen + alle varianter synkroniseres til Business Central
   - Varen markeres som `EKSPORTERET = EKSPORTERET + 1`

---

## Ikke-overvågede Felter

**Følgende felter trigger IKKE synkronisering:**

- Priser (håndteres af kostpris-synk den anden vej!)
- Lagerbeholdning
- Antal detaljer
- Web-specifikke felter (WEBOPDAT, WEBDATO)
- Kategorier 3, 4, 5
- Alle andre felter

**Rationale:** Kun master data der er relevante for BC synkroniseres.

---

## Andre Relevante Triggers på VARER

### VARER_AD50 (AFTER DELETE)
- Logger sletninger i `DATABASE_CHANGES` tabel

### VARER_BU0 (BEFORE UPDATE)
- Kaskaderer ændringer af LEVERID og VAREGRPID til relaterede tabeller

### VARER_MODEL (AFTER UPDATE)
- Opdaterer MODEL på varianter når hovedvare ændres

### VARER_WEB (BEFORE UPDATE)
- Håndterer WEBVARER og WEBOPDAT felter
- Sætter WEBDATO ved ændringer

### VARER_GOFACT (AFTER UPDATE)
- Opdaterer TRIGGERDATO på varianter når kategorier ændres

---

## Anbefalinger

### For Udvikling

1. **Hvis nye felter skal synkroniseres:**
   - Tilføj til `VARER_BC_CHANGES` trigger
   - Opdater mapping i synkroniseringskode
   - Test grundigt

2. **Ved debugging:**
   - Check `BC_UPDATEDATE` værdi på problemvarer
   - Verificer at trigger er aktiv: `SELECT RDB$TRIGGER_INACTIVE FROM RDB$TRIGGERS WHERE RDB$TRIGGER_NAME = 'VARER_BC_CHANGES'`

3. **Manuel trigger af synk:**
   ```sql
   UPDATE VARER 
   SET BC_UPDATEDATE = 'NOW' 
   WHERE PLU_NR = '12345';
   ```

### For Fejlfinding

**Hvis vare ikke synkroniseres:**

1. Check BC_UPDATEDATE:
   ```sql
   SELECT PLU_NR, BC_UPDATEDATE, VARENAVN1 
   FROM VARER 
   WHERE PLU_NR = '12345';
   ```

2. Check Last run i INI fil:
   ```ini
   [Items]
   Last run=45000.5  ; Er denne EFTER BC_UPDATEDATE?
   ```

3. Force re-sync:
   ```sql
   UPDATE VARER SET BC_UPDATEDATE = 'NOW' WHERE PLU_NR = '12345';
   ```

---

## Konklusion

✅ **BC_UPDATEDATE vedligeholdes automatisk** via trigger `VARER_BC_CHANGES`

✅ **Trigger er veldesignet** og overvåger alle relevante master data felter

✅ **Default værdi sikrer** at nye varer altid får en gyldig timestamp

⚠️ **Trigger er Kaufmann-specifik** - andre kunder har måske ikke denne

📝 **Dokumentation manglede** denne vigtige detalje - nu opdateret!

---

## Se Også

- [Sync_1_Items.md](Sync_1_Items.md) - Vare synkronisering dokumentation
- [Projekt_Analyse.md](Projekt_Analyse.md) - Generel projekt oversigt
- Database schema dokumentation (hvis tilgængelig)

---

**Analyseret:** 2025-12-09  
**Database:** Kaufmann OCCEASYPOS  
**Trigger:** VARER_BC_CHANGES (aktiv)
