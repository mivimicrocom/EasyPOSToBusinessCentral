# EasyPOS To Business Central - Projekt Analyse

**Dato:** 2025-12-09  
**Version:** Baseret på kodeanalyse

---

## 1. Projektoversigt

### Formål
Dette projekt er en **Windows Service** der synkroniserer data fra **EasyPOS** (et Point-of-Sale system) til **Microsoft Business Central** (et ERP system).

Programmet fungerer som en bro mellem de to systemer og sikrer, at transaktioner, varer, og økonomiske data automatisk overføres fra kasseapparatet (EasyPOS) til regnskabssystemet (Business Central).

### Deployment
- **Release mode:** Kører som Windows Service i baggrunden
- **Debug mode:** Kan køres som normal applikation til test

---

## 2. Arkitektur

### Hovedkomponenter

```
EasyPOS_To_BusinessCentral (Main Program)
├── uEasyPOSToBC.pas          - Windows Service implementation
├── UDM.pas                   - Data Module (hovedlogik)
├── uMain.pas                 - Debug/test form
├── uEventLogger.pas          - Windows Event Log integration
└── BusinessCentral-Integration/ (Submodule)
    └── uBusinessCentralIntegration.pas - BC API client
```

### Datakilder til BC_UPDATEDATE

Varer kan blive markeret til synkronisering fra 3 kilder:

1. **EasyPOSKontor** - Manuel redigering af varer
2. **Products API (CRUD)** - Automatisk import fra eksterne systemer
3. **Database triggers** - Automatisk ved vare-ændringer

### Database
- **Type:** Firebird SQL
- **Forbindelse:** Via FireDAC komponenter
- **Konfiguration:** Fra INI-fil eller direkte fra database

### API Integration
- **Business Central REST API**
- **Autentifikation:** 
  - Version 0: Basic Authentication (On-premise BC)
  - Version 2: OAuth2 (Cloud BC)
- **Kunder:** Kaufmann, ny-form

---

## 3. Funktionalitet

### 3.1 Timer-baseret Eksekvering

Programmet kører periodisk baseret på konfiguration:

- **Timer interval:** Konfigurerbart (standard 15 min)
- **Kørselstid:** Kan sættes til specifik time (f.eks. kl. 22)
- **Interval mode:** Kan køre hvert X minut ELLER på bestemt tidspunkt

**Styring:**
```pascal
procedure tiTimerTimer(Sender: TObject);
```

### 3.2 Synkroniseringsmoduler

Programmet synkroniserer følgende datatyper:

#### A. **Varer (Items)**
**Metode:** `DoSyncronizeItems`

- Henter nye/opdaterede varer fra EasyPOS
- Opretter/opdaterer i Business Central via `kmItem` API
- Markerer som eksporteret i EasyPOS
- Logging af succesfulde/fejlede operationer

**Vare-opdateringer triggeres af:**
1. **Manuel redigering** i EasyPOSKontor → Database triggers → BC_UPDATEDATE = NOW
2. **Products API (CRUD)** → P_UPDATEITEMS → Triggers → BC_UPDATEDATE = NOW (kun hvis felter ændres)
3. **Import jobs** → P_UPDATEITEMS → Triggers → BC_UPDATEDATE = NOW (kun hvis felter ændres)

**Flow:**
1. Hent varer der skal eksporteres fra EasyPOS database
   ```sql
   WHERE VARER.BC_UPDATEDATE >= :PStartDato 
     AND VARER.BC_UPDATEDATE <= :PSlutDato
   ```
2. For hver vare:
   - Tjek om den allerede findes i BC (via GET request)
   - Hvis ikke: POST ny vare til BC
   - Hvis ja: Skip
3. Marker vare som eksporteret i EasyPOS
4. Log i SLADREHANK tabel

#### B. **Kostpriser (Cost Prices)**
**Metode:** `DoSyncCostPriceFromBusinessCentral`

- **Retning:** Fra Business Central → EasyPOS (modsat de andre!)
- Henter opdaterede kostpriser fra BC
- Opdaterer alle varianter i alle afdelinger
- Håndterer lagerbeholdning under opdatering:
  1. Fjern lager (P_STOCKREGULATE)
  2. Opdater kostpris
  3. Gendan lager med ny kostpris

