# Synkroniseringsmetoder - Samlet Oversigt

**EasyPOS To Business Central Integration**

Dette dokument giver et overblik over alle synkroniseringsmetoder i systemet.

---

## Aktive Synkroniseringer

| # | Navn | Retning | Endpoint | INI Key | Dokument |
|---|---|---|---|---|---|
| 1 | Varer | EP → BC | kmItem | Items | [Internal/Sync_1_Items.md](Internal/Sync_1_Items.md) |
| 2 | Salgstransaktioner | EP → BC | kmItemSale | SalesTransactions | [Internal/Sync_2_Sales.md](Internal/Sync_2_Sales.md) |
| 3 | Flytningstransaktioner | EP → BC | kmItemMove | MovementsTransactions | [Internal/Sync_3_Movements.md](Internal/Sync_3_Movements.md) |
| 4 | Finansposter | EP → BC | kmCashstatement | FinancialRecords | [Internal/Sync_4_Financial.md](Internal/Sync_4_Financial.md) |
| 5 | **Kostpriser** | **BC → EP** | kmCostprice | Costprice from BC | [Internal/Sync_5_Costprice_From_BC.md](Internal/Sync_5_Costprice_From_BC.md) |

## Deaktiverede Synkroniseringer

| # | Navn | Status | Dokument |
|---|---|---|---|
| 6 | Lagerreguleringer | ❌ Udkommenteret | [Internal/Sync_6_StockRegulations_DISABLED.md](Internal/Sync_6_StockRegulations_DISABLED.md) |

---

## Kørselsoversigt

### Timer-baseret Eksekvering

```
Programstart
    ↓
Timer trigger (hvert X minut eller kl. Y)
    ↓
InitializeProgram()
    ↓
DoHandleEksportToBusinessCentral()
    ↓
┌─────────────────────────────────────────┐
│ For hver aktiveret synkronisering:     │
│                                         │
│ 1. DoSyncronizeItems                   │  → Varer
│ 2. DoSyncCostPriceFromBusinessCentral  │  → Kostpriser (BC→EP!)
│ 3. DoSyncronizeFinansCialRecords       │  → Finansposter
│ 4. DoSyncronizeSalesTransactions       │  → Salgstransaktioner
│ 5. DoSyncronizeMovemmentsTransaction   │  → Flytningstransaktioner
│ 6. (DoSyncronizeStockRegulation)       │  → DEAKTIVERET
└─────────────────────────────────────────┘
    ↓
DoClearFolder() - Ryd gamle logs
    ↓
Sleep til næste timer event
```

---

## Fælles Karakteristika

### Database Connection

**Alle metoder bruger:**
```pascal
ConnectToDB()
  ↓
FireDAC Transaction (tnMain)
  ↓
Diverse queries
  ↓
DisconnectFromDB()
```

### Transaction ID

**Alle metoder henter:**
```sql
EXECUTE PROCEDURE GETNAVISION_TRANSID(1)
RETURNING TRANSID
```

Dette giver et unikt ID per synkronisering til sporbarhed.

### Fejlhåndtering Pattern

**Fælles for alle:**
```
1. Try/Except på metode-niveau
2. For hver record:
   - GET for at checke eksistens
   - Hvis ikke findes: POST
   - Marker som eksporteret
3. Ved fejl:
   - Log til specifik fejl-fil
   - Stop yderligere behandling
   - Send email
   - Retry ved næste kørsel
```

### Tracing Log

**Alle logger til SLADREHANK:**
```sql
INSERT INTO SLADREHANK (
    DATO, ART, BONTEXT, ...
) VALUES (
    NOW, 
    3000 + [MetodeNummer*2],  -- Success
    'Beskrivelse OK', 
    ...
)
```

**ART koder:**
- 3001/3002 - Varer (succes/fejl)
- 3005/3006 - Salgstransaktioner
- 3011/3012 - Flytningstransaktioner
- 3015/3016 - Finansposter

---

