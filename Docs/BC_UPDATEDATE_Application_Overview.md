# BC_UPDATEDATE - EasyPOS Applikationsoversigt

**Komplet guide til BC_UPDATEDATE håndtering på tværs af EasyPOS applikationer**

---

## 📋 Dokumentoversigt

| Applikation | Rolle | BC_UPDATEDATE Påvirkning |
|---|---|---|
| **EasyPOSKontor** | Admin/Setup | ✅ Installer + Manuel force-synk |
| **EasyPOSSalg** | Salgs POS | ❌ Ingen påvirkning |
| **EasyPOS Products API (CRUD)** | Vare import/opdatering | ⚡ Kun hvis felter ændres (via trigger) |
| **Database** | Persistens | ✅ Automatiske triggers |
| **EP_TO_BC** | Synkronisering | ✅ Læser feltet |

---

## 1️⃣ EasyPOSKontor - Admin Applikation

### 🎯 Primær Rolle

**Installation og vedligeholdelse af BC_UPDATEDATE infrastruktur**

### 📦 Installation (EPOpdat12.pas)

**Hvornår:** Ved system opdatering til version 8.03+

**Hvad installeres:**

#### Trin 1: Opret Database Felt
```sql
ALTER TABLE VARER
    ADD BC_UPDATEDATE DATE DEFAULT 'NOW';
```

**Formål:** Tilføjer timestamp felt til alle varer.

---

#### Trin 2: Opret Index
```sql
CREATE INDEX VARER_BC_UPDATEDATE
ON VARER (BC_UPDATEDATE);
```

**Formål:** Performance optimering af synkroniserings-queries.

---

#### Trin 3: Initialiser Data
```sql
UPDATE VARER SET
    VARER.BC_UPDATEDATE = VARER.WEBDATO;
```

**Formål:** Populerer eksisterende varer med initial værdi (fra WEBDATO).

---

#### Trin 4: Opret VAREFRVSTR_BC_CHANGES Trigger
```sql
CREATE OR ALTER TRIGGER VAREFRVSTR_BC_CHANGES FOR VAREFRVSTR
ACTIVE BEFORE UPDATE POSITION 0
AS
BEGIN
  /*This trigger is made to Kaufmann*/
  /*It can maybe be used to furture Business central integrations*/
  
  IF ((NEW.FARVE_NAVN <> OLD.FARVE_NAVN) OR
      (NEW.STOERRELSE_NAVN <> OLD.STOERRELSE_NAVN) OR
      (NEW.LAENGDE_NAVN <> OLD.LAENGDE_NAVN) OR
      (NEW.EANNUMMER <> OLD.EANNUMMER) OR
      (NEW.V509INDEX <> OLD.V509INDEX) OR
      (NEW.LEVVARENR <> OLD.LEVVARENR)) THEN
  BEGIN
    UPDATE VARER SET
        VARER.BC_UPDATEDATE = 'NOW'
    WHERE
        VARER.PLU_NR = NEW.VAREPLU_ID;
  END
END
```

**Formål:** Opdaterer hovedvare når variant-dimensioner ændres.

**Overvågede variant-felter:**
- FARVE_NAVN (farve)
- STOERRELSE_NAVN (størrelse)
- LAENGDE_NAVN (længde)
- EANNUMMER (EAN barcode)
- V509INDEX (stregkode)
- LEVVARENR (leverandørens varenummer)

---

#### Trin 5: Opret VARER_BC_CHANGES Trigger
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

**Formål:** Opdaterer BC_UPDATEDATE når vare master data ændres.

**Overvågede vare-felter:**
- PLU_NR (varenummer)
- VARENAVN1, VARENAVN2, VARENAVN3 (beskrivelser)
- MODEL
- WEBVARER (web markering)
- LEVERID (leverandør)
- VAREGRPID (varegruppe)
- KATEGORI1 (landekode)
- KATEGORI2 (vægt)
- ALT_VARE_NR (alternativt nummer)
- INTRASTAT (toldnummer)

---

#### Trin 6: Opdater INS_VAREFRVSTR Trigger
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

**Formål:** Opdaterer hovedvare når ny variant oprettes.

---

### 👤 Bruger Interface - Manuel Force Synk

**Menu Item:** "Synkroniser vare imod Business Central"

**Placering:** Vare-vinduet (højreklik menu eller toolbar)

