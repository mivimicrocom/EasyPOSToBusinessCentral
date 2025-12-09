# P_UPDATEITEMS - BC_UPDATEDATE Ændring

**Dato:** 2025-12-09  
**Type:** Database stored procedure ændring  
**Impact:** Høj - Påvirker Products API (CRUD) adfærd

---

## Ændring

### Gammel Kode (før 09-12-2025)

```sql
/*Lets update fields we can on head item*/
:LSQLSTRING = 'UPDATE VARER SET ';
:LSQLSTRING = :LSQLSTRING || '  VARER.BC_UPDATEDATE = ''NOW'' ';  -- DIREKTE OPDATERING
IF (NOT(:LDESCRIPTION IS NULL)) THEN
  :LSQLSTRING = :LSQLSTRING || '  ,VARER.VARENAVN1 = ''' || :LDESCRIPTION || ''' ';
...
```

**Adfærd:**
- ✅ BC_UPDATEDATE opdateres **ALTID**
- ✅ Selv hvis kun priser sendes
- ⚠️ Kan give "tomme" synkroniseringer til BC

---

### Ny Kode (efter 09-12-2025)

```sql
/*Lets update fields we can on head item*/
:LSQLSTRING = 'UPDATE VARER SET ';
/*
  This is left out
  If we update this we force an update of this item back to Business Central.
  This is not what we want. This is maintained in the database via trigger 
  VAREFRVSTR_BC_CHANGES and VARER_BC_CHANGES
  Instead we will set WEBDato - this will be set via trigger anyway
*/
:LSQLSTRING = :LSQLSTRING || '  VARER.WEBDato = ''NOW'' ';  -- WEBDato i stedet
IF (NOT(:LDESCRIPTION IS NULL)) THEN
  :LSQLSTRING = :LSQLSTRING || '  ,VARER.VARENAVN1 = ''' || :LDESCRIPTION || ''' ';
...
```

**Adfærd:**
- ⚡ BC_UPDATEDATE opdateres **KUN via VARER_BC_CHANGES trigger**
- ✅ Kun faktiske vare-ændringer trigger synkronisering
- ✅ Undgår "tomme" synkroniseringer

---

## Konsekvens

### Flow Med Gammel Kode

```
Products API
    ↓
P_UPDATEITEMS
    ↓
UPDATE VARER SET BC_UPDATEDATE = 'NOW'  ← ALTID!
    ↓
EP_TO_BC synkroniserer (selv hvis ingen ændringer)
```

### Flow Med Ny Kode

```
Products API
    ↓
P_UPDATEITEMS
    ↓
UPDATE VARER SET VARENAVN1 = '...', KATEGORI1 = '...', ...
    ↓
VARER_BC_CHANGES trigger aktiveres (BEFORE UPDATE)
    ↓
IF (VARENAVN1 ændret OR KATEGORI1 ændret OR ...) THEN
    BC_UPDATEDATE = 'NOW'
    ↓
    EP_TO_BC synkroniserer
ELSE
    BC_UPDATEDATE uændret
    ↓
    INGEN synkronisering
```

---

## Eksempel Scenarier

### Scenarie 1: Kun Pris-opdatering

**Request:**
```json
{
    "barcode": "1085840130",
    "prices": [
        { "costprice": 113.36, "departments": ["003"] }
    ]
}
```

**Gammel adfærd:**
- ✅ BC_UPDATEDATE = NOW
- ✅ Vare synkroniseret til BC (selv om kun pris ændres)

**Ny adfærd:**
- ❌ BC_UPDATEDATE forbliver uændret
- ❌ Vare synkroniseres IKKE til BC
- ✅ Korrekt! (priser synkroniseres ikke til BC)

---

### Scenarie 2: Vare-beskrivelse opdatering

**Request:**
```json
{
    "barcode": "1085840130",
    "description": "Ny beskrivelse"
}
```

**Gammel adfærd:**
- ✅ BC_UPDATEDATE = NOW
- ✅ Vare synkroniseret til BC

**Ny adfærd:**
- ✅ VARENAVN1 opdateres
- ✅ VARER_BC_CHANGES trigger detekterer ændring
- ✅ BC_UPDATEDATE = NOW
- ✅ Vare synkroniseret til BC
- ✅ Korrekt!

---

### Scenarie 3: Samme beskrivelse sendes igen

**Request:**
```json
{
    "barcode": "1085840130",
    "description": "Eksisterende beskrivelse"
}
```