## Data Flow Diagram

```
┌──────────────────────────────────┐
│  EasyPOSKontor                   │
│  (Manuel redigering)             │
│  → Triggers → BC_UPDATEDATE      │
└────────────┬─────────────────────┘
             │
┌────────────▼─────────────────────┐
│  Products API (CRUD)             │
│  (Import fra eksterne systemer)  │
│  → P_UPDATEITEMS → BC_UPDATEDATE │
└────────────┬─────────────────────┘
             │
             ▼
EasyPOS Database (Firebird)
         ↓
    ┌────────────────────────┐
    │  Windows Service       │
    │  (EasyPOS_To_BC)       │
    │                        │
    │  ┌──────────────────┐  │
    │  │ Timer (15 min)   │  │
    │  └──────────────────┘  │
    │         ↓              │
    │  ┌──────────────────┐  │
    │  │ 1. Varer         │──┼──→ BC: kmItem
    │  │  (BC_UPDATEDATE) │  │
    │  └──────────────────┘  │
    │  ┌──────────────────┐  │
    │  │ 2. Kostpriser    │←─┼─── BC: kmCostprice
    │  └──────────────────┘  │
    │  ┌──────────────────┐  │
    │  │ 3. Finansposter  │──┼──→ BC: kmCashstatement
    │  └──────────────────┘  │
    │  ┌──────────────────┐  │
    │  │ 4. Salg          │──┼──→ BC: kmItemSale
    │  └──────────────────┘  │
    │  ┌──────────────────┐  │
    │  │ 5. Flytninger    │──┼──→ BC: kmItemMove
    │  └──────────────────┘  │
    └────────────────────────┘
         ↓
    Log filer / Email
```

---

## INI Fil Konfiguration

### Eksempel Settings.INI

```ini
[PROGRAM]
DATABASE=server:path\database.fdb
USER=sysdba
PASSWORD=***
Department=001
Machine=Kasse1
RUNTIME=22              ; Kør kl. 22
RUN AT EACH MINUTE=0    ; 0=dagligt, 1=hvert X min
LOGFILEFOLDER=C:\Logs\EasyPOS_BC\
TestRoutine=0           ; 0=prod, 1=test (ingen eksport)

[BUSINESS CENTRAL]
BC_BASEURL=https://api.businesscentral.dynamics.com
BC_PORT=
BC_COMPANY_URL=v2.0/tenant/prod/ODataV4/Company('guid')
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
StockRegulationsTransactions=0  ; SKAL være 0!

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

---

## Typiske Kørselsstatistikker

**Baseret på gennemsnit kunde:**

| Synk | Records/dag | Tid per kørsel | Kritisk? |
|---|---|---|---|
| Varer | 50-200 | 2-5 min | Medium |
| Kostpriser | 10-50 | 10-30 min | Lav |
| Finansposter | 100-500 | 3-8 min | Høj |
| Salgstransaktioner | 500-2000 | 5-10 min | Høj |
| Flytningstransaktioner | 50-200 | 3-7 min | Medium |

**Total kørselstime:** 25-60 minutter per dag (ved daglig kørsel kl. 22)

---

## Monitoring Checklist

### Daglig Kontrol

- [ ] Check Windows Event Viewer for event ID 1000, 3xxx
- [ ] Review `[LogFolder]\Log[YYYYMMDD].txt`
- [ ] Tjek for email fejl-notifikationer
- [ ] Verificer `Last run` datoer i INI fil

### Ugentlig Kontrol

- [ ] Review alle fejl-logs i `[LogFolder]`
- [ ] Check SLADREHANK for ART 30xx records
- [ ] Verificer data-integritet i BC vs EasyPOS

### Månedlig Kontrol

- [ ] Performance analyse (kørselsider)
- [ ] Cleanup af gamle logs (automatisk, men verificer)
- [ ] Review valutakurser (kostpris synk)

---

## Fejlfinding Guide

### Problem: Synkronisering starter ikke

**Check:**
1. Windows Service kører?
2. Timer enabled?
3. `ItIsTimeToRun()` returnerer TRUE?
4. Database forbindelse OK?

### Problem: Records synkroniseres ikke

**Check:**
1. `EKSPORTERET` / `BEHANDLET` flag i EasyPOS
2. `Last run` dato i INI (for langt frem?)
3. `Days to look for records` værdi
4. Query WHERE clause filtre

### Problem: 503 errors fra BC

**Løsning:**
- Normal BC rate limiting
- Vent 5-10 minutter
- Reducer `Items to handle per cycle`

### Problem: Valuta fejl (kostpriser)

**Check:**
1. VALUTALINIER har aktuel kurs?
2. STAMDATA_PRG_EXT har korrekt STDVALUTA?
3. Beregning: `(DKK / Kurs) * 100`

---

## Performance Tuning

### Generelt

1. **Kør uden for åbningstid**
   - Mindre database load
   - Færre locks

2. **Juster timer interval**
   - Daglig: RUNTIME=2200
   - Hver time: RUN AT EACH MINUTE=1, RUNTIME=60

3. **Batch sizes**
   - Kostpris: 200 variants per batch (fast)
   - Items to handle: Juster efter behov

### Per Synkronisering

**Varer:**
- Reducer lookback days
- Filtrer på specifikke afdelinger

**Kostpriser:**
- Kør kun ugentligt?
- Reducer `Items to handle per cycle`

**Finansposter:**
- OK som den er

**Salgstransaktioner:**
- Kritisk - kør dagligt minimum

**Flytningstransaktioner:**
- OK som den er

---

## Backup og Disaster Recovery

### Før Store Opdateringer

```sql
-- Backup EasyPOS
gbak -b -user sysdba -password *** server:database.fdb backup.fbk