**Kode (UVarer.pas, linje 23649):**
```delphi
procedure TfrmVarer.SynkroniservareimodBusinessCentral1Click(Sender: TObject);
var
  GemVareNr: String;
begin
  GemVareNr := DMVarer.Qvarer.FieldByName('PLU_NR').AsString;
  
  try
    DMVarer.VarerTrans.StartTransAction;
    
    DMVarer.QTemp.SQL.Clear;
    DMVarer.QTemp.SQL.Add('UPDATE VARER SET');
    DMVarer.QTemp.SQL.Add('    VARER.BC_UPDATEDATE = ''NOW''');
    DMVarer.QTemp.SQL.Add('WHERE');
    DMVarer.QTemp.SQL.Add('    VARER.PLU_NR = :PPLU_NR');
    DMVarer.QTemp.ParamByName('PPLU_NR').AsString := GemVareNr;
    DMVarer.QTemp.Open;
    
    DMVarer.VarerTrans.Commit;
  except
    on e: EIBError do
      ShowError('FEJL. Kan ikke sætte vare til overførsel til business central!');
  end;
  
  RefreshData;
end;
```

**Workflow:**
```
1. Bruger åbner vare i EasyPOSKontor
2. Bruger vælger menu: "Synkroniser vare imod Business Central"
3. BC_UPDATEDATE sættes til NOW
4. Vare data refreshes
5. Ved næste EP_TO_BC kørsel synkroniseres varen
```

**Use Cases:**
- Force re-synk af vare der fejlede tidligere
- Synkronisér vare efter manuel datakorrektion
- Test synkronisering af specifik vare
- Gensynkronisér vare hvis BC data er forkert

---

### 📊 Display til Bruger

**Vare Form (UVarer.dfm):**
```delphi
object DBText_BC_UPDATEDATE: TDBText
  DataField = 'BC_UPDATEDATE'
  DataSource = DMVarer.DSVarer
  DisplayFormat = 'dd-mm-yyyy hh:mm:ss'
end
```

**Hvad vises:**
- Seneste tidspunkt varen blev markeret til BC synk
- Format: "09-12-2025 13:45:30"
- Read-only felt

---

### ✅ EasyPOSKontor Opsummering

| Funktion | Metode | Hvornår |
|---|---|---|
| **Installation** | EPOpdat12.pas | Ved opdatering til v8.03+ |
| **Automatisk opdatering** | Database triggers | Ved vare-ændring |
| **Manuel force-synk** | Menu item | Efter bruger valg |
| **Display** | Vare form | Altid synlig |

**Konklusion:** EasyPOSKontor er **central hub** for BC_UPDATEDATE system.

---

## 2️⃣ EasyPOSSalg - Salgs POS Applikation

### 🎯 Primær Rolle

**Point-of-Sale system - INGEN BC_UPDATEDATE påvirkning**

### 🔍 Analyse Resultat

**Søgt efter:**
- ✅ Direkte BC_UPDATEDATE referencer
- ✅ UPDATE VARER statements
- ✅ Opdateringer til trigger-felter

**Resultat:** ❌ **INGEN FUND**

---

### 📝 Fundne UPDATE Statements

**Alle opdateringer var på VARER_BILLEDER (billeder), ikke VARER:**

| Fil | Formål | Påvirker BC_UPDATEDATE? |
|---|---|---|
| ULoadLogo.pas | Upload vare billede | ❌ Nej |
| UMereFakturaSetup.pas | Faktura setup | ❌ Nej |
| USecondWindowSettings.pas | Skærm indstillinger | ❌ Nej |
| UWEBOrdre.pas | Web ordre billeder | ❌ Nej |
| UWEBPlukliste.pas | Plukliste billeder | ❌ Nej |

**Konklusion:** VARER_BILLEDER tabel påvirker IKKE BC_UPDATEDATE.

---

### 🎯 EasyPOSSalg's Ansvar

**Hvad gør EasyPOSSalg:**
- ✅ Læser vare data (priser, beskrivelser)
- ✅ Registrerer salg
- ✅ Printer kvitteringer
- ✅ Håndterer betalinger
- ✅ Opdaterer lagerbeholdning

**Hvad gør EasyPOSSalg IKKE:**
- ❌ Ændrer vare master data
- ❌ Opdaterer varebeskrivelser
- ❌ Ændrer priser (kun læser)
- ❌ Modificerer leverandør/varegrupper
- ❌ Opdaterer BC_UPDATEDATE

