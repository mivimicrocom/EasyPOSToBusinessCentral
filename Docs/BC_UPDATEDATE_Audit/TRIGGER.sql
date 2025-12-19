/* ============================================================================
   BC_UPDATEDATE Audit Trigger
   
   Formål: Logger ALLE ændringer til BC_UPDATEDATE i WEB_SLADREHANK
   
   Hvornår logger:
   - Direkte opdatering af BC_UPDATEDATE
   - Indirekte via VARER_BC_CHANGES trigger (VARENAVN1, MODEL, etc.)
   - Via variant-ændringer (VAREFRVSTR_BC_CHANGES trigger)
   - Ved ny variant (INS_VAREFRVSTR trigger)
   
   Installation:
   1. Verificer at WEB_SLADREHANK tabel eksisterer
   2. Kør denne script
   3. Test med: UPDATE VARER SET VARENAVN1 = 'Test' WHERE PLU_NR = '12345';
   4. Check: SELECT * FROM WEB_SLADREHANK WHERE HVAD = 'BC UpdateDate changed' 
             ORDER BY DATO_STEMPEL DESC;
   
   Dato: 18. december 2025
   ============================================================================ */

SET TERM ^ ;

CREATE OR ALTER TRIGGER VARER_BC_UPDATEDATE_LOG FOR VARER
ACTIVE AFTER UPDATE POSITION 31
AS
DECLARE VARIABLE L_APP_NAME VARCHAR(50);
DECLARE VARIABLE L_AUDIT_MSG VARCHAR(8000);
BEGIN
  /* Only log if BC_UPDATEDATE actually changed */
  IF (OLD.BC_UPDATEDATE IS DISTINCT FROM NEW.BC_UPDATEDATE) THEN
  BEGIN
    
    /* Try to get application name from monitoring table */
    /* MON$REMOTE_PROCESS can be up to 255 chars, but HVOR is only 50 */
    SELECT FIRST 1 RIGHT(MON$REMOTE_PROCESS, 50)
    FROM MON$ATTACHMENTS 
    WHERE MON$ATTACHMENT_ID = CURRENT_CONNECTION
    INTO :L_APP_NAME;
    
    /* Default to 'Unknown' if not found */
    IF (L_APP_NAME IS NULL) THEN
      L_APP_NAME = 'Unknown';
    
    /* Build English audit message with line breaks for readability */
    /* Use ASCII_CHAR for Firebird 3 Dialect 1 compatibility */
    L_AUDIT_MSG = 
        'User ' || CURRENT_USER || 
        ' at ' || CAST(CURRENT_TIMESTAMP AS VARCHAR(30)) || ASCII_CHAR(13) || ASCII_CHAR(10) ||
        'from connection ' || L_APP_NAME || ASCII_CHAR(13) || ASCII_CHAR(10) ||
        'changed BC_UPDATEDATE on item ' || NEW.PLU_NR || ASCII_CHAR(13) || ASCII_CHAR(10) ||
        'from ' || CAST(OLD.BC_UPDATEDATE AS VARCHAR(30)) || ASCII_CHAR(13) || ASCII_CHAR(10) ||
        'to ' || CAST(NEW.BC_UPDATEDATE AS VARCHAR(30));
    
    /* Insert audit record (ID auto-increments) */
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

SET TERM ; ^

/* Test queries after installation:

   -- Test 1: Update a product
   UPDATE VARER SET VARENAVN1 = 'Test' WHERE PLU_NR = '12345';
   
   -- Test 2: Check log
   SELECT * FROM WEB_SLADREHANK
   WHERE HVAD = 'BC UpdateDate changed'
   ORDER BY DATO_STEMPEL DESC
   FETCH FIRST 1 ROW ONLY;
   
   -- Test 3: Verify trigger is active
   SELECT RDB$TRIGGER_NAME, RDB$TRIGGER_INACTIVE
   FROM RDB$TRIGGERS
   WHERE RDB$TRIGGER_NAME = 'VARER_BC_UPDATEDATE_LOG';
   
   Expected: RDB$TRIGGER_INACTIVE = 0 (active)
*/

COMMIT;
