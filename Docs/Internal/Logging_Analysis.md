# Logging Analyse - EasyPOS to Business Central Service

**Dato:** 2025-12-09  
**Formål:** Analyse af Windows Service logging mekanismer

---

## Logging Mekanismer

Servicen bruger **3 forskellige logging systemer**:

### 1. **Fil-baseret Logging** (Primær)
- **Implementering:** `AddToLog()` og `AddToLogCostprice()`
- **Location:** Konfigurerbar via INI fil
- **Format:** Tekst filer med timestamp
- **Filnavne:** 
  - `LogYYYYMMDD.Txt` - Daglig general log
  - `Log_CostpriceYYYYMMDD.Txt` - Daglig kostpris log
  - `Error_*.txt` - Fejl logs

### 2. **Windows Event Log**
- **Implementering:** `WriteEventLog()` (uEventLogger.pas)
- **Source:** "EasyPOS Windows Service to sync. with Business Central"
- **Typer:** ERROR, WARNING, INFORMATION
- **Event IDs:** Se nedenfor

### 3. **Database Log** (EasyPOS)
- **Tabel:** `SLADREHANK` (Tracing log)
- **Tabel:** `WEBLOGEASYPOS` (Web/API log)
- **Formål:** Synkroniserings-historik synlig i EasyPOS

---

## Logging Niveauer

### ✅ **GOD LOGGING:**

#### **Startup & Initialization**
```delphi
AddToLog('EasyPOS Service to synconize data from EasyPOS to BUsiness Central: ' + Version);
AddToLog('It is time to run.');
AddToLog('INI file: ' + iniFile.FileName);
AddToLog('Database: ' + EasyPOS_Database);
AddToLog('Connecting to database');
AddToLog('Connected to database');
```

#### **Synkronisering Flow**
```delphi
AddToLog('DoSyncronizeItems - BEGIN');
AddToLog('  Fetching items from EasyPOS marked for BC export');
AddToLog(Format('  Item to transfer: %d - %s', [lCount, lJSONStr]));
AddToLog('DoSyncronizeItems - END');
```

#### **Fejlhåndtering**
```delphi
lErrotString := 'Unexpected error when inserting item in BC ' + #13#10 +
  '  EP ID: ' + QFetchItems.FieldByName('EPID').AsString + #13#10 +
  '  Code: ' + StatusCode.ToString + #13#10 +
  '  Message: ' + StatusText + #13#10 +
  '  JSON: ' + lJSONStr + #13#10;
AddToLog(lErrotString);
AddToErrorLog(lErrotString, lItemErrorFileName);
WriteEventLog(lErrotString, '', 'EasyPOS Windows Service...', EVENTLOG_ERROR_TYPE, EventID, 1);
```

---

## ⚠️ **MANGLER / FORBEDRINGSOMRÅDER:**

### 1. **Log Levels mangler**
```delphi
// NUVÆRENDE: Alt logges på samme niveau
AddToLog('Connecting to database');
AddToLog('Connected to database');
AddToLog('ERROR. Something failed');

// FORSLAG: Tilføj log levels
AddToLog('Connecting to database', LOG_DEBUG);
AddToLog('Connected to database', LOG_INFO);
AddToLog('ERROR. Something failed', LOG_ERROR);
```

**Problem:** Kan ikke filtrere logs efter vigtighed.

---

### 2. **Ingen Structured Logging**
```delphi
// NUVÆRENDE: String concatenation
AddToLog(Format('  Item to transfer: %d - %s', [lCount, lJSONStr]));

// FORSLAG: Structured data
AddToLog(LOG_INFO, 'ItemTransfer', {
  Count: lCount, 
  JSON: lJSONStr,
  ItemID: ItemID,
  TransactionID: TransID
});
```

**Problem:** Svært at parse logs automatisk for monitoring/alerting.

---

### 3. **Try-Except blokke swallower exceptions**
```delphi
// LINJE 340-351: AddToLog() metoden
procedure TDM.AddToLog(aStringToWriteToLogFile: String);
begin
  try
    // ... logging code ...
  except
    on E: Exception do
    begin
      // ❌ INGENTING! Exception er tabt!
    end;
  end;
end;
```

**Problem:** Hvis logging fejler, får man INGEN besked!

**Forslag:**
```delphi
except
  on E: Exception do
  begin
    // Fallback til Windows Event Log
    WriteEventLog('CRITICAL: Logging failed! ' + E.Message, '', 
      'EasyPOS Windows Service', EVENTLOG_ERROR_TYPE, 9999, 1);
  end;
end;
```

---

