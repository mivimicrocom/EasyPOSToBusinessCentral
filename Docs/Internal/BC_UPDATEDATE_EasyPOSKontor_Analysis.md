# BC_UPDATEDATE Referencer i EasyPOSKontor Projekt

## Analyse Dato
**2025-12-09**

## Projekt Analyseret
**Z:\EasyPOS\EasyPOSKontor**

---

## 🔍 Søgningsresultater

### ✅ FUNDNE REFERENCER - 5 filer

1. `Opdateringer\EPOpdat12.pas` - Database opdatering script
2. `DM\UDMVarer.dfm` - Data module form definition
3. `DM\UDMVarer.pas` - Data module kode
4. `Varer\UVarer.dfm` - Vare form definition
5. `Varer\UVarer.pas` - Vare form kode

---

## 📝 Detaljerede Fund

### 1. EPOpdat12.pas - Database Opdatering (Installation)

**Formål:** Opretter BC_UPDATEDATE felt og triggers under system opdatering

#### Sektion 1: Opret BC_UPDATEDATE felt (linje 33144)
```sql
ALTER TABLE VARER
    ADD BC_UPDATEDATE DATE DEFAULT 'NOW';
```

#### Sektion 2: Opret index (linje 33159-33160)
```sql
CREATE INDEX VARER_BC_UPDATEDATE
ON VARER (BC_UPDATEDATE);
```

#### Sektion 3: Initialiser felt med eksisterende data (linje 33177)
```sql
UPDATE VARER SET
    VARER.BC_UPDATEDATE = VARER.WEBDATO
```
**Note:** Ved første installation kopieres WEBDATO værdi til BC_UPDATEDATE.

#### Sektion 4: Opret VAREFRVSTR_BC_CHANGES trigger (linje 33207)
```sql
CREATE OR ALTER TRIGGER VAREFRVSTR_BC_CHANGES FOR VAREFRVSTR
ACTIVE BEFORE UPDATE POSITION 0
AS
BEGIN
  /*This trigger is made to Kaufmann*/
  /*It can maybe be used to furture Business central integrations*/
  IF ((NEW.FARVE_NAVN <> OLD.FARVE_NAVN) OR
      (NEW.STOERRELSE_NAVN <> OLD.STOERRELSE_NAVN) OR
      (NEW.LAENGDE_NAVN > OLD.LAENGDE_NAVN) OR
      (NEW.EANNUMMER > OLD.EANNUMMER) OR
      (NEW.V509INDEX > OLD.V509INDEX) OR
      (NEW.LEVVARENR <> OLD.LEVVARENR)) THEN
  BEGIN
    UPDATE VARER SET
        VARER.BC_UPDATEDATE = 'NOW'
    WHERE
        VARER.PLU_NR = NEW.VAREPLU_ID;
  END
END
```

#### Sektion 5: Opret VARER_BC_CHANGES trigger (linje 33247)
```sql
CREATE OR ALTER TRIGGER VARER_BC_CHANGES FOR VARER
ACTIVE BEFORE UPDATE POSITION 0
AS
BEGIN
  /*This trigger is made to Kaufmann*/
  /*It can maybe be used to furture Business central integrations*/
  IF ((OLD.PLU_NR <> NEW.PLU_NR) OR
      (OLD.VARENAVN1 <> NEW.VARENAVN1) OR
      (OLD.VARENAVN2 <> NEW.VARENAVN2) OR
      (OLD.VARENAVN3 <> NEW.VARENAVN3) OR
      (OLD.MODEL <> NEW.MODEL) OR
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

#### Sektion 6: Opdater INS_VAREFRVSTR trigger (linje 36014)
```sql
CREATE OR ALTER TRIGGER INS_VAREFRVSTR FOR VAREFRVSTR
ACTIVE AFTER INSERT POSITION 0
AS
BEGIN
  UPDATE VARER SET
      ANTAL_DETALJER = ANTAL_DETALJER + 1,
      VARER.BC_UPDATEDATE = 'NOW'
  WHERE
      VARER.PLU_NR = NEW.VAREPLU_ID;
