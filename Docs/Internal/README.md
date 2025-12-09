# Internal - Teknisk Dokumentation

**Denne mappe indeholder detaljeret teknisk dokumentation beregnet til udviklere og teknisk support.**

---

## 📚 Indhold

### Synkroniseringer - Detaljeret SQL & Kode

Hvert dokument indeholder:
- Komplette SQL queries med parametre
- Felt-til-felt data mapping
- Business Central API calls (request/response)
- Fejlhåndtering og error codes
- Performance detaljer
- Debug SQL traces

| # | Dokument | Status | SQL Kompleksitet |
|---|---|---|---|
| 1 | [Sync_1_Items.md](Sync_1_Items.md) | ✅ Aktiv | ⭐⭐⭐ Høj |
| 2 | [Sync_2_Sales.md](Sync_2_Sales.md) | ✅ Aktiv | ⭐⭐ Medium |
| 3 | [Sync_3_Movements.md](Sync_3_Movements.md) | ✅ Aktiv | ⭐⭐ Medium |
| 4 | [Sync_4_Financial.md](Sync_4_Financial.md) | ✅ Aktiv | ⭐⭐⭐ Høj |
| 5 | [Sync_5_Costprice_From_BC.md](Sync_5_Costprice_From_BC.md) | ✅ Aktiv | ⭐⭐⭐⭐ Meget høj |
| 6 | [Sync_6_StockRegulations_DISABLED.md](Sync_6_StockRegulations_DISABLED.md) | ❌ Deaktiveret | ⭐ Lav |

---

### BC_UPDATEDATE Database Analyser

Dybtgående teknisk analyse af BC_UPDATEDATE feltet:

| Dokument | Type | Indhold |
|---|---|---|
| [BC_UPDATEDATE_Complete_Analysis.md](BC_UPDATEDATE_Complete_Analysis.md) | Database analyse | Alle triggers, complete verificering |
| [BC_UPDATEDATE_EasyPOSKontor_Analysis.md](BC_UPDATEDATE_EasyPOSKontor_Analysis.md) | Kodeanalyse | Installation scripts, trigger kode |
| [BC_UPDATEDATE_EasyPOSSalg_Search.md](BC_UPDATEDATE_EasyPOSSalg_Search.md) | Søgeresultater | Verifikation af ingen påvirkning |
| [BC_UPDATEDATE_Analysis.md](BC_UPDATEDATE_Analysis.md) | Initial analyse | Første fund fra database |

---

## 🎯 Hvem er Dette For?

### Udviklere ✅

**Brug dette til:**
- Implementering af nye synkroniseringer
- Ændring af eksisterende synkroniseringer
- Tilføjelse af nye felter
- Debugging af synkroniseringsfejl
- Database trigger vedligeholdelse

**Eksempel use cases:**
- "Jeg skal tilføje et nyt felt til vare-synkronisering"
- "Hvorfor fejler finanspost-synkronisering?"
- "Hvordan mapper jeg et nyt felt til BC?"

### Teknisk Support ✅

**Brug dette til:**
- Dybtgående fejlfinding
- SQL query analyse
- Database trigger kontrol
- API debugging
- Performance problemer

**Eksempel use cases:**
- "Kunde rapporterer duplikerede varer i BC"
- "Finansposter synkroniseres ikke"
- "BC_UPDATEDATE opdateres ikke automatisk"

### Slutbrugere ❌

**IKKE for slutbrugere!**

Hvis du er:
- Kassemedarbejder
- Butiksansvarlig
- Administrator (ikke-teknisk)

**→ Se i stedet: [../README.md](../README.md)**

---

## 📖 Dokumentstruktur

Alle Sync_X dokumenter følger samme struktur:

```
# Synkronisering X: Navn

## Formål
Hvad synkroniseres?

## Arbejdsflow
Step-by-step proces med beslutningslogik

## SQL Queries
Alle queries med:
- Parametre forklaret
- Vigtige filtre fremhævet
- Performance noter

## Data Mapping
Felt-til-felt tabeller:
| EasyPOS Felt | BC Felt | Type | Mapping | Note |

## Business Central API Calls
Request/Response eksempler med JSON

## Konfiguration
INI fil settings med forklaring

## Tracing Log
SLADREHANK ART koder

## Fejlhåndtering
Logfiler, error scenarios, email

## Specielle Situationer
Edge cases og special logic

## Performance
Optimering og kørselsider

## Debug Tips
Praktiske fejlfindingskommandoer

## Dependencies
Tabeller, procedures, endpoints

## Changelog
Versionshistorik
```