### 4. **Inkonsistent Error Logging**
```delphi
// Nogle steder:
AddToLog(lErrotString);
AddToErrorLog(lErrotString, lItemErrorFileName);
WriteEventLog(lErrotString, '', ..., EVENTLOG_ERROR_TYPE, ...);
SendErrorMail(...);

// Andre steder:
AddToLog('ERROR. Something failed');
// ❌ Ingen Windows Event Log
// ❌ Ingen error file
// ❌ Ingen email
```

**Problem:** Uforudsigelig fejlhåndtering.

**Forslag:** Lav en `LogError()` metode:
```delphi
procedure LogError(ErrorMsg: string; ErrorFile: string; EventID: integer; SendMail: Boolean);
begin
  AddToLog('ERROR: ' + ErrorMsg);
  AddToErrorLog(ErrorMsg, ErrorFile);
  WriteEventLog(ErrorMsg, '', 'EasyPOS Service', EVENTLOG_ERROR_TYPE, EventID, 1);
  if SendMail then
    SendErrorMail(LogFileFolder + ErrorFile, 'Error', ErrorMsg);
end;
```

---

### 5. **Sensitive Data i Logs**
```delphi
// LINJE 3513: Password logges!!!
AddToLog('User: xxx');      // ✅ Masked
AddToLog('Password: xxx');  // ✅ Masked
```

✅ **Dette er godt!** Men tjek også:

```delphi
// LINJE 646-651: Business Central credentials
AddToLog('  LF_BC_USERNAME: ' + LF_BC_USERNAME);
AddToLog('  LF_BC_PASSWORD: ' + LF_BC_PASSWORD);  // ❌ SENSITIVE!
```

**Problem:** BC password logges i klar tekst!

**Fix:** 
```delphi
AddToLog('  LF_BC_USERNAME: ' + LF_BC_USERNAME);
AddToLog('  LF_BC_PASSWORD: ' + MaskPassword(LF_BC_PASSWORD));  // '****'
```

---

### 6. **Manglende Correlation ID**
```delphi
// NUVÆRENDE: Svært at følge en synkronisering gennem logs
AddToLog('DoSyncronizeItems - BEGIN');
AddToLog('  Fetching items...');
// ... 100 linjer senere ...
AddToLog('DoSyncronizeItems - END');

// Hvis flere synkroniseringer kører samtidigt (teoretisk), 
// er logs blandet sammen
```

**Forslag:**
```delphi
var CorrelationID: TGUID;
CreateGUID(CorrelationID);
AddToLog(Format('[%s] DoSyncronizeItems - BEGIN', [GUIDToString(CorrelationID)]));
```

---

### 7. **Ingen Performance Metrics**
```delphi
// MANGLER: Hvor lang tid tager hver synkronisering?
// MANGLER: Hvor mange items synkroniseres per sekund?
// MANGLER: Database query performance
```

**Forslag:**
```delphi
var StartTime: TDateTime;
StartTime := Now;
// ... do work ...
AddToLog(Format('DoSyncronizeItems completed in %d ms. Items: %d', 
  [MilliSecondsBetween(Now, StartTime), ItemCount]));
```

---

## Windows Event Log - Event IDs

### Items Synkronisering (1000-1099)
- **1001** - Item export success
- **1002** - Item export error
- **1099** - Items general error

### Sales Transactions (3200-3299)
- **3201** - Mark exported error
- **3202** - Insert error
- **3203** - Check error
- **3299** - General error

### Movements (3300-3399)
- **3301** - Mark exported error
- **3302** - Insert error
- **3303** - Check error
- **3399** - General error

### Financial (3400-3499)
- **3401** - Mark exported error
- **3402** - Insert error
- **3403** - Check error
- **3499** - General error

### Costprice (3500-3599)
- **3503** - Fetch costprice error
- **3599** - General error

### System (9000+)
- **9999** - Critical logging failure (FORSLAG)

---

## Log Rotation

### ✅ **GODT: Automatisk oprydning**
```delphi
procedure TDM.DoClearFolder(aFolder: string; aFile: string);
const
  NumberOfDays = 21;
begin
  // Sletter filer ældre end 21 dage
  if (sr.TimeStamp < NOW - NumberOfDays) then
    DeleteFile(PChar(lFilSti + sr.Name));
end;
```

### ⚠️ **MULIGT PROBLEM:**
- Hvad hvis `DoClearFolder` fejler?
- Ingen check på disk plads
- Ingen arkivering før sletning

---

## Email Notifikationer

### ✅ **GODT:**
```delphi
// 503 (Service Unavailable) håndtering
if FLastStatusCode = 503 then
  lDoSendMail := TRUE;  // Send email ved BC overload
```