END
```

**Konklusion:** EPOpdat12.pas installerer hele BC_UPDATEDATE infrastrukturen!

---

### 2. UDMVarer.dfm - Data Module Form (Read-Only)

**Linje 1061:** BC_UPDATEDATE inkluderet i SELECT query
```sql
SELECT
    ...
    VARER.BC_UPDATEDATE
FROM VARER
ORDER BY ...
```

**Linje 1318-1320:** Field definition
```delphi
object QVarerBC_UPDATEDATE: TDateTimeField
  FieldName = 'BC_UPDATEDATE'
  Origin = 'VARER.BC_UPDATEDATE'
  DisplayFormat = 'dd-mm-yyyy hh:mm:ss'
end
```

**Konklusion:** Kun læser feltet - ingen opdateringer.

---

### 3. UDMVarer.pas - Data Module Kode (Read-Only)

**Linje 1230:** Field declaration
```delphi
QVarerBC_UPDATEDATE: TDateTimeField;
```

**Konklusion:** Kun declaration - ingen opdateringer.

---

### 4. UVarer.dfm - Vare Form (Display Only)

**Linje 3209:** Display field på form
```delphi
DataField = 'BC_UPDATEDATE'
DataSource = DMVarer.DSVarer
```

**Konklusion:** Kun viser feltet til brugeren - ingen opdateringer.

---

### 5. UVarer.pas - Vare Form Kode (KRITISK!)

**Linje 23649-23665:** Manuel force synk til BC
```delphi
procedure TfrmVarer.SynkroniservareimodBusinessCentral1Click(Sender: TObject);
var
  GemVareNr: String;
  GemAfd: String;
begin
  GemVareNr := DMVarer.Qvarer.FieldByName('PLU_NR').AsString;
  GemAfd := dblAfd.Text;
  try
    if (not(DMVarer.VarerTrans.Active)) then
      DMVarer.VarerTrans.StartTransAction;
      
    DMVarer.QTemp.SQL.Clear;
    DMVarer.QTemp.SQL.Add('UPDATE VARER SET');
    DMVarer.QTemp.SQL.Add('    VARER.BC_UPDATEDATE = ''NOW''');
    DMVarer.QTemp.SQL.Add('WHERE');
    DMVarer.QTemp.SQL.Add('    VARER.PLU_NR = :PPLU_NR   ');
    DMVarer.QTemp.ParamByName('PPLU_NR').AsString := GemVareNr;
    DMVarer.QTemp.Open;
    DMVarer.VarerTrans.Commit;
  except
    on e: EIBError do
    begin
      StandardProcedure.CallError2('FEJL. Kan ikke sætte vare til overførsel til business central!', 
                                   e.message, '', '', '', '', e.SQLCode, e.IBErrorCode, 
                                   e.HelpContext, TRUE, DMVarer.VarerTrans);
    end;
  end;
  OpdaterVarerMM_(GemVareNr, '', '', '', GemAfd, FALSE, nil);