**Særlige noter:**
- Batch processing: 200 varianter ad gangen
- Valuta-konvertering baseret på afdelingens kurs
- Spring over hvis kostpris er uændret

#### C. **Salgstransaktioner (Sales Transactions)**
**Metode:** `DoSyncronizeSalesTransactions`

- Henter salg fra EasyPOS (ART 0,1)
- Opretter `kmItemSale` records i BC
- Periode: Seneste X dage (konfigurerbart)
- Inkluderer: Vare, antal, pris, kostpris, moms, butik, kasse

**Felter der synkroniseres:**
- transId, epId, bonNummer
- VareId, variantId
- bogfRingsDato, salgstidspunkt
- antal, salgspris, kostPris, momsbelB
- kasse, butikId
- Status: 'Ubehandlet'

#### D. **Flytningstransaktioner (Movement Transactions)**
**Metode:** `DoSyncronizeMovemmentsTransaction`

- Varebevægelser mellem butikker (ART 14)
- Opretter `kmItemMove` records
- Fra-butik → Til-butik
- Inkluderer kostpris

#### E. **Finansposter (Financial Records)**
**Metode:** `DoSyncronizeFinansCialRecords`

- Eksporterer økonomiske poster
- Opretter JSON filer
- Håndterer kassekladde, momsbeløb, etc.

#### F. **Lagerreguleringer (Stock Regulations)** ❌
**Status:** Deaktiveret (udkommenteret kode)

- Tidligere: `DoSyncronizeStockRegulationTransaction`
- Ville synkronisere lagertilgange (ART 11)

---

## 4. Fejlhåndtering

### 4.1 Error Logging

**Lokale logfiler:**
- `Log[YYYYMMDD].txt` - Normal log
- `Log_Costprice[YYYYMMDD].txt` - Kostpris log
- `*Errors.txt` - Fejl pr. modul

**Fil-placering:** Konfigurerbar via INI fil

### 4.2 Email Notifikationer

Ved fejl sendes email til administrator med:
- Fejlbesked
- HTTP status code
- JSON payload
- Vedlagt logfil

**SMTP konfiguration:** Fra INI fil

### 4.3 Windows Event Log

Kritiske fejl logges til Windows Event Viewer:
```pascal
WriteEventLog(Message, '', Source, EVENTLOG_ERROR_TYPE, EventID, Category)
```

**Event IDs:**
- 1000: Generel fejl
- 3xxx: Modul-specifikke fejl (3201-3299: Sales, 3301-3399: Movements, etc.)

### 4.4 Status Code 503 Håndtering

Business Central sender 503 når API'et er overbelastet:
- Programmet registrerer tidspunkt for 503
- Kan implementere delay før genstart
- Logger men sender ikke gentagne emails

### 4.5 Retry Mekanik

- Transaktioner markeres med `EKSPORTERET` counter
- Ved fejl: Tæller op, prøves igen næste gang
- Query filtrerer: `WHERE (EKSPORTERET>=0 or EKSPORTERET IS null)`

---

## 5. Database Design

### Centrale Tabeller

#### TRANSAKTIONER
- Indeholder alle salgs- og lagertransaktioner
- `ART` field: Transaction type (0=salg, 1=retur, 14=flytning, 11=lager)
- `EKSPORTERET`: Synkroniseringsstatus (NULL/0 = ikke eksporteret)
- `BOGFORINGSDATO`: Posteringsdato

#### VARER
- Hovedvarer (PLU_NR = primær nøgle)
- `UPDATE_FROM_BC`: Flag for kostprisopdatering fra BC
- `SIDSTERET`: Sidste ændringsdato

#### VAREFRVSTR
- Varianter af hovedvarer
- `V509INDEX`: Stregkode/variant-ID
- Farve, Størrelse, Længde dimensions

#### VAREFRVSTR_DETAIL
- Variant detaljer pr. afdeling
- `VEJETKOSTPRISSTK`: Vejet kostpris
- `ANTALSTK`: Lagerbeholdning
- `SIDSTEKOSTPRSTK`: Sidste kostpris