### ⚠️ **PROBLEM:**
```delphi
// LINJE 221: Sender ALTID email ved 503
// Kan give email spam hvis BC er nede længe
```

**Forslag:**
```delphi
if FLastStatusCode = 503 then
begin
  if FLastDateTimeForStatusCode503 < (NOW - EncodeTime(1, 0, 0, 0)) then
  begin
    // Kun send email hvis > 1 time siden sidste 503
    lDoSendMail := TRUE;
  end;
end;
```

---

## Database Logging (SLADREHANK)

### ✅ **GODT: Brugervenlig historik**
```delphi
InsertTracingLog(5, lFromDateAndTime, lToDateAndTime, BC_TransactionID);
// ART 3005: "Eksport af vare til Business Central OK (Service)"
// Synlig i EasyPOSKontor for brugere
```

### Tracing Log Art Codes:
- **3001** - Vare export OK
- **3002** - Vare export ERROR
- **3005** - Salg synk OK
- **3006** - Salg synk ERROR
- **3011** - Flytning synk OK
- **3012** - Flytning synk ERROR
- **3015** - Finans synk OK
- **3016** - Finans synk ERROR

---

## WEBLOGEASYPOS Logging

```delphi
procedure DoInsertEasyPOSLog(aLog: String);
begin
  INS_WEBLogEasyPOS.ParamByName('HVAD').AsString := 'EasyPOS to BC Windows Service';
  INS_WEBLogEasyPOS.ParamByName('HVEM').AsString := 'EasyPOS to BC Windows Service';
  INS_WEBLogEasyPOS.ParamByName('HVOR').AsString := 'EasyPOS to BC Windows Service';
  INS_WEBLogEasyPOS.ParamByName('DATO_STEMPEL').AsDateTime := NOW;
  INS_WEBLogEasyPOS.ParamByName('SQLSETNING').AsString := aLog;
  INS_WEBLogEasyPOS.ExecSQL;
end;
```

### ⚠️ **PROBLEM:**
- Alle felter har samme værdi ("EasyPOS to BC Windows Service")
- `SQLSETNING` bruges til log text (misvisende navn)
- Ingen skelnen mellem forskellige operationer

---

## Anbefalinger

### 🎯 **KRITISKE FIXES:**

1. **Fix try-except i AddToLog()**
   ```delphi
   except
     on E: Exception do
       WriteEventLog('CRITICAL: Logging failed! ' + E.Message, '', ...);
   end;
   ```

2. **Mask BC Password i logs**
   ```delphi
   AddToLog('  LF_BC_PASSWORD: ****');
   ```

3. **Konsistent error logging**
   ```delphi
   procedure LogError(ErrorMsg, ErrorFile: string; EventID: integer; SendMail: Boolean);
   ```

### 💡 **FORBEDRINGER:**

4. **Tilføj log levels**
   - DEBUG, INFO, WARNING, ERROR, CRITICAL

5. **Performance metrics**
   ```delphi
   AddToLog(Format('Completed in %d ms. Items: %d', [Duration, Count]));
   ```

6. **Correlation IDs**
   ```delphi
   AddToLog(Format('[%s] DoSyncronizeItems - BEGIN', [CorrelationID]));
   ```

7. **Structured logging**
   - JSON format for maskinlæsbarhed
   - Lettere monitoring/alerting

8. **503 Email throttling**
   - Max 1 email per time ved BC overload

---

## Konklusion

### ✅ **STYRKER:**
- Grundlæggende logging er på plads
- God fejlhåndtering med multiple outputs (file, event log, database)
- Automatisk log rotation
- Email notifikationer ved fejl
- Brugervenlig database historik (SLADREHANK)

### ⚠️ **SVAGHEDER:**
- **KRITISK:** Try-except swallower logging exceptions
- **KRITISK:** BC password logges i klar tekst
- Ingen log levels (DEBUG/INFO/ERROR)
- Ingen structured logging
- Ingen performance metrics
- Inkonsistent error logging
- Email spam risiko ved 503 errors

### 📊 **SAMLET VURDERING:**
**6/10 - Acceptabel men kan forbedres**

Logging er funktionel til debugging, men mangler enterprise-grade features som:
- Log levels
- Correlation tracking
- Performance monitoring
- Consistent error handling
- Security (password masking)

---

## Næste Skridt

1. ✅ Implementer kritiske fixes (password masking, logging exception handling)
2. 💡 Overvej structured logging framework (JSON format)
3. 💡 Tilføj performance metrics
4. 💡 Implementer log levels
5. 💡 Centraliser error logging i én metode