end;
```

**Funktion:** Menu item "Synkroniser vare imod Business Central"

**Hvad sker der:**
1. Henter aktuelt varenummer
2. Opdaterer `BC_UPDATEDATE = 'NOW'` på varen
3. Refresher vare data
4. Varen vil blive synkroniseret ved næste EP_TO_BC kørsel

**User Interface:** Dette er sandsynligvis en højreklik menu eller knap i vare-vinduet.

---

## 📊 Sammenfatning

### Installation (EPOpdat12.pas)

**Hvornår køres dette?**
- Under system opdatering/upgrade
- Sandsynligvis én gang per installation
- Opretter alle nødvendige database objekter

**Hvad oprettes:**
1. ✅ BC_UPDATEDATE felt med DEFAULT 'NOW'
2. ✅ VARER_BC_UPDATEDATE index
3. ✅ Initial data (kopierer fra WEBDATO)
4. ✅ VARER_BC_CHANGES trigger
5. ✅ VAREFRVSTR_BC_CHANGES trigger
6. ✅ INS_VAREFRVSTR trigger (opdateret)

### Runtime Brug (UVarer.pas)

**Manuel Force Synk:**

Brugeren kan **manuelt** markere en vare til BC synkronisering via:
- Menu: "Synkroniser vare imod Business Central"
- Effekt: Sætter `BC_UPDATEDATE = NOW`
- Resultat: Varen synkroniseres ved næste EP_TO_BC kørsel

---

## 🎯 Konklusion

### ✅ EasyPOSKontor's Rolle i BC_UPDATEDATE

**Installation:**
- ✅ Opretter BC_UPDATEDATE felt
- ✅ Opretter alle 3 triggers (VARER_BC_CHANGES, VAREFRVSTR_BC_CHANGES, INS_VAREFRVSTR)
- ✅ Opretter index

**Runtime:**
- ✅ Viser BC_UPDATEDATE til bruger
- ✅ Tillader manuel force-synk via menu
- ❌ Opdaterer IKKE automatisk ved normal vare-redigering

### Automatisk vs Manuel Opdatering

**Automatisk (via triggers):**
Når bruger ændrer vare-felter i EasyPOSKontor, opdateres BC_UPDATEDATE **automatisk** via de triggers som EPOpdat12.pas har oprettet.

**Manuel (via menu):**
Bruger kan **force** en vare til synkronisering ved at vælge menu item:
"Synkroniser vare imod Business Central"

---

## 🔍 Vigtig Opdagelse

### Database Trigger Installation

**EasyPOSKontor er den applikation der INSTALLER triggerne!**

Dette forklarer hvorfor vi fandt triggerne i databasen - de blev ikke oprettet manuelt, men via EPOpdat12.pas opdaterings-script.

**Opdateringsnummer:** Denne opdatering ser ud til at være omkring version 8.03 eller senere (baseret på DMOpdat803 reference).

### Version Historia

Fra koden kan vi se:
```delphi
// Label3.Caption := 'Business Central Integration 1';
// Label3.Caption := 'Business Central Integration 2';
// Label3.Caption := 'Business Central Integration 3';
// Label3.Caption := 'Business Central Integration 4';
```

BC_UPDATEDATE infrastrukturen blev tilføjet i 4 separate opdaterings-trin.

---

## 📌 Praktiske Implikationer

### For Support

**Hvis BC_UPDATEDATE mangler eller triggers er væk:**

Dette kan ske hvis:
1. Database er ikke opdateret til version 8.03+
2. Opdatering fejlede midtvejs
3. Triggers er blevet slettet ved en fejl

**Løsning:**
Kør EPOpdat12.pas opdatering igen (eller relevant del af den).

### For Brugere

**Manuel synkronisering:**

Brugere kan selv trigger en vare til BC synk:
1. Åbn varen i EasyPOSKontor
2. Højreklik eller menu → "Synkroniser vare imod Business Central"
3. Varen synkroniseres automatisk ved næste EP_TO_BC kørsel

---

## 🎓 Anbefalinger

### For Nye Installationer

Sikr at EPOpdat12.pas's BC integration steps køres:
- Step 1: Opret BC_UPDATEDATE felt
- Step 2: Opret index
- Step 3: Initialiser med WEBDATO
- Step 4: Opret triggers

### For Fejlfinding

**Check om triggers eksisterer:**
```sql
SELECT RDB$TRIGGER_NAME 
FROM RDB$TRIGGERS 
WHERE RDB$TRIGGER_NAME IN (
    'VARER_BC_CHANGES', 
    'VAREFRVSTR_BC_CHANGES', 
    'INS_VAREFRVSTR'
);
```

**Check om index eksisterer:**
```sql
SELECT RDB$INDEX_NAME 
FROM RDB$INDICES 
WHERE RDB$INDEX_NAME = 'VARER_BC_UPDATEDATE';
```

---

## ✅ Final Konklusion

**EasyPOSKontor:**
1. ✅ **Installer** hele BC_UPDATEDATE infrastrukturen
2. ✅ **Viser** BC_UPDATEDATE til bruger
3. ✅ **Tillader** manuel force-synk
4. ✅ **Ændringer** triggerer automatisk via database triggers

**BC_UPDATEDATE vedligeholdes af:**
- Database triggers (oprettet af EasyPOSKontor)
- Manuel force-synk (fra EasyPOSKontor menu)
- P_UPDATEITEMS procedure (import)

---

**Dokumenteret:** 2025-12-09  
**Projekt:** Z:\EasyPOS\EasyPOSKontor  
**Metode:** Source code analyse  
**Resultat:** Installation + Manuel force-synk funktion fundet