#### SLADREHANK
- Audit trail / tracing log
- Registrerer alle synkroniseringsoperationer
- `ART`: 3000+ for BC synk events
- `BONTEXT`: Beskrivelse af operation

#### UNDERAFDELING
- Butikker/afdelinger
- BC connection settings (hvis ikke i INI)
- `KURS`: Valutakurs

---

## 6. Konfiguration

### INI Fil Struktur

**Placering:** `[ProgramFolder]\Settings.INI`

```ini
[PROGRAM]
DATABASE=Server:Path\Database.FDB
USER=SYSDBA
PASSWORD=masterkey
Department=001
Machine=Kasse1
TIMER=300
RUNTIME=22              ; Kørselstidspunkt (kl. 22) ELLER
RUNTIME=2206           ; Kør mellem kl. 22-06
RUN AT EACH MINUTE=0   ; 0=dagligt, 1=hvert X minut
LOGFILEFOLDER=C:\Logs\
TestRoutine=0          ; 1=test mode (ingen faktisk eksport)
LAST RUN=42000.5       ; TDateTime

[BUSINESS CENTRAL]
BC_BASEURL=https://api.businesscentral.dynamics.com
BC_PORT=7048
BC_COMPANY_URL=v2.0/[tenant]/[environment]/ODataV4/Company('[company]')
BC_ENVIRONMENT=Production
BC_USERNAME=user@domain.com
BC_PASSWORD=***
BC_ACTIVECOMPANYID={GUID}
Online Business Central=KAUFMANN  ; KAUFMANN eller NYFORM

[SYNCRONIZE]
FinancialRecords=1
Items=1
Costprice from BC=1
SalesTransactions=1
MovementsTransactions=1
StockRegulationsTransactions=0

[SalesTransaction]
Last run=42000.5
Days to look for records=5
Last time sync to BC was tried=42000.6

[MovementsTransaction]
Last run=42000.5
Days to look for records=5
Last time sync to BC was tried=42000.6

[Costprice]
Items to handle per cycle=50

[MAIL]
From name=EasyPOS Service
From mail=service@example.com
Reply name=Support
Reply mail=support@example.com
Recipient Mail=admin@example.com
Subject=EasyPOS-BC Sync Error
Host=smtp.office365.com
Port=587
Username=service@example.com
Password=***
UseTSL=1
```

---

## 7. Business Central API Endpoints

**Bruges fra submodulet:** `BusinessCentral-Integration`

### API Versioner

#### Version 0 (On-Premise BC)
```
http://[server]:[port]/[company]/ODataV4/Company('[companyId]')/
```

#### Version 2 (Cloud BC - OAuth2)
```
https://api.businesscentral.dynamics.com/v2.0/[tenant]/[environment]/ODataV4/Company('[companyId]')/
```

### Endpoints (OData)

```
GET/POST /kmItem              - Varer
GET/POST /kmItemSale          - Salgstransaktioner  
GET/POST /kmItemMove          - Flytningstransaktioner
GET/POST /kmItemAccess        - Lagertilgange (ikke brugt)
GET      /kmCostprice         - Kostpriser (read-only fra BC)
```

**OData features brugt:**
- `$filter` - Filtrering (eq, and, or)
- `$orderby` - Sortering
- `$select` - Field selection
- `$skip`, `$top` - Paginering

---

## 8. Særlige Features

### 8.1 Multi-Company Support

- Kaufmann (LF_BC_Version = 0)
- ny-form (LF_BC_Version = 2)

### 8.2 Valuta Håndtering

- Hovedvaluta: DKK
- Afdelings-specifik kurs i `UNDERAFDELING.KURS`
- Konvertering: `DKK = LocalPrice * Kurs / 100`

### 8.3 Batch Processing

- Kostpris: 200 varianter per batch
- Gentages indtil alle er håndteret
- Undgår timeout ved store datamængder

### 8.4 Transaction Safety

- FireDAC transactions
- Rollback ved fejl
- Separate transaktioner per modul:
  - `tnMain` - Hovedtransaktion
  - `trUpdateCostprice` - Kostpris updates
  - `trSetEksportedValueOnSaleTrans` - Markering af sales
  - `trSetEksportedValueOnMovementsTrans` - Markering af movements
  - osv.