---

### 💡 Rationale

**Hvorfor påvirker EasyPOSSalg ikke BC_UPDATEDATE?**

1. **Separation of Concerns:**
   - Salg ≠ Administration
   - POS system skal være simpelt og hurtigt
   - Master data vedligeholdes i kontor-system

2. **Sikkerhed:**
   - Kassemedarbejdere skal ikke ændre master data
   - Forhindrer utilsigtede ændringer
   - Bedre audit trail

3. **Performance:**
   - POS skal være lynhurtigt
   - Ingen unødvendige database writes
   - Fokus på salgs-transaktioner

---

### ✅ EasyPOSSalg Opsummering

| Funktion | Påvirkning | Note |
|---|---|---|
| **Læser vare data** | ❌ Ingen | Read-only |
| **Ændrer master data** | ❌ Ingen | Ikke tilladt |
| **Opdaterer BC_UPDATEDATE** | ❌ Ingen | Ingen kode |
| **Trigger BC synk** | ❌ Ingen | Kun via database triggers |

**Konklusion:** EasyPOSSalg er **fuldstændig isoleret** fra BC_UPDATEDATE.

---

## 3️⃣ EasyPOS Products API (CRUD) - Vare Import/Opdatering

### 🎯 Primær Rolle

**REST API til automatisk import og opdatering af varer fra eksterne systemer**

### 📡 API Endpoints

| Endpoint | Metode | Formål | BC_UPDATEDATE? |
|---|---|---|---|
| `/products/create` | POST | Opretter nye varer | ✅ Ja |
| `/products/update` | POST | Opdaterer eksisterende varer | ✅ Ja |
| `/products/createupdate` | POST | Opretter eller opdaterer | ✅ Ja |

---

### 🔄 Arbejdsflow - Products API

```
1. Eksternt system (WebOrder, integrator)
   ↓
2. POST request til /products/update eller /products/createupdate
   ↓
3. JSON data valideres og indsættes i:
   • CREATEUPDATE_ITEM (vare info)
   • CREATEUPDATE_PRICES (pris info)
   ↓
4. P_CREATEUPDATEITEMS kaldes (database stored procedure)
   ↓
5. P_UPDATEITEMS kaldes
   ↓
6. VARER opdateres (VARENAVN1, KATEGORI1, etc.)
   ↓
7. VARER_BC_CHANGES trigger aktiveres
   ↓
8. HVIS relevante felter ændret:
   → VARER.BC_UPDATEDATE = 'NOW'
   → Vare markeres til BC synkronisering
```

---

### 📝 Eksempel: Pris Opdatering

**JSON Request Body:**
```json
[
    {
        "barcode": "1085840130",
        "prices": [
            {
                "costprice": 113.36556,
                "departments": ["003"]
            },
            {
                "costprice": 146.34,
                "departments": ["004"]
            }
        ]
    }
]
```

**Hvad sker der:**
1. API modtager request på `/products/update`
2. Finder vare via barcode "1085840130"
3. Gemmer pris-opdateringer i CREATEUPDATE_PRICES
4. **P_UPDATEITEMS opdaterer vare-felter (beskrivelser, kategorier)**
5. **VARER_BC_CHANGES trigger tjekker om relevante felter er ændret**
6. **HVIS ændret:** `BC_UPDATEDATE = 'NOW'` → Vare synkroniseres til BC
7. **HVIS IKKE ændret:** BC_UPDATEDATE forbliver uændret

**Vigtigt:** BC_UPDATEDATE opdateres **KUN hvis faktiske vare-felter ændres!**
- ✅ Beskrivelser, kategorier, attributter ændret → BC_UPDATEDATE opdateres
- ❌ Kun priser sendes (uden vare-ændringer) → BC_UPDATEDATE forbliver uændret

---

### ⚡ Hvordan Opdateres BC_UPDATEDATE?

**Smart trigger-baseret opdatering:**

P_UPDATEITEMS opdaterer **IKKE** direkte BC_UPDATEDATE. I stedet:

1. **P_UPDATEITEMS opdaterer vare-felter:**
   ```sql
   UPDATE VARER SET
       VARER.VARENAVN1 = :LDESCRIPTION,
       VARER.KATEGORI1 = :LCATEGORY1,
       ...
   WHERE VARER.PLU_NR = :ITEMPLU_NR;
   ```