---

## 🛠️ Udviklerværktøjer

Denne mappe indeholder også værktøjer til database analyse:

### SQL Scripts

| Fil | Formål |
|---|---|
| `check_bc_updatedate.sql` | Hent alle triggers og field definitions for BC_UPDATEDATE |
| `get_bc_updatedate_details.sql` | Detaljeret info om triggers og stored procedures |
| `search_bc_updatedate_usage.sql` | Find alle referencer til BC_UPDATEDATE i database |

**Brug:**
```bash
isql -user SYSDBA -password masterkey server:database.fdb -i check_bc_updatedate.sql
```

### Database Tools

| Fil | Formål |
|---|---|
| `fbclient.dll` | Firebird client library til database forbindelse |
| `flamerobin_connection.txt` | Connection info til FlameRobin GUI tool |

---

## 🔍 Hurtig Reference

### SQL Query Locations

| Synkronisering | Source Fil | Linje(r) |
|---|---|---|
| Items (Varer) | UDM.dfm | 100-200 |
| Sales | UDM.dfm | 215-350 |
| Movements | UDM.dfm | 355-372 |
| Financial | UDM.dfm | 38-90 |
| Costprice | UDM.dfm | 750-839 |

### Database Triggers

| Trigger | Tabel | Dokumentation |
|---|---|---|
| VARER_BC_CHANGES | VARER | BC_UPDATEDATE_Complete_Analysis.md |
| VAREFRVSTR_BC_CHANGES | VAREFRVSTR | BC_UPDATEDATE_Complete_Analysis.md |
| INS_VAREFRVSTR | VAREFRVSTR | BC_UPDATEDATE_Complete_Analysis.md |

### Business Central Endpoints

| Endpoint | Retning | Dokumentation |
|---|---|---|
| kmItem | EP → BC | Sync_1_Items.md |
| kmItemSale | EP → BC | Sync_2_Sales.md |
| kmItemMove | EP → BC | Sync_3_Movements.md |
| kmCashstatement | EP → BC | Sync_4_Financial.md |
| kmCostprice | BC → EP | Sync_5_Costprice_From_BC.md |

---

## 🛠️ Development Workflow

### Tilføjelse af Nyt Felt til Synkronisering

**Eksempel: Tilføj "SEASON" felt til varer**

1. **Læs:** Sync_1_Items.md - forstå nuværende mapping

2. **Database trigger:**
   - Se: BC_UPDATEDATE_EasyPOSKontor_Analysis.md
   - Tilføj `(OLD.SEASON <> NEW.SEASON)` til VARER_BC_CHANGES

3. **SQL query:**
   - Opdater query i UDM.dfm
   - Tilføj `VARER.SEASON` til SELECT

4. **Data mapping:**
   - Opdater DoSyncronizeItems i UDM.pas
   - Map til BC felt (f.eks. `season`)

5. **Test:**
   - Opdater vare i EasyPOSKontor
   - Check BC_UPDATEDATE opdateres
   - Verificer synk til BC
   - Check BC data

6. **Dokumenter:**
   - Opdater Sync_1_Items.md
   - Opdater BC_UPDATEDATE_Complete_Analysis.md

---

## ⚠️ Advarsler

### Trigger Ændringer

**ALDRIG ændr triggers direkte i produktionsdatabase!**

Triggers skal ALTID ændres via:
1. EPOpdat12.pas (næste version)
2. Test i test-database først
3. Deploy via normal opdateringsproces

### SQL Performance

Alle queries er optimeret med indices.

Før ændring af queries:
- ✅ Check EXPLAIN PLAN
- ✅ Test med realistisk datamængde
- ✅ Monitor performance efter deploy

### Breaking Changes

Ved ændringer der kan bryde eksisterende:
- ⚠️ Notér i Changelog
- ⚠️ Test med eksisterende INI filer
- ⚠️ Tjek bagudkompatibilitet

---

## 📞 Support

**Ved tekniske spørgsmål:**

1. Check relevant dokumentation her
2. Review source kode (UDM.pas, UDM.dfm)
3. Check database (triggers, stored procedures)
4. Kontakt udviklingsteam med:
   - Logfiler
   - SQL traces
   - INI fil
   - Fejlbeskrivelse

---

**Sidst opdateret:** 2025-12-09  
**Dokumenter:** 10 filer  
**Total størrelse:** ~80 KB