### 8.5 SQL Logging

**Debug feature:** Gemmer SQL queries til filer
```
[LogFolder]\SQL\
  ItemsUpdateCostprice.SQL
  SalesTransactions.SQL
  MovementsTransactions.SQL
  etc.
```

---

## 9. Workflow - Typisk Kørsel

```
1. Timer trigger
   ↓
2. InitialilzeProgram()
   - Læs INI fil
   - Check om det er tid til at køre
   - Setup logfiler
   ↓
3. DoHandleEksportToBusinessCentral()
   ↓
4. For hver aktiveret modul:
   ┌─────────────────────────────┐
   │ A. ConnectToDB()            │
   │ B. Fetch records to sync    │
   │ C. For hver record:         │
   │    - Check if exists in BC  │
   │    - POST if new            │
   │    - Mark as exported       │
   │ D. InsertTracingLog()       │
   │ E. DisconnectFromDB()       │
   └─────────────────────────────┘
   ↓
5. DoClearFolder() - Cleanup gamle logs
   ↓
6. Sleep til næste timer event
```

---

## 10. Sikkerhed

### Credentials Storage
⚠️ **Advarsel:** Passwords gemmes i plain text i INI fil
- Bør sikres med NTFS permissions
- Kun SYSTEM/Admin adgang

### Network Security
- HTTPS til BC Cloud (Version 2)
- OAuth2 token-based auth
- Basic auth til on-premise (Version 0)

---

## 11. Performance Considerations

### Optimering
- **Incremental sync:** Kun nye/opdaterede records siden sidste kørsel
- **Batching:** 200 records ad gangen for kostpriser
- **Indexing:** Brug af FireDAC prepared statements
- **Filter queries:** WHERE clauses for at begrænse data

### Potential Bottlenecks
1. **BC API rate limits** → 503 responses
2. **Stor lagerbeholdning** → Kostprisopdatering kan være langsom
3. **Netværk latency** → Påvirker API calls

---

## 12. Vedligeholdelse

### Log Cleanup
- Automatisk sletning af filer ældre end 21 dage
- Kører ved hver synkronisering
- Targets: `Log*.*`, `Error*.*`, `EkspFinancialRecordsToBC*.*`

### Monitoring
1. **Windows Event Viewer** - Kritiske fejl
2. **Log filer** - Detaljeret trace
3. **Email alerts** - Ved synkroniseringsfejl
4. **Database SLADREHANK** - Audit trail

---

## 13. Kendte Begrænsninger

1. **Stock Regulation sync er deaktiveret** - Kommenteret ud i koden
2. **Email ved 503 errors** - Sender stadig emails selvom det er "normalt"
3. **INI fil passwords** - Ikke krypteret
4. **Single-threaded** - Én synkronisering ad gangen

---

## 14. Dependencies

### Delphi Libraries
- FireDAC (Database access)
- MVCFramework (Serialization)
- REST.Client (HTTP calls)
- Indy (SMTP email)

### External Systems
- Firebird SQL Server
- Microsoft Business Central (On-Prem eller Cloud)
- SMTP Server (til fejl-emails)

---

## 15. Build Information

**Project Files:**
- `EasyPOS_To_BusinessCentral.dpr` - Main program
- `EasyPOS_To_BusinessCentral.dproj` - Delphi project
- `EasyPOS_To_BusinessCentralGroup.groupproj` - Project group

**Conditional Compilation:**
```pascal
{$IFDEF RELEASE}  - Service mode
{$IFDEF DEBUG}    - Test mode med form
```

**Service Installation:**
```
Service Name: (Auto-generated fra DisplayName)
Display Name: EasyPOS To Business Central
Description: "EasyPOS Service to synconize data from EasyPOS to Business Central."
```

---

## Konklusion

Dette er et robust synkroniseringssystem der:
✅ Automatisk holder EasyPOS og Business Central synkroniseret  
✅ Håndterer fejl med logging, retry og email notifikationer  
✅ Understøtter både cloud og on-premise BC  
✅ Kører uovervåget som Windows Service  
✅ Kan testes i debug mode før deployment  

Systemet er produktionsklar og i brug hos mindst 2 kunder (Kaufmann, ny-form).