**Gammel adfærd:**
- ✅ BC_UPDATEDATE = NOW
- ⚠️ Vare synkroniseret til BC (selv om ingen ændring)

**Ny adfærd:**
- ✅ VARENAVN1 opdateres (til samme værdi)
- ❌ VARER_BC_CHANGES trigger: VARENAVN1 ikke ændret
- ❌ BC_UPDATEDATE forbliver uændret
- ❌ Vare synkroniseres IKKE til BC
- ✅ Effektivt! (ingen unødvendig synkronisering)

---

## VARER_BC_CHANGES Trigger

Trigger'en tjekker følgende felter:

```sql
IF ((NEW.VARENAVN1 <> OLD.VARENAVN1) OR
    (NEW.VARENAVN2 <> OLD.VARENAVN2) OR
    (NEW.VARENAVN3 <> OLD.VARENAVN3) OR
    (NEW.KATEGORI1 <> OLD.KATEGORI1) OR
    (NEW.KATEGORI2 <> OLD.KATEGORI2) OR
    (NEW.KATEGORI3 <> OLD.KATEGORI3) OR
    (NEW.KATEGORI4 <> OLD.KATEGORI4) OR
    (NEW.KATEGORI5 <> OLD.KATEGORI5) OR
    (NEW.VARETEKSTER <> OLD.VARETEKSTER) OR
    (NEW.SERVICEYDELSE <> OLD.SERVICEYDELSE) OR
    (NEW.ETIKETANTAL <> OLD.ETIKETANTAL) OR
    (NEW.WEBVARER <> OLD.WEBVARER) OR
    (NEW.SPERRET <> OLD.SPERRET) OR
    (NEW.INTRASTAT <> OLD.INTRASTAT) OR
    (NEW.SEASON <> OLD.SEASON) OR
    (NEW.GENDER <> OLD.GENDER) OR
    (NEW.WEIGHT <> OLD.WEIGHT) OR
    (NEW.COUNTRY_OF_ORIGION <> OLD.COUNTRY_OF_ORIGION) OR
    (NEW.QUALITY <> OLD.QUALITY)) THEN
BEGIN
  NEW.BC_UPDATEDATE = 'NOW';
END
```

---

## Fordele Ved Ny Løsning

✅ **Intelligent synkronisering**
- Kun faktiske ændringer trigger BC synkronisering
- Undgår unødvendig netværkstrafik
- Reducerer load på Business Central

✅ **Korrekt pris-håndtering**
- Priser opdaterer ikke BC_UPDATEDATE
- Priser synkroniseres ikke til BC (som forventet)
- Priser hentes fra BC → EasyPOS (korrekt flow)

✅ **Konsistent trigger-baseret logik**
- Manuel redigering i EasyPOSKontor → Trigger
- Products API (CRUD) → Trigger
- Samme logik begge steder

✅ **Performance forbedring**
- Færre BC API kald
- Mindre database aktivitet
- Hurtigere EP_TO_BC kørsel

---

## Migration

**Database:**
- ✅ Trigger VARER_BC_CHANGES allerede installeret (via EPOpdat12.pas)
- ✅ Trigger VAREFRVSTR_BC_CHANGES allerede installeret
- ✅ Ingen database migration nødvendig

**Kode:**
- ✅ Opdater P_UPDATEITEMS stored procedure
- ✅ Opdater dokumentation

**Test:**
1. Send kun pris-opdatering → Tjek BC_UPDATEDATE forbliver uændret
2. Send vare-beskrivelse → Tjek BC_UPDATEDATE opdateres
3. Send samme beskrivelse to gange → Tjek kun første gang opdaterer BC_UPDATEDATE

---

## Dokumentation Opdateret

- ✅ BC_UPDATEDATE_Application_Overview.md
- ✅ Projekt_Analyse.md
- ✅ Sync_Overview.md

**Nøgle ændringer:**
- "Products API sætter ALTID BC_UPDATEDATE" → "Products API KAN trigger BC_UPDATEDATE via triggers"
- "Selv hvis kun priser sendes" → "Kun hvis vare-felter ændres"
- Tilføjet forklaring på smart trigger-baseret opdatering

---

## Se Også

- [BC_UPDATEDATE_Application_Overview.md](../BC_UPDATEDATE_Application_Overview.md)
- [Database_Triggers.md](Database_Triggers.md)
- [VARER_BC_CHANGES.sql](VARER_BC_CHANGES.sql)
