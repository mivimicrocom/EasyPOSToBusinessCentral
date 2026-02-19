# EasyPOS To Business Central - Integration Service

[![Delphi](https://img.shields.io/badge/Delphi-12.3-red.svg)](https://www.embarcadero.com/products/delphi)
[![Platform](https://img.shields.io/badge/Platform-Windows-blue.svg)](https://www.microsoft.com/windows)
[![License](https://img.shields.io/badge/License-Proprietary-orange.svg)](LICENSE)

En Windows Service der automatisk synkroniserer data fra **EasyPOS** (Point-of-Sale) til **Microsoft Dynamics 365 Business Central** (ERP).

---

## 📋 Indholdsfortegnelse

- [Oversigt](#oversigt)
- [Funktionalitet](#funktionalitet)
- [Arkitektur](#arkitektur)
- [Installation](#installation)
- [Konfiguration](#konfiguration)
- [Synkroniseringsmoduler](#synkroniseringsmoduler)
- [Monitoring & Logs](#monitoring--logs)
- [Dokumentation](#dokumentation)
- [Udvikling](#udvikling)
- [Support](#support)

---

## 🎯 Oversigt

Dette projekt er en **Windows Service** der fungerer som en bro mellem EasyPOS kasseapparatsystemet og Microsoft Business Central ERP-systemet. Servicen sikrer, at transaktioner, varer, økonomiske data og lagerflytninger automatisk og pålideligt overføres mellem de to systemer.

### Nøglefunktioner

- ✅ **Automatisk synkronisering** af varer, salg, flytninger og finansposter
- ✅ **Bi-direktional synkronisering** (kostpriser fra BC til EasyPOS)
- ✅ **Timer-baseret eksekvering** med konfigurerbar interval
- ✅ **Omfattende logging** og fejlhåndtering
- ✅ **Email-notifikationer** ved fejl
- ✅ **Windows Event Log** integration
- ✅ **Debug mode** til test og udvikling

### Deployment Modes

- **Release mode:** Kører som Windows Service i baggrunden
- **Debug mode:** Kører som desktop applikation til test og fejlfinding

---

## 🔄 Funktionalitet

### Synkroniseringsretninger

```
┌─────────────────────────────────────────────────────────────┐
│                      EasyPOS Database                       │
│                       (Firebird SQL)                        │
└────────┬───────────────────────────────────────────┬────────┘
         │                                           │
         │ ① Varer                                   │ ⑤ Kostpriser
         │ ② Salgstransaktioner         ← ← ← ← ← ← │
         │ ③ Flytningstransaktioner                  │
         │ ④ Finansposter                            │
         ↓                                           ↑
┌────────────────────────────────────────────────────────────┐
│                  Windows Service                           │
│          EasyPOS To Business Central                       │
│                                                             │
│  • Timer-baseret eksekvering (konfigurerbart interval)     │
│  • Transaction ID tracking for sporbarhed                  │
│  • Fejlhåndtering og automatisk retry                      │
│  • Email-notifikationer ved fejl                           │
└────────┬───────────────────────────────────────────┬────────┘
         │                                           │
         ↓                                           ↑
┌─────────────────────────────────────────────────────────────┐
│          Microsoft Dynamics 365 Business Central            │
│                         REST API                            │
│        (OAuth2 Cloud / Basic On-Premise)                    │
└─────────────────────────────────────────────────────────────┘
```

### Supported Customers

Servicen understøtter følgende Business Central konfigurationer:

- **Kaufmann** (Version 0: On-premise BC med Basic Auth)
- **ny-form** (Version 2: Cloud BC med OAuth2)

---

## 🏗️ Arkitektur

### Hovedkomponenter

```
EasyPOS_To_BusinessCentral.dpr (Hovedprogram)
│
├── uEasyPOSToBC.pas              Windows Service implementation
├── UDM.pas                        Data Module (hovedlogik & timer)
├── uMain.pas                      Debug/test GUI form
├── uEventLogger.pas               Windows Event Log integration
│
├── BusinessCentral-Integration/   Git submodule
│   ├── uBusinessCentralIntegration.pas    BC REST API client
│   └── USelectCompany.pas                  Company selection dialog
│
├── AfsendMail/                    Email modul
│   └── uSendEMail.pas                     SMTP email sender
│
└── Helper/                        Hjælpeprogrammer
    └── INIFileEditor/                     INI konfigurationseditor
```

### Teknologi Stack

- **Sprog:** Delphi 12.3 (Object Pascal)
- **Database:** Firebird SQL (via FireDAC)
- **API:** REST Client med OAuth2/Basic Auth
- **Serialization:** MVCFramework JSON
- **Email:** Indy SMTP komponenter

---

## 📦 Installation

### Forudsætninger

- Windows Server 2016+ eller Windows 10+
- .NET Framework 4.8+
- Adgang til EasyPOS Firebird database
- Business Central API credentials (OAuth2 eller Basic Auth)
- SMTP server til email-notifikationer

### Installation Steps

1. **Kompiler projektet** i Delphi (Release mode)
   ```
   EasyPOS_To_BusinessCentral.dproj
   ```

2. **Installer som Windows Service**
   ```cmd
   EasyPOS_To_BusinessCentral.exe /install
   ```

3. **Konfigurer INI-fil** (se [Konfiguration](#konfiguration))

4. **Start servicen**
   ```cmd
   net start "EasyPOS To Business Central"
   ```
   Eller via Windows Services (services.msc)

### Afinstallation

```cmd
net stop "EasyPOS To Business Central"
EasyPOS_To_BusinessCentral.exe /uninstall
```

---

## ⚙️ Konfiguration

Servicen konfigureres via en `Settings.INI` fil placeret i samme mappe som EXE-filen.

### Eksempel Settings.INI

```ini
[PROGRAM]
DATABASE=server.local:C:\Databases\EasyPOS.fdb
USER=sysdba
PASSWORD=masterkey
Department=001
Machine=WindowsService
RUNTIME=22                  ; Se "Timer Modes" nedenfor
RUN AT EACH MINUTE=0        ; 0=dagligt/interval, 1=fast interval
LOGFILEFOLDER=C:\Logs\EasyPOS_BC\
TestRoutine=0               ; 0=production, 1=test mode (ingen eksport)

[BUSINESS CENTRAL]
BC_BASEURL=https://api.businesscentral.dynamics.com
BC_PORT=
BC_COMPANY_URL=v2.0/12345678-abcd-1234-abcd-123456789abc/Production/ODataV4/Company('company-guid')
BC_ENVIRONMENT=Production
BC_USERNAME=user@domain.com
BC_PASSWORD=***
BC_ACTIVECOMPANYID={GUID}
Online Business Central=KAUFMANN    ; KAUFMANN eller NYFORM

[SYNCRONIZE]
Items=1                              ; Varer
SalesTransactions=1                  ; Salg
MovementsTransactions=1              ; Flytninger
FinancialRecords=1                   ; Finansposter
Costprice from BC=1                  ; Kostpriser (BC → EP)
StockRegulationsTransactions=0       ; ⚠️ SKAL være 0 (deaktiveret)

[Items]
Last run=45000.5
Days to look for records=5
Department=001

[SalesTransaction]
Last run=45000.6
Days to look for records=5

[MovementsTransaction]
Last run=45000.6
Days to look for records=5

[FinancialRecords]
Last run=45000.7
Days to look for records=5

[Costprice]
Items to handle per cycle=50

[MAIL]
From name=EasyPOS Service
From mail=service@company.dk
Reply name=IT Support
Reply mail=support@company.dk
Recipient Mail=admin@company.dk
Subject=EasyPOS-BC Sync Error
Host=smtp.office365.com
Port=587
Username=service@company.dk
Password=***
UseTSL=1
```

### Vigtige Settings

| Setting | Beskrivelse |
|---------|-------------|
| `RUNTIME` | Se "Timer Modes" nedenfor for detaljer |
| `RUN AT EACH MINUTE` | 0=daglig/interval mode, 1=fast interval |
| `TestRoutine` | 1=test mode (ingen data eksporteres til BC) |
| `Days to look for records` | Hvor langt tilbage der søges efter nye records |
| `Last run` | Timestamp for sidste succesfulde synk (auto-opdateres) |

### Timer Modes

Servicen kan køre på tre forskellige måder:

#### Mode 1: Daglig kørsel på fast tidspunkt
```ini
RUNTIME=22                  ; Kør én gang dagligt kl. 22:00
RUN AT EACH MINUTE=0
```
- Kører én gang dagligt på det angivne tidspunkt
- Tjekker hvert 15. minut om det er tid at køre
- Kører kun én gang per dag

#### Mode 2: Daglig kørsel i tidsinterval (nattetimer)
```ini
RUNTIME=2205                ; Kør mellem kl. 22:00 og 05:00
RUN AT EACH MINUTE=0
```
- Kører når nuværende time ligger mellem time 1 og time 2
- Nyttigt for natkørsel (f.eks. 22:00-05:00)
- Tjekker hvert 15. minut og kan køre flere gange
- **Format:** HHMM hvor HH=start time, MM=slut time

#### Mode 3: Fast interval gennem dagen
```ini
RUNTIME=60                  ; Kør hvert 60. minut
RUN AT EACH MINUTE=1
```
- Kører kontinuerligt med fast interval (i minutter)
- Kører hele dagen, hver X minut
- Værdi i RUNTIME angiver interval i minutter

---

## 🔄 Synkroniseringsmoduler

Servicen udfører følgende synkroniseringer i denne rækkefølge:

### 1. Varer (Items) - EP → BC

**API Endpoint:** `kmItem`  
**Trigger:** `BC_UPDATEDATE` felt opdateret i VARER tabel

Synkroniserer varer og varianter når:
- Manuel redigering i EasyPOSKontor
- Import via Products API (CRUD)
- Database triggers detekterer ændringer

**Status:** ✅ Aktiv

### 2. Salgstransaktioner (Sales) - EP → BC

**API Endpoint:** `kmItemSale`  
**Trigger:** `EKSPORTERET = 0`

Synkroniserer:
- Salgslinjer fra kasseapparater
- Pris, antal, rabat
- Moms information
- Timestamp og bruger

**Status:** ✅ Aktiv

### 3. Flytningstransaktioner (Movements) - EP → BC

**API Endpoint:** `kmItemMove`  
**Trigger:** `EKSPORTERET = 0`

Synkroniserer:
- Lagerflytninger mellem afdelinger
- Svind og regulering
- Interne overførsler

**Status:** ✅ Aktiv

### 4. Finansposter (Financial) - EP → BC

**API Endpoint:** `kmCashstatement`  
**Trigger:** `BEHANDLET = 0`

Synkroniserer:
- Kassekladde (Z-rapporter)
- Betalingsformer (kontant, kort, MobilePay)
- Bank- og debitorposteringer
- Post type mapping til BC

**Status:** ✅ Aktiv

### 5. Kostpriser (Cost Prices) - BC → EP ⬅️

**API Endpoint:** `kmCostprice` (GET)  
**Batch size:** 200 varianter per kørsel

Synkroniserer:
- **Kostpriser fra Business Central til EasyPOS**
- **⚠️ Opdaterer direkte lagerbeholdning via regulering**
- Valutakonvertering (DKK til lokal valuta)
- Opdaterer `VAREFRVSTR_DETAIL` og `VAREFRVSTR` tabeller

**Status:** ✅ Aktiv (kræver forsigtighed!)

### 6. Lagerreguleringer (Stock Regulations) - ❌ DEAKTIVERET

**API Endpoint:** `kmItemAccess`

**Status:** ❌ **PERMANENT DEAKTIVERET**

Denne synkronisering er udkommenteret i koden og MÅ IKKE aktiveres uden grundig analyse. Se dokumentation i `Docs/Internal/Sync_6_StockRegulations_DISABLED.md`.

---

## 📊 Monitoring & Logs

### Log Filer

Alle logfiler placeres i mappen angivet i `LOGFILEFOLDER`:

```
C:\Logs\EasyPOS_BC\
├── Log20260219.txt                    Daglig hovedlog
├── Log20260219_Items_Error.txt        Vare-fejl
├── Log20260219_Sales_Error.txt        Salg-fejl
├── Log20260219_Movements_Error.txt    Flytnings-fejl
├── Log20260219_Financial_Error.txt    Finans-fejl
└── Log20260219_Costprice_Error.txt    Kostpris-fejl
```

### Windows Event Log

Servicen logger til **Windows Event Viewer** under:
```
Application and Services Logs > EasyPOS To Business Central
```

**Event IDs:**
- `1000` - Generelle fejl
- `3101-3103` - Vare fejl
- `3201-3203` - Salg fejl
- `3301-3303` - Flytnings fejl
- `3402-3403` - Finans fejl
- `3503` - Kostpris fejl

### Database Tracing (SLADREHANK)

Alle synkroniseringer logges i `SLADREHANK` tabellen:

```sql
SELECT DATO, ART, BONTEXT, BETXT1, BETXT2
FROM SLADREHANK
WHERE ART BETWEEN 3000 AND 3999
ORDER BY DATO DESC;
```

**ART koder:**
- `3001/3002` - Varer (success/error)
- `3005/3006` - Salg (success/error)
- `3011/3012` - Flytninger (success/error)
- `3015/3016` - Finans (success/error)

### Email Notifikationer

Ved fejl sendes automatisk email til modtager(e) angivet i INI-filen med:
- Fejlbeskrivelse
- Attached logfil
- Timestamp og modul

---

## 📚 Dokumentation

Omfattende dokumentation findes i **`Docs/`** mappen:

### For Brugere (Ikke-tekniske)

| Dokument | Beskrivelse |
|----------|-------------|
| [Bruger_Guide_Vare_Synkronisering.md](Docs/Bruger_Guide_Vare_Synkronisering.md) | 🌟 **START HER!** Simpel guide til vare-synkronisering |
| [Projekt_Analyse.md](Docs/Projekt_Analyse.md) | Komplet projektanalyse |
| [Sync_Overview.md](Docs/Sync_Overview.md) | Oversigt over alle synkroniseringer |
| [BC_UPDATEDATE_Application_Overview.md](Docs/BC_UPDATEDATE_Application_Overview.md) | Hvordan BC_UPDATEDATE virker |

### For Udviklere - Teknisk Dokumentation

| Dokument | Synkronisering | Beskrivelse |
|----------|----------------|-------------|
| [TECH_Sync_Items.md](Docs/TECH_Sync_Items.md) | Varer (EP → BC) | Database queries, data mapping, API calls, fejlhåndtering |
| [TECH_Sync_Sales.md](Docs/TECH_Sync_Sales.md) | Salg (EP → BC) | Salgstransaktioner, ART koder, EKSPORTERET flag |
| [TECH_Sync_Movements.md](Docs/TECH_Sync_Movements.md) | Flytninger (EP → BC) | Lagerflytninger, svind, regulering |
| [TECH_Sync_Financial.md](Docs/TECH_Sync_Financial.md) | Finans (EP → BC) | Kassekladde, PostType mapping, Z-rapporter |
| [TECH_Sync_Costprice.md](Docs/TECH_Sync_Costprice.md) | Kostpriser (BC → EP) | ⚠️ Kritisk - opdaterer lagerbeholdning! |

### For Udviklere/Support

| Dokument | Beskrivelse |
|----------|-------------|
| [CHANGELOG.md](Docs/CHANGELOG.md) | Versionshistorik og ændringer |
| [SECURITY_FIXES.md](Docs/SECURITY_FIXES.md) | Sikkerhedsfixes |
| [Internal/](Docs/Internal/) | Teknisk dokumentation for hver synkronisering |

### Teknisk Dokumentation (Internal/)

| # | Dokument | Modul |
|---|----------|-------|
| 1 | [Sync_1_Items.md](Docs/Internal/Sync_1_Items.md) | Varer |
| 2 | [Sync_2_Sales.md](Docs/Internal/Sync_2_Sales.md) | Salgstransaktioner |
| 3 | [Sync_3_Movements.md](Docs/Internal/Sync_3_Movements.md) | Flytningstransaktioner |
| 4 | [Sync_4_Financial.md](Docs/Internal/Sync_4_Financial.md) | Finansposter |
| 5 | [Sync_5_Costprice_From_BC.md](Docs/Internal/Sync_5_Costprice_From_BC.md) | Kostpriser (BC → EP) |
| 6 | [Sync_6_StockRegulations_DISABLED.md](Docs/Internal/Sync_6_StockRegulations_DISABLED.md) | Lagerreguleringer (deaktiveret) |

---

## 🛠️ Udvikling

### Build Environment

- **Delphi Version:** 12.3 Athens
- **Project Group:** `EasyPOS_To_BusinessCentralGroup.groupproj`
- **Main Project:** `EasyPOS_To_BusinessCentral.dproj`

### Build Konfigurationer

**Release Build:**
```pascal
{$DEFINE RELEASE}
// Kompilerer som Windows Service
// Ingen debug GUI
```

**Debug Build:**
```pascal
{$UNDEF RELEASE}
// Kompilerer som desktop applikation
// Memory leak detection aktiv
// GUI til test
```

### Git Submodules

Projektet bruger et submodule til Business Central integration:

```bash
git submodule update --init --recursive
```

### Vigtige Dependencies

- **FireDAC** - Database connectivity
- **REST Client** - HTTP REST API calls
- **MVCFramework** - JSON serialization
- **Indy** - SMTP email (AfsendMail modul)

### Compile & Test

1. Åbn `EasyPOS_To_BusinessCentralGroup.groupproj` i Delphi
2. Vælg **Debug** configuration
3. Build → **Build All**
4. Run → Kør med F9
5. Test synkroniseringer via GUI

### Release Build

1. Vælg **Release** configuration
2. Build → **Build All**
3. Output: `Win32\Release\EasyPOS_To_BusinessCentral.exe`

---

## 🔐 Sikkerhed

### ⚠️ Vigtige Sikkerhedsovervejelser

1. **INI-fil passwords er i plain text**
   - Placer INI-fil med begrænsede adgangsrettigheder
   - Overvej kryptering eller Windows Credential Manager

2. **Kostpris-synkronisering er kritisk**
   - Opdaterer direkte lagerbeholdning
   - Fejl kan medføre inkonsistens
   - Kræver grundig test før aktivering

3. **Windows Service sikkerhed**
   - Kør under dedikeret service account
   - Begræns database og API adgang til minimum
   - Overvåg Windows Event Log for uautoriseret adgang

4. **API credentials**
   - Brug mindste nødvendige privilegier i Business Central
   - Roter passwords regelmæssigt
   - Overvåg API usage i BC

---

## 🐛 Fejlfinding

### Servicen starter ikke

**Check:**
1. Windows Services (services.msc) - er servicen installeret?
2. INI-fil placering - findes `Settings.INI` ved siden af EXE?
3. Database forbindelse - kan servicen tilgå Firebird databasen?
4. Windows Event Log - se fejlbeskeder

### Records synkroniseres ikke

**Check:**
1. INI: Er synkronisering aktiveret (`[SYNCRONIZE]` sektion)?
2. `Last run` dato - ligger den for langt frem?
3. `Days to look for records` - er værdien for lille?
4. Database: Er `EKSPORTERET`/`BEHANDLET` flag sat korrekt?
5. Database: Er `BC_UPDATEDATE` opdateret (for varer)?

### BC API fejl (503 Service Unavailable)

**Løsning:**
- Dette er normal BC rate limiting
- Servicen venter automatisk 5-10 minutter
- Reducer `Items to handle per cycle` i INI-fil

### Email notifikationer sendes ikke

**Check:**
1. SMTP settings i `[MAIL]` sektion
2. Firewall tillader udgående SMTP (port 587)
3. SMTP credentials er korrekte
4. Test SMTP connection manuelt

---

## 🤝 Support

### Rapportering af Fejl

Ved fejl eller problemer:

1. **Tjek logs** (`LOGFILEFOLDER`)
2. **Tjek Windows Event Viewer**
3. **Tjek dokumentation** i `Docs/`
4. **Kontakt support** med følgende information:
   - Logfiler (hele dagen)
   - Windows Event Log export
   - INI-fil (red passwords)
   - Beskrivelse af problem

### Support Kontakter

**For tekniske problemer:**
- EasyPOS Support: [kontaktinfo]
- BC Integration Team: [kontaktinfo]
- Systemadministrator: [kontaktinfo]

---

## 📄 Licens

Dette projekt er proprietær software udviklet til intern brug.

**Fortrolighed:** Indeholder kunde-specifikke oplysninger og skal behandles fortroligt.

---

## 🔗 Relaterede Projekter

- **EasyPOSKontor** - Desktop applikation til varevedligeholdelse
- **EasyPOS Products API** - REST API til vare-import (CRUD)
- **Business Central** - Microsoft Dynamics 365 ERP

---

## 📝 Changelog

Se [CHANGELOG.md](Docs/CHANGELOG.md) for versionshistorik og seneste ændringer.

**Seneste version:** Se build info i compiled EXE  
**Sidst opdateret:** 2026-02-19

---

## 🎯 Roadmap

**Planlagte forbedringer:**

- [ ] Kryptering af passwords i INI-fil
- [ ] Real-time sync via webhooks
- [ ] Web-baseret monitoring dashboard
- [ ] Parallel processing for hurtigere synk
- [ ] Automatisk retry ved transiente fejl
- [ ] Bedre audit trail og change tracking

---

**Udviklet med ❤️ i Delphi**