2. **VARER_BC_CHANGES trigger aktiveres** (BEFORE UPDATE)
3. **Trigger tjekker om relevante felter er ændret**
4. **KUN hvis ændret:** `BC_UPDATEDATE = 'NOW'`

**Konsekvens:**
- ✅ Kun faktiske vare-ændringer trigger BC synkronisering
- ✅ Undgår "tomme" synkroniseringer
- ❌ Pris-opdateringer alene opdaterer IKKE BC_UPDATEDATE
- ⚡ Effektiv og intelligent synkronisering

---

### 📌 Note Om Priser og BC_UPDATEDATE

**Vigtigt:** Kostpriser synkroniseres **IKKE** fra EasyPOS til Business Central!

**Korrekt dataflow:**
- ❌ **IKKE:** EasyPOS → BC (priser)
- ✅ **JA:** BC → EasyPOS (priser via Sync_5_Costprice_From_BC)
- ✅ **JA:** EasyPOS → BC (vare master data, beskrivelser, kategorier)

**BC_UPDATEDATE og priser:**
- ✅ Hvis API request **KUN** indeholder priser → BC_UPDATEDATE opdateres **IKKE**
- ✅ Hvis API request indeholder priser **OG** vare-felter → BC_UPDATEDATE opdateres (via trigger)
- ⚡ Smart trigger sikrer kun nødvendige synkroniseringer

---

### 🔧 Tekniske Detaljer

**Database Procedures Kaldt:**
1. `P_CREATEUPDATEITEMS` - Orchestrator
2. `P_UPDATEITEMS` - Opdaterer VARER tabel (BC_UPDATEDATE via triggers)
3. (Evt.) `P_CREATEITEMS` - Hvis vare ikke findes

**Tabeller Påvirket:**
- `CREATEUPDATE_ITEM` - Staging tabel for vare data
- `CREATEUPDATE_PRICES` - Staging tabel for priser
- `VARER` - **BC_UPDATEDATE opdateres her**
- `VAREFRVSTR` - Variant opdateringer

**Se også:** [Internal/P_UPDATEITEMS_Analysis.md](Internal/P_UPDATEITEMS_Analysis.md) for komplet teknisk dokumentation.

---

### ✅ EasyPOS Products API Opsummering

| Funktion | Påvirkning | Note |
|---|---|---|
| **Vare opdatering** | ✅ BC_UPDATEDATE = NOW | Kun hvis felter ændres |
| **Pris opdatering** | ❌ BC_UPDATEDATE uændret | Priser trigger IKKE synk |
| **BC synkronisering** | ⚡ Smart trigger | Via VARER_BC_CHANGES |
| **Manuel kontrol** | ❌ Nej | Automatisk process |

**Konklusion:** Products API (CRUD) kan **triggere** BC_UPDATEDATE via database triggers - men kun ved faktiske vare-ændringer.

---

## 4️⃣ Database Triggers - Automatisk Håndtering

### 🎯 Primær Rolle

**Automatisk opdatering af BC_UPDATEDATE ved data-ændringer**

### 📊 Trigger Oversigt

| Trigger | Tabel | Type | Formål |
|---|---|---|---|
| VARER_BC_CHANGES | VARER | BEFORE UPDATE | Opdater ved vare-ændring |
| VAREFRVSTR_BC_CHANGES | VAREFRVSTR | BEFORE UPDATE | Opdater ved variant-ændring |
| INS_VAREFRVSTR | VAREFRVSTR | AFTER INSERT | Opdater ved ny variant |

### 🔄 Automatisk Workflow

```
┌─────────────────────────────────────┐
│ Bruger ændrer vare i EasyPOSKontor │
└─────────────┬───────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│ Database UPDATE statement           │
└─────────────┬───────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│ Trigger aktiveres automatisk        │
│ (VARER_BC_CHANGES eller             │
│  VAREFRVSTR_BC_CHANGES)             │
└─────────────┬───────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│ BC_UPDATEDATE = 'NOW'               │
└─────────────┬───────────────────────┘
              │
              ▼
┌─────────────────────────────────────┐
│ Vare markeret til BC synkronisering │
└─────────────────────────────────────┘
```

### ✅ Database Trigger Opsummering