-- Backup INI fil
copy Settings.INI Settings_BACKUP_[DATO].INI
```

### Ved Fejl i Kostpris-synk

**Lager kan være inkonsistent!**

```sql
-- Check lager-status
SELECT V509INDEX, AFDELING_ID, ANTALSTK, VEJETKOSTPRISSTK
FROM VAREFRVSTR_DETAIL
WHERE V509INDEX = '[barcode]';

-- Revert til backup hvis nødvendigt
```

### Ved Duplikater i BC

**Sjældent, men kan ske:**

```sql
-- Find duplikater i EasyPOS
SELECT TRANSID, COUNT(*)
FROM TRANSAKTIONER
WHERE EKSPORTERET > 1
GROUP BY TRANSID
HAVING COUNT(*) > 1;
```

I BC:
```
GET /kmItemSale?$filter=epId eq [ID]
DELETE /kmItemSale([duplikat-guid])
```

---

## Videreudvikling

### Potentielle Forbedringer

1. **Real-time sync:**
   - Webhook ved ændringer
   - Reducer batch delay

2. **Parallel processing:**
   - Multiple threads
   - Hurtigere kørselsider

3. **Better error recovery:**
   - Automatisk retry ved 503
   - Partial rollback

4. **Monitoring dashboard:**
   - Web UI til status
   - Grafisk oversigt

5. **Audit trail:**
   - Bedre sporbarhed
   - Change tracking

---

## Support Kontakter

**Ved tekniske problemer:**
- EasyPOS Support: [kontaktinfo]
- BC Integration Team: [kontaktinfo]
- Systemadministrator: [kontaktinfo]

**Eskalering:**
1. Check logs og dokumentation
2. Kontakt support med log-filer
3. Ved kritiske fejl: Direkte telefon

---

## Se Også

- [Projekt_Analyse.md](Projekt_Analyse.md) - Hovedoversigt
- Individuelle synk-dokumenter (se tabel øverst)
- Business Central API dokumentation
- EasyPOS database dokumentation

---

**Sidst opdateret:** 2025-12-09  
**Version:** 1.0  
**Forfatter:** System dokumentation baseret på kodeanalyse