**Fordele:**
- ✅ Automatisk - ingen bruger-handling nødvendig
- ✅ Konsistent - virker uanset applikation
- ✅ Pålidelig - kan ikke glemmes
- ✅ Centraliseret - én kilde til sandhed

**Ulemper:**
- ⚠️ Kan ikke slås fra per applikation
- ⚠️ Kan skabe performance overhead
- ⚠️ Skal vedligeholdes ved nye felter

---

## 5️⃣ EP_TO_BC - Synkroniserings Service

### 🎯 Primær Rolle

**Læser BC_UPDATEDATE og synkroniserer til Business Central**

### 📖 Læser BC_UPDATEDATE

**Query (DoSyncronizeItems):**
```sql
SELECT DISTINCT
    VARER.PLU_NR AS VAREID,
    VARER.BC_UPDATEDATE,
    VAREFRVSTR.V509INDEX AS VARIANTID,
    ...
FROM VARER
    INNER JOIN VAREFRVSTR ON (VAREFRVSTR.VAREPLU_ID = VARER.PLU_NR)
    ...
WHERE
    VARER.BC_UPDATEDATE >= :PStartDato 
    AND VARER.BC_UPDATEDATE <= :PSlutDato
ORDER BY
    VARER.PLU_NR,
    VAREFRVSTR.V509INDEX
```

**Parametre:**
- `:PStartDato` = Last run - X dage
- `:PSlutDato` = NOW

### 🔄 Synkroniserings Workflow

```
1. Timer trigger (hver X minutter eller kl. Y)
2. Læs INI fil: [Items] Last run
3. Query VARER WHERE BC_UPDATEDATE >= Last run
4. For hver vare:
   ├─ Send hovedvare til BC (kmItem)
   ├─ Send alle varianter til BC (kmItem)
   ├─ Marker som EKSPORTERET
   └─ Log til SLADREHANK
5. Opdater INI fil: [Items] Last run = NOW
```

### ✅ EP_TO_BC Opsummering

**Ansvar:**
- ✅ Læser BC_UPDATEDATE
- ✅ Synkroniserer til Business Central
- ✅ Opdaterer Last run
- ❌ Ændrer IKKE BC_UPDATEDATE

---

## 📊 Samlet Data Flow

```
┌──────────────────────┐
│  EasyPOSKontor       │
│  (Admin)             │
│                      │
│  1. Installer        │
│     triggers         │
│                      │
│  2. Bruger ændrer    │
│     vare             │
│                      │
│  3. Manuel force     │
│     synk (menu)      │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│  Products API (CRUD) │
│                      │
│  1. Modtager POST    │
│  2. Validerer data   │
│  3. Kalder           │
│     P_UPDATEITEMS    │
│  4. Triggers sætter  │
│     BC_UPDATEDATE    │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│  Database            │
│  (Firebird)          │
│                      │
│  Triggers opdaterer  │
│  BC_UPDATEDATE       │
│  automatisk          │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│  EP_TO_BC            │
│  (Windows Service)   │
│                      │
│  Læser               │
│  BC_UPDATEDATE og    │
│  synkroniserer       │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│  Business Central    │
│  (ERP System)        │
│                      │
│  Modtager vare data  │
└──────────────────────┘

┌──────────────────────┐
│  EasyPOSSalg         │
│  (POS)               │
│                      │
│  Ingen påvirkning!   │
│  Read-only vare data │
└──────────────────────┘
```

---

## 🎯 Konklusion

### Applikations Ansvar

| Applikation | Installation | Opdatering | Læsning | Synkronisering |
|---|---|---|---|---|
| **EasyPOSKontor** | ✅ Ja | ✅ Manuel | ✅ Ja | ❌ Nej |
| **EasyPOSSalg** | ❌ Nej | ❌ Nej | ❌ Nej | ❌ Nej |
| **Products API (CRUD)** | ❌ Nej | ⚡ Via trigger | ❌ Nej | ❌ Nej |
| **Database Triggers** | ⚙️ Via Kontor | ✅ Automatisk | - | - |
| **EP_TO_BC** | ❌ Nej | ❌ Nej | ✅ Ja | ✅ Ja |

### Felter der Trigger Synkronisering

**VARER (12 felter):**
1. PLU_NR, VARENAVN1, VARENAVN2, VARENAVN3
2. MODEL, WEBVARER
3. LEVERID, VAREGRPID
4. KATEGORI1, KATEGORI2
5. ALT_VARE_NR, INTRASTAT

**VAREFRVSTR (5 felter):**
1. FARVE_NAVN, STOERRELSE_NAVN, LAENGDE_NAVN
2. EANNUMMER, LEVVARENR

**Special Cases:**
- Ny variant oprettet (INS_VAREFRVSTR)
- Import via P_UPDATEITEMS (Products API/CRUD) - kun hvis vare-felter ændres
- Manuel force-synk fra EasyPOSKontor

### Felter der IKKE Trigger Synkronisering

- ❌ Priser (håndteres fra BC → EasyPOS!)
- ❌ Lagerbeholdning
- ❌ Web felter (WEBOPDAT, WEBDATO)
- ❌ Kategorier 3, 4, 5
- ❌ Billeder (VARER_BILLEDER tabel)

---

## 📖 Support Guide

### For Brugere

**"Hvordan får jeg en vare synkroniseret til Business Central?"**

**Automatisk:**
1. Åbn varen i EasyPOSKontor
2. Ret ét af de 17 trigger-felter
3. Gem varen
4. BC_UPDATEDATE opdateres automatisk
5. Vent på næste EP_TO_BC kørsel

**Manuel force:**
1. Åbn varen i EasyPOSKontor
2. Højreklik → "Synkroniser vare imod Business Central"
3. Vent på næste EP_TO_BC kørsel

### For Support

**"Vare synkroniseres ikke til BC"**

**Check 1: Er BC_UPDATEDATE opdateret?**
```sql
SELECT PLU_NR, BC_UPDATEDATE, VARENAVN1 
FROM VARER 
WHERE PLU_NR = '12345';
```

**Check 2: Er BC_UPDATEDATE efter Last run?**
```ini
[Items]
Last run=45283.5  ; Er denne EFTER varefrets BC_UPDATEDATE?
```

**Check 3: Er triggers aktive?**
```sql
SELECT RDB$TRIGGER_NAME, RDB$TRIGGER_INACTIVE
FROM RDB$TRIGGERS 
WHERE RDB$TRIGGER_NAME IN (
    'VARER_BC_CHANGES',
    'VAREFRVSTR_BC_CHANGES', 
    'INS_VAREFRVSTR'
);
```
Skal returnere `RDB$TRIGGER_INACTIVE = 0` for alle.

**Løsning: Force re-synk**
```sql
UPDATE VARER 
SET BC_UPDATEDATE = 'NOW' 
WHERE PLU_NR = '12345';
```

### For Udviklere

**"Nyt felt skal trigger BC synkronisering"**

1. Tilføj til VARER_BC_CHANGES trigger (EPOpdat12.pas)
2. Opdater synkroniseringskode (DoSyncronizeItems)
3. Test grundigt!

---

## 🔒 Sikkerhed og Best Practices

### Do's ✅

- ✅ Brug manuel force-synk ved behov
- ✅ Monitor BC_UPDATEDATE i vare-vindue
- ✅ Sikr triggers er aktive efter DB restore
- ✅ Backup før store data-opdateringer
- ✅ Test synkronisering i test-miljø først

### Don'ts ❌

- ❌ Deaktiver aldrig triggerne
- ❌ Modificer ikke triggers manuelt
- ❌ Slet ikke BC_UPDATEDATE feltet
- ❌ Opdater ikke direkte fra EasyPOSSalg
- ❌ Forvent ikke real-time synkronisering

---

## 📚 Relateret Dokumentation

- [BC_UPDATEDATE_Complete_Analysis.md](BC_UPDATEDATE_Complete_Analysis.md) - Komplet database analyse
- [BC_UPDATEDATE_EasyPOSKontor_Analysis.md](BC_UPDATEDATE_EasyPOSKontor_Analysis.md) - Detaljeret Kontor analyse
- [BC_UPDATEDATE_EasyPOSSalg_Search.md](BC_UPDATEDATE_EasyPOSSalg_Search.md) - Salg søgeresultater
- [Sync_1_Items.md](Sync_1_Items.md) - Vare synkronisering dokumentation

---

**Dokumenteret:** 2025-12-09  
**Version:** 1.0  
**Forfattere:** System analyse baseret på kode review og database scanning  
**Status:** Komplet og verificeret
