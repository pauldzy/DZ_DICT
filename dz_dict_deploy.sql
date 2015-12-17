
--*************************--
PROMPT sqlplus_header.sql;

WHENEVER SQLERROR EXIT -99;
WHENEVER OSERROR  EXIT -98;
SET DEFINE OFF;



--*************************--
PROMPT DZ_DICT_ORACLE_OBJECT.tps;

CREATE OR REPLACE TYPE dz_dict_oracle_object FORCE
AUTHID CURRENT_USER
AS OBJECT (
    owner_name           VARCHAR2(30 Char)
   ,object_name          VARCHAR2(30 Char)
   ,object_type          VARCHAR2(4000 Char)
    
   ,CONSTRUCTOR FUNCTION dz_dict_oracle_object
    RETURN SELF AS RESULT

);
/

GRANT EXECUTE ON dz_dict_oracle_object TO PUBLIC;


--*************************--
PROMPT DZ_DICT_ORACLE_OBJECT.tpb;

CREATE OR REPLACE TYPE BODY dz_dict_oracle_object
AS

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   CONSTRUCTOR FUNCTION dz_dict_oracle_object
   RETURN SELF AS RESULT
   AS
   BEGIN
      RETURN;
      
   END dz_dict_oracle_object;
 
END;
/


--*************************--
PROMPT DZ_DICT_ORACLE_OBJECT_LIST.tps;

CREATE OR REPLACE TYPE dz_dict_oracle_object_list FORCE             
AS 
TABLE OF dz_dict_oracle_object;
/

GRANT EXECUTE ON dz_dict_oracle_object_list TO PUBLIC;


--*************************--
PROMPT DZ_DICT_UTIL.pks;

CREATE OR REPLACE PACKAGE dz_dict_util
AUTHID CURRENT_USER
AS

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION get_guid
   RETURN VARCHAR2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION gz_split(
       p_str              IN  VARCHAR2
      ,p_regex            IN  VARCHAR2
      ,p_match            IN  VARCHAR2 DEFAULT NULL
      ,p_end              IN  NUMBER   DEFAULT 0
      ,p_trim             IN  VARCHAR2 DEFAULT 'FALSE'
   ) RETURN MDSYS.SDO_STRING2_ARRAY DETERMINISTIC;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION safe_to_number(
       p_input            IN  VARCHAR2
      ,p_null_replacement IN  NUMBER DEFAULT NULL
   ) RETURN NUMBER;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION strings2numbers(
      p_input             IN  MDSYS.SDO_STRING2_ARRAY
   ) RETURN MDSYS.SDO_NUMBER_ARRAY;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION unique_name(
       p_prefix           IN  VARCHAR2 DEFAULT NULL
      ,p_suffix           IN  VARCHAR2 DEFAULT NULL
   ) RETURN VARCHAR2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION scrunch_name(
       p_input            IN  VARCHAR2
      ,p_max_length       IN  NUMBER   DEFAULT 26
      ,p_method           IN  VARCHAR2 DEFAULT 'SUBSTR'
   ) RETURN VARCHAR2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE parse_schema(
       p_input            IN  VARCHAR2
      ,p_schema           OUT VARCHAR2
      ,p_object_name      OUT VARCHAR2
   );
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION has_schema_prefix(
      p_input             IN  VARCHAR2
   ) RETURN VARCHAR2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION utl_url_escape(
       p_input_url        IN  VARCHAR2 CHARACTER SET ANY_CS
      ,p_escape_reserved  IN  VARCHAR2 DEFAULT NULL
      ,p_url_charset      IN  VARCHAR2 DEFAULT NULL
   ) RETURN VARCHAR2 CHARACTER SET p_input_url%CHARSET;
     
END dz_dict_util;
/

GRANT EXECUTE ON dz_dict_util TO public;


--*************************--
PROMPT DZ_DICT_UTIL.pkb;

CREATE OR REPLACE PACKAGE BODY dz_dict_util
AS

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION get_guid
   RETURN VARCHAR2
   AS
      str_sysguid VARCHAR2(40 Char);
      
   BEGIN
   
      str_sysguid := UPPER(RAWTOHEX(SYS_GUID()));
      
      RETURN '{' 
         || SUBSTR(str_sysguid,1,8)  || '-'
         || SUBSTR(str_sysguid,9,4)  || '-'
         || SUBSTR(str_sysguid,13,4) || '-'
         || SUBSTR(str_sysguid,17,4) || '-'
         || SUBSTR(str_sysguid,21,12)|| '}';
   
   END get_guid;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION gz_split(
       p_str              IN VARCHAR2
      ,p_regex            IN VARCHAR2
      ,p_match            IN VARCHAR2 DEFAULT NULL
      ,p_end              IN NUMBER   DEFAULT 0
      ,p_trim             IN VARCHAR2 DEFAULT 'FALSE'
   ) RETURN MDSYS.SDO_STRING2_ARRAY DETERMINISTIC 
   AS
      int_delim      PLS_INTEGER;
      int_position   PLS_INTEGER := 1;
      int_counter    PLS_INTEGER := 1;
      ary_output     MDSYS.SDO_STRING2_ARRAY;
      num_end        NUMBER := p_end;
      str_trim       VARCHAR2(5 Char) := UPPER(p_trim);
      
      FUNCTION trim_varray(
         p_input            IN MDSYS.SDO_STRING2_ARRAY
      ) RETURN MDSYS.SDO_STRING2_ARRAY
      AS
         ary_output MDSYS.SDO_STRING2_ARRAY := MDSYS.SDO_STRING2_ARRAY();
         int_index  PLS_INTEGER := 1;
         str_check  VARCHAR2(4000 Char);
         
      BEGIN

         --------------------------------------------------------------------------
         -- Step 10
         -- Exit if input is empty
         --------------------------------------------------------------------------
         IF p_input IS NULL
         OR p_input.COUNT = 0
         THEN
            RETURN ary_output;
            
         END IF;

         --------------------------------------------------------------------------
         -- Step 20
         -- Trim the strings removing anything utterly trimmed away
         --------------------------------------------------------------------------
         FOR i IN 1 .. p_input.COUNT
         LOOP
            str_check := TRIM(p_input(i));
            
            IF str_check IS NULL
            OR str_check = ''
            THEN
               NULL;
               
            ELSE
               ary_output.EXTEND(1);
               ary_output(int_index) := str_check;
               int_index := int_index + 1;
               
            END IF;

         END LOOP;

         --------------------------------------------------------------------------
         -- Step 10
         -- Return the results
         --------------------------------------------------------------------------
         RETURN ary_output;

      END trim_varray;

   BEGIN

      --------------------------------------------------------------------------
      -- Step 10
      -- Create the output array and check parameters
      --------------------------------------------------------------------------
      ary_output := MDSYS.SDO_STRING2_ARRAY();

      IF str_trim IS NULL
      THEN
         str_trim := 'FALSE';
         
      ELSIF str_trim NOT IN ('TRUE','FALSE')
      THEN
         RAISE_APPLICATION_ERROR(-20001,'boolean error');
         
      END IF;

      IF num_end IS NULL
      THEN
         num_end := 0;
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 20
      -- Exit early if input is empty
      --------------------------------------------------------------------------
      IF p_str IS NULL
      OR p_str = ''
      THEN
         RETURN ary_output;
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 30
      -- Account for weird instance of pure character breaking
      --------------------------------------------------------------------------
      IF p_regex IS NULL
      OR p_regex = ''
      THEN
         FOR i IN 1 .. LENGTH(p_str)
         LOOP
            ary_output.EXTEND(1);
            ary_output(i) := SUBSTR(p_str,i,1);
            
         END LOOP;
         
         RETURN ary_output;
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 40
      -- Break string using the usual REGEXP functions
      --------------------------------------------------------------------------
      LOOP
         EXIT WHEN int_position = 0;
         int_delim  := REGEXP_INSTR(p_str,p_regex,int_position,1,0,p_match);
         
         IF  int_delim = 0
         THEN
            -- no more matches found
            ary_output.EXTEND(1);
            ary_output(int_counter) := SUBSTR(p_str,int_position);
            int_position  := 0;
            
         ELSE
            IF int_counter = num_end
            THEN
               -- take the rest as is
               ary_output.EXTEND(1);
               ary_output(int_counter) := SUBSTR(p_str,int_position);
               int_position  := 0;
               
            ELSE
               --dbms_output.put_line(ary_output.COUNT);
               ary_output.EXTEND(1);
               ary_output(int_counter) := SUBSTR(p_str,int_position,int_delim-int_position);
               int_counter := int_counter + 1;
               int_position := REGEXP_INSTR(p_str,p_regex,int_position,1,1,p_match);
               
            END IF;
            
         END IF;
         
      END LOOP;

      --------------------------------------------------------------------------
      -- Step 50
      -- Trim results if so desired
      --------------------------------------------------------------------------
      IF str_trim = 'TRUE'
      THEN
         RETURN trim_varray(
            p_input => ary_output
         );
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 60
      -- Cough out the results
      --------------------------------------------------------------------------
      RETURN ary_output;
      
   END gz_split;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION safe_to_number(
       p_input            IN VARCHAR2
      ,p_null_replacement IN NUMBER DEFAULT NULL
   ) RETURN NUMBER
   AS
   BEGIN
      RETURN TO_NUMBER(
         REPLACE(
            REPLACE(
               p_input,
               CHR(10),
               ''
            ),
            CHR(13),
            ''
         ) 
      );
      
   EXCEPTION
      WHEN VALUE_ERROR
      THEN
         RETURN p_null_replacement;
         
   END safe_to_number;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION strings2numbers(
      p_input            IN MDSYS.SDO_STRING2_ARRAY
   ) RETURN MDSYS.SDO_NUMBER_ARRAY
   AS
      ary_output MDSYS.SDO_NUMBER_ARRAY := MDSYS.SDO_NUMBER_ARRAY();
      num_tester NUMBER;
      int_index  PLS_INTEGER := 1;

   BEGIN

      --------------------------------------------------------------------------
      -- Step 10
      -- Exit if input is empty
      --------------------------------------------------------------------------
      IF p_input IS NULL
      OR p_input.COUNT = 0
      THEN
         RETURN ary_output;
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 20
      -- Convert anything that is a valid number to a number, dump the rest
      --------------------------------------------------------------------------
      FOR i IN 1 .. p_input.COUNT
      LOOP
         IF p_input(i) IS NOT NULL
         THEN
            num_tester := safe_to_number(
               p_input => p_input(i)
            );
            
            IF num_tester IS NOT NULL
            THEN
               ary_output.EXTEND();
               ary_output(int_index) := num_tester;
               int_index := int_index + 1;
            END IF;
            
         END IF;
         
      END LOOP;

      RETURN ary_output;

   END strings2numbers;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION unique_name(
       p_prefix          IN  VARCHAR2 DEFAULT NULL
      ,p_suffix          IN  VARCHAR2 DEFAULT NULL
   ) RETURN VARCHAR2
   AS
      str_seq    VARCHAR2(4000 Char);
      num_random NUMBER;

   BEGIN

      num_random := DBMS_RANDOM.RANDOM;
      str_seq := TO_CHAR(SYS_CONTEXT('USERENV', 'SESSIONID'));

      IF p_prefix IS NOT NULL
      THEN
         str_seq := p_prefix || str_seq;
         IF LENGTH(str_seq) > 27
         THEN
            str_seq := SUBSTR(str_seq,-27);
            RETURN 'DZ' || str_seq || 'X';
            
         END IF;
         
      END IF;

      IF p_suffix IS NOT NULL
      THEN
         str_seq := str_seq || p_suffix;
         IF LENGTH(str_seq) > 27
         THEN
            str_seq := SUBSTR(str_seq,1,27);
            RETURN 'DZ' || str_seq || 'X';
            
         END IF;
         
      END IF;

      str_seq := str_seq || TO_CHAR(REPLACE(num_random,'-',''));
      
      IF LENGTH(str_seq) > 27
      THEN
        str_seq := SUBSTR(str_seq,1,27);
        
      END IF;

      RETURN 'DZ' || str_seq || 'X';

   END unique_name;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION scrunch_name(
       p_input       IN  VARCHAR2
      ,p_max_length  IN  NUMBER DEFAULT 26
      ,p_method      IN  VARCHAR2 DEFAULT 'SUBSTR'
   ) RETURN VARCHAR2
   AS
      num_max_length NUMBER := p_max_length;
      str_input      VARCHAR2(4000 Char) := UPPER(p_input);
      str_method     VARCHAR2(4000 Char) := p_method;
      str_temp       VARCHAR2(4000 Char);
      
      FUNCTION drop_vowel(
         p_input   IN  VARCHAR2
      ) RETURN VARCHAR2
      AS
         str_input VARCHAR2(4000 Char) := p_input;
         str_temp  VARCHAR2(4000 Char);
         
      BEGIN
      
         str_temp := REGEXP_REPLACE(
             str_input
            ,'[AEIOU]([^A^E^I^O^U]*$)'
            ,'\1'
            ,1
            ,1
         );
         
         IF LENGTH(str_temp) = LENGTH(str_input) - 1
         THEN
            IF SUBSTR(str_input,1,1) IN ('A','E','I','O','U') AND 
            SUBSTR(str_temp,1,1) NOT IN ('A','E','I','O','U')
            THEN
               NULL;
               
            ELSE
               RETURN str_temp;
               
            END IF;
            
         END IF;

         RETURN p_input;
         
      END drop_vowel;
      
   BEGIN
   
      IF num_max_length IS NULL
      THEN
         num_max_length := 26;
         
      END IF;
      
      IF str_method IS NULL
      THEN
         str_method := 'SUBSTR';
         
      END IF; 

      IF LENGTH(str_input) <= num_max_length
      THEN
         RETURN str_input;
         
      END IF;
      
      IF str_method = 'SUBSTR'
      THEN
         RETURN SUBSTR(str_input,1,num_max_length);
         
      ELSIF str_method = 'VOWELS'
      THEN
         str_temp := str_input;
         
         FOR i IN num_max_length .. LENGTH(str_input) - 1
         LOOP
            
            str_temp := drop_vowel(str_temp);
            
         END LOOP;
         
         IF LENGTH(str_temp) <= num_max_length
         THEN
            RETURN str_temp;
            
         END IF;
         
         str_temp := REPLACE(str_temp,'_','');
         RETURN SUBSTR(str_temp,1,num_max_length);
         
      ELSE
         RAISE_APPLICATION_ERROR(-20001,'err');
         
      END IF;  
      
   END scrunch_name;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE parse_schema(
       p_input                IN  VARCHAR2
      ,p_schema               OUT VARCHAR2
      ,p_object_name          OUT VARCHAR2
   )
   AS
      ary_parts MDSYS.SDO_STRING2_ARRAY;
      
   BEGIN

      IF p_input IS NULL
      THEN
         RAISE_APPLICATION_ERROR(-20001,'input to procedure cannot be NULL');
         
      END IF;

      ary_parts := gz_split(
         p_str   => p_input,
         p_regex => '\.'
      );

      IF ary_parts.COUNT = 1
      THEN
         p_schema      := USER;
         p_object_name := UPPER(ary_parts(1));
         
      ELSIF ary_parts.COUNT = 2
      THEN
         p_schema      := UPPER(ary_parts(1));
         p_object_name := UPPER(ary_parts(2));
         
      ELSE
         RAISE_APPLICATION_ERROR(-20001,'cannot parse out schema from ' || p_input);
         
      END IF;

   END parse_schema;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION has_schema_prefix(
      p_input            IN  VARCHAR2
   ) RETURN VARCHAR2
   AS
      ary_parts MDSYS.SDO_STRING2_ARRAY;
      
   BEGIN
   
      IF p_input IS NULL
      THEN
         RAISE_APPLICATION_ERROR(-20001,'input to procedure cannot be NULL');
         
      END IF;

      ary_parts := gz_split(
         p_str   => p_input,
         p_regex => '\.'
      );

      IF ary_parts.COUNT = 1
      THEN
         RETURN 'FALSE';
         
      ELSIF ary_parts.COUNT = 2
      THEN
         RETURN 'TRUE';
         
      ELSE
         RAISE_APPLICATION_ERROR(-20001,'cannot parse out schema from ' || p_input);
         
      END IF;

   END has_schema_prefix;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION utl_url_escape(
       p_input_url       IN VARCHAR2 CHARACTER SET ANY_CS
      ,p_escape_reserved IN VARCHAR2 DEFAULT NULL
      ,p_url_charset     IN VARCHAR2 DEFAULT NULL
   )  RETURN VARCHAR2 CHARACTER SET p_input_url%CHARSET
   AS
      str_escape_reserved VARCHAR2(4000 Char) := UPPER(p_escape_reserved);
      boo_escape_reserved BOOLEAN;
      str_url_charset     VARCHAR2(4000 Char) := p_url_charset;

   BEGIN

      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF str_escape_reserved IS NULL
      THEN
         boo_escape_reserved := FALSE;
         
      ELSIF str_escape_reserved = 'TRUE'
      THEN
         boo_escape_reserved := TRUE;
         
      ELSIF str_escape_reserved = 'FALSE'
      THEN
         boo_escape_reserved := FALSE;
         
      ELSE
         RAISE_APPLICATION_ERROR(-20001,'boolean error');
         
      END IF;

      IF str_url_charset IS NULL
      THEN
         str_url_charset := utl_http.get_body_charset;
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 20
      -- Return results
      --------------------------------------------------------------------------
      RETURN SYS.UTL_URL.ESCAPE(
         p_input_url,
         boo_escape_reserved,
         str_url_charset
      );

   END utl_url_escape;
   
END dz_dict_util;
/


--*************************--
PROMPT DZ_DICT_MAIN.pks;

CREATE OR REPLACE PACKAGE dz_dict_main
AUTHID CURRENT_USER
AS
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   header: DZ_DICT
     
   - Build ID: 4
   - TFS Change Set: 8297
   
   Utilities for the manipulation of the Oracle data dictionary.
   
   */
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Procedure: dz_dict_main.drop_type_quietly

   Utility function which drops a type without returning an error if the type
   does not exist.   

   Parameters:

      p_owner - optional owner of the type, default is current user.
      p_type_name - name of type to drop.
      
   Returns:

      Nothing

   */
   PROCEDURE drop_type_quietly(
       p_owner            IN  VARCHAR2 DEFAULT NULL
      ,p_type_name        IN  VARCHAR2
   );

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Procedure: dz_dict_main.drop_table_quietly

   Utility function which drops a table without returning an error if the table 
   not exist.   

   Parameters:

      p_owner - optional owner of the table, default is current user.
      p_table_name - name of table to drop.
      
   Returns:

      Nothing

   */
   PROCEDURE drop_table_quietly (
       p_owner            IN  VARCHAR2 DEFAULT NULL
      ,p_table_name       IN  VARCHAR2
   );
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_dict_main.table_exists

   Utility function to determine if a table (or view) exists and is selectable.
   Test may also include one or more column names as part of the test.   

   Parameters:

      p_owner - optional owner of the table or view, default is current user.
      p_table_name - name of table or view to verify
      p_column_name - optional column name or names to verify is part of table 
      in question
      
   Returns:

      TRUE or FALSE as VARCHAR2 text string

   */
   FUNCTION table_exists(
       p_owner            IN  VARCHAR2 DEFAULT NULL
      ,p_table_name       IN  VARCHAR2
      ,p_column_name      IN  VARCHAR2 DEFAULT NULL
   ) RETURN VARCHAR2;

   FUNCTION table_exists(
       p_owner            IN  VARCHAR2 DEFAULT NULL
      ,p_table_name       IN  VARCHAR2
      ,p_column_name      IN  MDSYS.SDO_STRING2_ARRAY
   ) RETURN VARCHAR2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_dict_main.tables_exists

   Utility function to determine if one or more tables exist in a given schema.  

   Parameters:

      p_owner - optional owner of the tables or views, default is current user.
      p_table_names - array of table names or views to verify
      
   Returns:

      TRUE or FALSE as VARCHAR2 text string
      
   */
   FUNCTION tables_exists(
       p_owner            IN  VARCHAR2 DEFAULT NULL
      ,p_table_names      IN  MDSYS.SDO_STRING2_ARRAY
   ) RETURN VARCHAR2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_dict_main.mview_exists

   Utility function to determine if a materialized view exists in a given schema.  

   Parameters:

      p_owner - optional owner of the materialized view, default is current user.
      p_mview_name - materialized view name to verify
      
   Returns:

      TRUE or FALSE as VARCHAR2 text string
      
   */
   FUNCTION mview_exists(
       p_owner            IN  VARCHAR2 DEFAULT NULL
      ,p_mview_name       IN  VARCHAR2
   ) RETURN VARCHAR2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_dict_main.tablespace_exists

   Utility function to determine if a tablespace exists.  

   Parameters:

      p_tablespace_name - tablespace name to verify
      
   Returns:

      TRUE or FALSE as VARCHAR2 text string
      
   */
   FUNCTION tablespace_exists(
      p_tablespace_name   IN  VARCHAR2
   ) RETURN VARCHAR2;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_dict_main.table_privileges

   Utility function to dump the privledges you currently have on the provided
   table.  

   Parameters:

      p_owner - optional owner of the table or view, default is current user.
      p_table_name - table or view name to verify
      
   Returns:

      MDSYS.SDO_STRING2_ARRAY of privledges as text strings.
      
   */
   FUNCTION table_privileges(
       p_owner            IN  VARCHAR2 DEFAULT NULL
      ,p_table_name       IN  VARCHAR2
   ) RETURN MDSYS.SDO_STRING2_ARRAY;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_dict_main.table_privileges_dml

   Utility function to determine if user has full SELECT, UPDATE, INSERT and
   DELETE rights on a given table.  

   Parameters:

      p_owner - optional owner of the table or view, default is current user.
      p_table_name - table or view name to verify
      
   Returns:

      TRUE or FALSE as VARCHAR2 text string
      
   */
   FUNCTION table_privileges_dml(
       p_owner            IN  VARCHAR2 DEFAULT NULL
      ,p_table_name       IN  VARCHAR2
   ) RETURN VARCHAR2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_dict_main.sequence_exists

   Utility function to determine if a sequence exists in a given schema.  

   Parameters:

      p_owner - optional owner of the sequence, default is current user.
      p_sequence_name - sequence name to verify
      
   Returns:

      TRUE or FALSE as VARCHAR2 text string
      
   */
   FUNCTION sequence_exists(
       p_owner            IN  VARCHAR2 DEFAULT NULL
      ,p_sequence_name    IN  VARCHAR2
   ) RETURN VARCHAR2;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Procedure: dz_dict_main.drop_sequence

   Utility to drop one or more sequences matching a name value either exactly or
   via wildcard LIKE selection.   

   Parameters:

      p_owner - optional owner of the sequences, default is current user.
      p_sequence_name - sequence name or wilcard value to verify
      p_like_flag - optional flag to trigger LIKE verse equals sequence name matching.
      
   Returns:

      Nothing
      
   */
   PROCEDURE drop_sequence(
       p_owner            IN  VARCHAR2 DEFAULT NULL
      ,p_sequence_name    IN  VARCHAR2
      ,p_like_flag        IN  VARCHAR2 DEFAULT 'FALSE'
   );
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Procedure: dz_dict_main.sequence_from_max_column

   Utility to generate a sequence with a "start with" value equal to the next integer
   value in an existing table and column.   

   Parameters:

      p_owner - optional owner of the table, default is current user.
      p_table_name  - table name containing the column to interrogate
      p_column_name - column name to interrogate to determine the sequence start
      with value.
      p_sequence_owner - optional owner of the new sequence, default is current user.
      p_sequence_name - name of the sequence to create.  If NULL is provided then this
      value will contain a randomly generated name used for resulting sequence.
      
   Returns:

      Nothing
      
   Notes:
   
      - Random sequence name created using dz_dict_util.unique_name() function.
      
      - If source table is empty, the sequence is create with a start with value of 1.
      
   */
   PROCEDURE sequence_from_max_column(
       p_owner            IN  VARCHAR2 DEFAULT NULL
      ,p_table_name       IN  VARCHAR2
      ,p_column_name      IN  VARCHAR2
      ,p_sequence_owner   IN  VARCHAR2 DEFAULT NULL
      ,p_sequence_name    IN OUT VARCHAR2
   );
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_dict_main.quick_sequence

   Utility function to quickly generate a simple sequence.  

   Parameters:

      p_owner - optional owner of the sequence, default is current user.
      p_start_with - optional start with value, default is 1.
      p_prefix - optional prefix value for unique name generation.
      p_suffix - optional suffix value for unique name generation.
      
   Returns:

      VARCHAR2 text name of the sequence created.
      
   */
   FUNCTION quick_sequence(
       p_owner           IN  VARCHAR2 DEFAULT NULL
      ,p_start_with      IN  NUMBER   DEFAULT 1
      ,p_prefix          IN  VARCHAR2 DEFAULT NULL
      ,p_suffix          IN  VARCHAR2 DEFAULT NULL
   ) RETURN VARCHAR2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_dict_main.object_exists

   Utility function to interrogate all_objects for existence a given object.  

   Parameters:

      p_owner - optional owner of the object, default is current user.
      p_object_type_name - name of the object to verify.
      
   Returns:

      TRUE or FALSE as VARCHAR2 text string.
      
   */
   FUNCTION object_exists(
       p_owner            IN  VARCHAR2 DEFAULT NULL
      ,p_object_type_name IN  VARCHAR2
   ) RETURN VARCHAR2;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_dict_main.object_is_valid

   Utility function to interrogate all_objects for existence and validity of a 
   given object.  

   Parameters:

      p_owner - optional owner of the object, default is current user.
      p_object_type_name - name of the object to verify.
      
   Returns:

      TRUE or FALSE as VARCHAR2 text string.
      
   */
   FUNCTION object_is_valid(
       p_owner            IN  VARCHAR2 DEFAULT NULL
      ,p_object_type_name IN  VARCHAR2
   ) RETURN VARCHAR2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_dict_main.get_column_number

   Utility function to interrogate all_objects for existence and validity of a 
   given object.  

   Parameters:

      p_owner - optional owner of the table, default is current user.
      p_table_name - table or view name to inspect.
      p_column_name - column name in table to inspect.
      
   Returns:

      Number indicating position of column in table.
      
   */
   FUNCTION get_column_number(
       p_owner            IN  VARCHAR2 DEFAULT NULL
      ,p_table_name       IN  VARCHAR2
      ,p_column_name      IN  VARCHAR2
   ) RETURN NUMBER;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_dict_main.rename_to_x

   Utility function to rename a given table with X suffix, usually used in
   preparation for rebuilding or redefining the table into a new table with 
   the old name.  
   
   E.g. Renames MyTable to MyTable_X

   Parameters:

      p_owner - optional owner of the table, default is current user.
      p_table_name - table to rename.
      p_flush_objects - optional TRUE or FALSE flag to drop all indexes
      and constraints on the table.
      
   Returns:

      VARCHAR2 string of the new name of the renamed table.
      
   Notes:
   
      - The function is smart enough to rename to X1, X2, etc if X already exists.
      
   */
   FUNCTION rename_to_x(
       p_owner            IN  VARCHAR2 DEFAULT NULL
      ,p_table_name       IN  VARCHAR2
      ,p_flush_objects    IN  VARCHAR2 DEFAULT 'FALSE'
   ) RETURN VARCHAR2;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Procedure: dz_dict_main.fast_not_null

   Utility to quickly add a not null constraint to a column of a given table.   

   Parameters:

      p_owner - optional owner of the table, default is current user.
      p_table_name  - table name containing the column to set as not null.
      p_column_name - column name to set as not null.
      
   Returns:

      Nothing
      
   */
   PROCEDURE fast_not_null(
       p_owner            IN  VARCHAR2 DEFAULT NULL
      ,p_table_name       IN  VARCHAR2
      ,p_column_name      IN  VARCHAR2
   );
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Procedure: dz_dict_main.drop_indexes

   Utility to drop all indexes from a given table.   

   Parameters:

      p_owner - optional owner of the table, default is current user.
      p_table_name  - table name from which to drop all indexes.
      
   Returns:

      Nothing

   */
   PROCEDURE drop_indexes(
       p_owner            IN  VARCHAR2 DEFAULT NULL
      ,p_table_name       IN  VARCHAR2
   );

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Procedure: dz_dict_main.drop_index

   Utility to drop all indexes matching a given name or LIKE wildcard.   

   Parameters:

      p_owner - optional owner of the index, default is current user.
      p_index_name  - index name or LIKE wildcard to match indexes in owner's schema.
      p_like_flag - optional flag to trigger LIKE verse equals index name matching.
      
   Returns:

      Nothing
      
   */
   PROCEDURE drop_index(
       p_owner            IN  VARCHAR2 DEFAULT NULL
      ,p_index_name       IN  VARCHAR2
      ,p_like_flag        IN  VARCHAR2 DEFAULT 'FALSE'
   );

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_dict_main.index_exists

   Utility function to verify existence a given index.  

   Parameters:

      p_owner - optional owner of the index, default is current user.
      p_index_name - name of the index to verify.
      
   Returns:

      TRUE or FALSE as VARCHAR2 text string.
      
   */
   FUNCTION index_exists(
       p_owner            IN  VARCHAR2 DEFAULT NULL
      ,p_index_name       IN  VARCHAR2
   ) RETURN VARCHAR2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Procedure: dz_dict_main.drop_constraints

   Utility to drop all constraints from a given table.   

   Parameters:

      p_owner - optional owner of the table, default is current user.
      p_table_name  - table name from which to drop all constraints.
      
   Returns:

      Nothing

   */
   PROCEDURE drop_constraints(
       p_owner            IN  VARCHAR2 DEFAULT NULL
      ,p_table_name       IN  VARCHAR2
   );
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Procedure: dz_dict_main.drop_constraint

   Utility to drop all constraints matching a given name or LIKE wildcard.   

   Parameters:

      p_owner - optional owner of the constraint, default is current user.
      p_index_name  - constraint name or LIKE wildcard to match constraints in 
      owner's schema.
      p_like_flag - optional flag to trigger LIKE verse equals constraint name 
      matching.
      
   Returns:

      Nothing
      
   */
   PROCEDURE drop_constraint(
       p_owner            IN  VARCHAR2 DEFAULT NULL
      ,p_constraint_name  IN  VARCHAR2
      ,p_like_flag        IN  VARCHAR2 DEFAULT 'FALSE'
   );
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Procedure: dz_dict_main.drop_ref_constraints

   Utility to drop all referential constraints from a given table.   

   Parameters:

      p_owner - optional owner of the table, default is current user.
      p_table_name  - table name from which to drop all referential constraints.
      
   Returns:

      Nothing

   */
   PROCEDURE drop_ref_constraints(
       p_owner            IN  VARCHAR2 DEFAULT NULL
      ,p_table_name       IN  VARCHAR2
   );
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Procedure: dz_dict_main.get_index_name

   Procedure to extract the index name from a given table and column.  This only
   applies to single column indexes.   

   Parameters:

      p_owner - optional owner of the table, default is current user.
      p_table_name  - table name to inspect.
      p_column_name - column name to inspect for single-column index.
      
   Returns:

      p_index_owner - index owner
      p_index_name  - index name

   */
   PROCEDURE get_index_name(
       p_owner             IN  VARCHAR2 DEFAULT NULL
      ,p_table_name        IN  VARCHAR2
      ,p_column_name       IN  VARCHAR2
      ,p_index_owner       OUT VARCHAR2
      ,p_index_name        OUT VARCHAR2
   );
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_dict_main.new_index_name

   Utility function to generate a standardized and unique name for a single-column 
   index on a given table.   

   Parameters:

      p_owner - optional owner of the table, default is current user.
      p_table_name  - table name to inspect.
      p_column_name - column name to inspect.
      p_suffix_ind  - optional value in suffix to indicate index type, 
      default is "I".
      p_full_suffix - optional full value for the index suffix.
      
   Returns:

      VARCHAR2 string of the index name.
      
   Notes:
   
      - This function does not actually create the index, it's just intended to
        provide a standardized name for whatever index you decide to create.
      
   */
   FUNCTION new_index_name(
       p_owner             IN  VARCHAR2 DEFAULT NULL
      ,p_table_name        IN  VARCHAR2
      ,p_column_name       IN  VARCHAR2
      ,p_suffix_ind        IN  VARCHAR2 DEFAULT 'I'
      ,p_full_suffix       IN  VARCHAR2 DEFAULT NULL
   ) RETURN VARCHAR2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Procedure: dz_dict_main.fast_index

   Procedure to quickly and with no fuss build a simple index with a standardized
   name on a given table and column.   

   Parameters:

      p_owner - optional owner of the table, default is current user.
      p_table_name  - table name to build the index upon.
      p_column_name - column name to build the index upon.
      p_index_type - optional flag to build alternative index types such as BITMAP.
      p_tablespace - optional value for specific index tablespace.
      p_logging - optional flag to mark index as LOGGING or NOLOGGING, default is 
      to not specify (required for situations such as temp tables whose indexes 
      cannot be either LOGGING or NOLOGGING).
      
   Returns:

      Nothing

   */
   PROCEDURE fast_index(
       p_owner             IN  VARCHAR2 DEFAULT NULL
      ,p_table_name        IN  VARCHAR2
      ,p_column_name       IN  VARCHAR2
      ,p_index_type        IN  VARCHAR2 DEFAULT NULL
      ,p_tablespace        IN  VARCHAR2 DEFAULT NULL
      ,p_logging           IN  VARCHAR2 DEFAULT NULL
   );
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   Function: dz_dict_main.new_index_name

   Utility function to dump all index DBMS_METADATA.GET_DDL information on a
   given table.  Useful if you need to drop all indexes for some purpose and 
   then recreate them afterwards.

   Parameters:

      p_owner - optional owner of the table, default is current user.
      p_table_name  - table name to inspect.
      
   Returns:

      MDSYS.SDO_STRING2_ARRAY of string values of each DDL statement extracted
      from the table.
      
   */
   FUNCTION table_index_ddl(
       p_owner             IN  VARCHAR2 DEFAULT NULL
      ,p_table_name        IN  VARCHAR2
   ) RETURN MDSYS.SDO_STRING2_ARRAY;
   
END dz_dict_main;
/

GRANT EXECUTE ON dz_dict_main TO public;


--*************************--
PROMPT DZ_DICT_MAIN.pkb;

CREATE OR REPLACE PACKAGE BODY dz_dict_main
AS

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE drop_type_quietly(
       p_owner            IN  VARCHAR2 DEFAULT NULL
      ,p_type_name        IN  VARCHAR2
   )
   AS
      str_owner VARCHAR2(30 Char) := UPPER(p_owner);
      
   BEGIN
   
      IF str_owner IS NULL
      THEN
         str_owner := USER;
      
      END IF;
   
      BEGIN
          EXECUTE IMMEDIATE 
          'DROP TYPE ' || str_owner || '.' || p_type_name || ' FORCE ';
          
      EXCEPTION
         WHEN OTHERS
         THEN
            IF SQLCODE = -4043
            THEN
               NULL;
            ELSE
               RAISE;
            END IF;
            
      END;
      
   END drop_type_quietly;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE drop_table_quietly(
       p_owner            IN  VARCHAR2 DEFAULT NULL
      ,p_table_name       IN  VARCHAR2
   )
   AS
      str_owner VARCHAR2(30 Char) := UPPER(p_owner);
      
   BEGIN
   
      IF str_owner IS NULL
      THEN
         str_owner := USER;
      
      END IF;
   
      BEGIN
          EXECUTE IMMEDIATE 
          'DROP TABLE ' || str_owner || '.' || p_table_name || ' PURGE ';
          
      EXCEPTION
         WHEN OTHERS
         THEN
            IF SQLCODE = -942
            THEN
               NULL;
            ELSE
               RAISE;
            END IF;
            
      END;
      
   END drop_table_quietly;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION table_exists(
       p_owner            IN  VARCHAR2 DEFAULT NULL
      ,p_table_name       IN  VARCHAR2
      ,p_column_name      IN  VARCHAR2 DEFAULT NULL
   ) RETURN VARCHAR2
   AS
      str_owner        VARCHAR2(30 Char) := UPPER(p_owner);
      num_tab          PLS_INTEGER;
      
   BEGIN

      IF str_owner IS NULL
      THEN
         str_owner := USER;
         
      END IF;

      IF p_column_name IS NULL
      THEN
         SELECT 
         COUNT(*) 
         INTO num_tab
         FROM (
            SELECT 
             aa.owner
            ,aa.table_name 
            FROM 
            all_tables aa
            UNION ALL 
            SELECT 
             bb.owner
            ,bb.view_name AS table_name
            FROM 
            all_views bb
         ) a 
         WHERE 
             a.owner      = str_owner
         AND a.table_name = p_table_name;

      ELSE
         SELECT 
         COUNT(*) 
         INTO num_tab
         FROM (
            SELECT 
             aa.owner
            ,aa.table_name 
            FROM 
            all_tables aa
            UNION ALL 
            SELECT 
             bb.owner
            ,bb.view_name AS table_name
            FROM 
            all_views bb
         ) a 
         JOIN 
         all_tab_cols b 
         ON 
             a.owner = b.owner
         AND a.table_name = b.table_name 
         WHERE 
             a.owner = str_owner
         AND a.table_name = p_table_name
         AND b.column_name = p_column_name;

      END IF;

      IF num_tab = 0
      THEN
         RETURN 'FALSE';
         
      ELSE
         RETURN 'TRUE';
         
      END IF;

   END table_exists;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION table_exists(
       p_owner            IN  VARCHAR2 DEFAULT NULL
      ,p_table_name       IN  VARCHAR2
      ,p_column_name      IN  MDSYS.SDO_STRING2_ARRAY
   ) RETURN VARCHAR2
   AS
      str_owner        VARCHAR2(30 Char) := UPPER(p_owner);
      num_tab          PLS_INTEGER;

   BEGIN

      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF str_owner IS NULL
      THEN
         str_owner := USER;
      
      END IF;

      --------------------------------------------------------------------------
      -- Step 20
      -- Build and Execute SQL string
      --------------------------------------------------------------------------
      SELECT 
      COUNT(*) 
      INTO num_tab
      FROM (
         SELECT 
         a.owner, 
         a.table_name, 
         b.column_name 
         FROM (
            SELECT 
            owner, 
            table_name 
            FROM 
            all_tables 
            UNION ALL 
            SELECT 
            owner, 
            view_name table_name 
            FROM 
            all_views 
         ) a 
         JOIN 
         all_tab_cols b 
         ON 
         a.owner = b.owner AND 
         a.table_name = b.table_name 
         WHERE 
         a.owner = str_owner AND 
         a.table_name = p_table_name 
      ) aa 
      JOIN (
         SELECT column_value FROM TABLE(p_column_name)
      ) bb 
      ON 
      aa.column_name = bb.column_value;

      --------------------------------------------------------------------------
      -- Step 30
      -- Return results as string boolean
      --------------------------------------------------------------------------
      IF num_tab = p_column_name.COUNT
      THEN
         RETURN 'TRUE';
         
      ELSE
         RETURN 'FALSE';
         
      END IF;

   END table_exists;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION tables_exists(
       p_owner            IN  VARCHAR2 DEFAULT NULL
      ,p_table_names      IN  MDSYS.SDO_STRING2_ARRAY
   ) RETURN VARCHAR2
   AS
      str_owner     VARCHAR2(30 Char) := UPPER(p_owner);
      num_tab       NUMBER;
      
   BEGIN
      
      --------------------------------------------------------------------------
      -- Step 10
      -- Determine the input schema and tables
      --------------------------------------------------------------------------
      IF str_owner IS NULL
      THEN
         str_owner := USER;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Build and Execute SQL string
      --------------------------------------------------------------------------
      SELECT 
      COUNT(*) 
      INTO num_tab
      FROM (
         SELECT 
          a.owner 
         ,a.table_name 
         FROM (
            SELECT 
             aa.owner
            ,aa.table_name 
            FROM 
            all_tables aa 
            UNION ALL 
            SELECT 
             bb.owner
            ,bb.view_name AS table_name 
            FROM 
            all_views bb  
         ) a 
         WHERE
         a.owner = str_owner
         AND a.table_name IN (
            SELECT column_value FROM TABLE(p_table_names)
         )
      );
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Report results
      --------------------------------------------------------------------------
      IF num_tab = p_table_names.COUNT
      THEN
         RETURN 'TRUE';
         
      ELSE
         RETURN 'FALSE';
         
      END IF;
      
   END tables_exists;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION mview_exists(
       p_owner            IN  VARCHAR2 DEFAULT NULL
      ,p_mview_name       IN  VARCHAR2
   ) RETURN VARCHAR2
   AS
      str_owner        VARCHAR2(30 Char) := UPPER(p_owner);
      num_tab          PLS_INTEGER;

   BEGIN

      IF str_owner IS NULL
      THEN
         str_owner := USER;
      
      END IF;

      SELECT 
      COUNT(*) 
      INTO num_tab 
      FROM
      all_mviews a
      WHERE 
      a.owner = str_owner AND
      a.mview_name = p_mview_name;

      IF num_tab = 0
      THEN
         RETURN 'FALSE';
         
      ELSE
         RETURN 'TRUE';
         
      END IF;

   END mview_exists;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION tablespace_exists(
      p_tablespace_name  IN  VARCHAR2
   ) RETURN VARCHAR2
   AS
      str_tablespace_name VARCHAR2(30 Char) := UPPER(p_tablespace_name);
      num_check           NUMBER;
      
   BEGIN
   
      SELECT
      COUNT(*)
      INTO num_check
      FROM
      user_tablespaces a
      WHERE
      a.tablespace_name = str_tablespace_name;
      
      IF num_check = 1
      THEN
         RETURN 'TRUE';
         
      ELSE
         RETURN 'FALSE';
         
      END IF;
   
   END tablespace_exists;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION table_privileges(
       p_owner            IN  VARCHAR2 DEFAULT NULL
      ,p_table_name       IN  VARCHAR2
   ) RETURN MDSYS.SDO_STRING2_ARRAY
   AS
      str_owner      VARCHAR2(30 Char) := UPPER(p_owner);
      ary_output     MDSYS.SDO_STRING2_ARRAY;
      
   BEGIN
   
      ary_output := MDSYS.SDO_STRING2_ARRAY();
      
      IF str_owner IS NULL
      THEN
         str_owner := USER;
         
      END IF;

      IF table_exists(
          p_owner      => str_owner
         ,p_table_name => p_table_name
      ) = 'FALSE'
      THEN
         RETURN ary_output;
         
      END IF;

      IF str_owner = USER
      THEN
         RETURN MDSYS.SDO_STRING2_ARRAY('SELECT','DELETE','INSERT','UPDATE');
         
      END IF;

      SELECT 
      a.privilege 
      BULK COLLECT INTO ary_output
      FROM 
      all_tab_privs_recd a 
      WHERE 
      a.owner = str_owner AND 
      a.table_name = p_table_name ;

      RETURN ary_output;

   END table_privileges;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION table_privileges_dml(
       p_owner            IN  VARCHAR2 DEFAULT NULL
      ,p_table_name       IN  VARCHAR2
   ) RETURN VARCHAR2
   AS
      ary_output     MDSYS.SDO_STRING2_ARRAY;
      int_counter    PLS_INTEGER;
      
   BEGIN
      
      int_counter := 0;
      
      ary_output := table_privileges(
          p_owner      => p_owner
         ,p_table_name => p_table_name
      );
      
      FOR i IN 1 .. ary_output.COUNT
      LOOP
         IF ary_output(i) IN ('SELECT','INSERT','UPDATE','DELETE')
         THEN
            int_counter := int_counter + 1;
            
         END IF;
         
      END LOOP;
      
      IF int_counter = 4
      THEN
         RETURN 'TRUE';
         
      ELSE
         RETURN 'FALSE';
         
      END IF;
      
   END table_privileges_dml;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION sequence_exists(
       p_owner            IN  VARCHAR2 DEFAULT NULL
      ,p_sequence_name    IN  VARCHAR2
   ) RETURN VARCHAR2
   AS
      num_counter   NUMBER;
      str_owner     VARCHAR2(30 Char) := UPPER(p_owner);

   BEGIN

      IF str_owner IS NULL
      THEN
         str_owner := USER;
      
      END IF;

      SELECT 
      COUNT(*) 
      INTO num_counter
      FROM 
      all_sequences a 
      WHERE 
      a.sequence_owner = str_owner AND 
      a.sequence_name  = p_sequence_name;

      IF num_counter = 0
      THEN
         RETURN 'FALSE';
         
      ELSIF num_counter = 1
      THEN
         RETURN 'TRUE';
         
      ELSE
         RAISE_APPLICATION_ERROR(-20001,'error');
         
      END IF;

   END sequence_exists;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE drop_sequence(
       p_owner            IN  VARCHAR2 DEFAULT NULL
      ,p_sequence_name    IN  VARCHAR2
      ,p_like_flag        IN  VARCHAR2 DEFAULT 'FALSE'
   )
   AS
      ary_list          MDSYS.SDO_STRING2_ARRAY;
      str_like_flag     VARCHAR2(4000 Char) := UPPER(p_like_flag);
      str_owner         VARCHAR2(30 Char) := UPPER(p_owner);

   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF str_like_flag IS NULL
      THEN
         str_like_flag := 'FALSE';
         
      ELSIF str_like_flag NOT IN ('TRUE','FALSE')
      THEN
         RAISE_APPLICATION_ERROR(-20001,'boolean error');
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Parse out the schema from the sequence name
      --------------------------------------------------------------------------
      IF str_owner IS NULL
      THEN
         str_owner := USER;
      
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Pull the list of all sequences matching the input
      --------------------------------------------------------------------------
      IF str_like_flag = 'TRUE'
      THEN
         SELECT 
         a.sequence_name 
         BULK COLLECT INTO ary_list
         FROM 
         all_sequences a 
         WHERE 
         a.sequence_owner = str_owner AND 
         a.sequence_name LIKE p_sequence_name;

      ELSE
         SELECT 
         a.sequence_name 
         BULK COLLECT INTO ary_list
         FROM 
         all_sequences a 
         WHERE 
         a.sequence_owner = str_owner AND 
         a.sequence_name = p_sequence_name;

      END IF;
      
      --------------------------------------------------------------------------
      -- Step 40
      -- Loop through and attempt to drop all matches
      --------------------------------------------------------------------------
      IF  ary_list IS NOT NULL
      AND ary_list.COUNT > 0
      THEN
         FOR i IN 1 .. ary_list.COUNT
         LOOP
            EXECUTE IMMEDIATE 'DROP SEQUENCE ' || str_owner || '.' || ary_list(i) || ' ';
            
         END LOOP;

      END IF;

   END drop_sequence;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE sequence_from_max_column(
       p_owner            IN  VARCHAR2 DEFAULT NULL
      ,p_table_name       IN  VARCHAR2
      ,p_column_name      IN  VARCHAR2
      ,p_sequence_owner   IN  VARCHAR2 DEFAULT NULL
      ,p_sequence_name    IN OUT VARCHAR2
   )
   AS
      str_sql            VARCHAR2(4000 Char);
      str_owner          VARCHAR2(30 Char) := UPPER(p_owner);
      str_sequence_owner VARCHAR2(30 Char) := UPPER(p_sequence_owner);
      num_max            NUMBER;
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF str_owner IS NULL
      THEN
         str_owner := USER;
      
      END IF;
      
      IF str_sequence_owner IS NULL
      THEN
         str_sequence_owner := USER;
         
      END IF;
      
      IF table_exists(
          p_owner       => str_owner
         ,p_table_name  => p_table_name
         ,p_column_name => p_column_name
      ) = 'FALSE'
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,str_owner || '.' || p_table_name || '.' || p_column_name || ' not found'
         );
         
      END IF;
      
      p_sequence_name := UPPER(p_sequence_name);
      IF p_sequence_name IS NULL
      THEN
         p_sequence_name := dz_dict_util.unique_name();
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Pull the maximum value
      --------------------------------------------------------------------------
      str_sql := 'SELECT '
              || 'MAX(a.' || p_column_name || ') '
              || 'FROM '
              || str_owner || '.' || p_table_name || ' a ';
              
      EXECUTE IMMEDIATE str_sql INTO num_max;
      
      IF num_max IS NULL
      THEN
         num_max := 1;
         
      ELSE
         num_max := num_max + 1;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Drop and create the new sequence
      --------------------------------------------------------------------------
      drop_sequence(
          p_owner         => str_sequence_owner
         ,p_sequence_name => p_sequence_name
      );
      
      EXECUTE IMMEDIATE 
      'CREATE SEQUENCE ' || str_sequence_owner || '.' || p_sequence_name || ' ' || 
      'START WITH ' || TO_CHAR(num_max);
   
   END sequence_from_max_column;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION quick_sequence(
       p_owner           IN  VARCHAR2 DEFAULT NULL
      ,p_start_with      IN  NUMBER   DEFAULT 1
      ,p_prefix          IN  VARCHAR2 DEFAULT NULL
      ,p_suffix          IN  VARCHAR2 DEFAULT NULL
   ) RETURN VARCHAR2
   AS
      str_owner      VARCHAR2(30 Char) := UPPER(p_owner);
      num_start_with NUMBER := p_start_with;
      str_seq        VARCHAR2(30 Char);
      num_sanity     NUMBER;

   BEGIN

      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF num_start_with IS NULL
      THEN
         num_start_with := 1;
         
      END IF;
      
      IF str_owner IS NULL
      THEN
         str_owner := USER;
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 20
      -- Search for a reasonable sequence name not in usage in this schema
      --------------------------------------------------------------------------
      num_sanity := 1;
      WHILE num_sanity > 0
      LOOP
         num_sanity := num_sanity + 1;

         str_seq := dz_dict_util.unique_name(
             p_prefix => p_prefix
            ,p_suffix => p_suffix
         );

         IF sequence_exists(
             p_owner         => str_owner
            ,p_sequence_name => str_seq
         ) = 'FALSE'
         THEN
            num_sanity := 0;
            
         END IF;

         IF num_sanity > 25
         THEN
            RAISE_APPLICATION_ERROR(-20001,'cannot get good sequence name');
            
         END IF;

      END LOOP;

      --------------------------------------------------------------------------
      -- Step 30
      -- Create the sequence
      --------------------------------------------------------------------------
      EXECUTE IMMEDIATE
      'CREATE SEQUENCE ' || str_owner || '.' || str_seq || ' ' ||
      'START WITH ' || TO_CHAR(num_start_with);

      --------------------------------------------------------------------------
      -- Step 40
      -- Return the name to the caller
      --------------------------------------------------------------------------
      RETURN str_seq;

   END quick_sequence;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION object_exists(
       p_owner            IN  VARCHAR2 DEFAULT NULL
      ,p_object_type_name IN  VARCHAR2
   ) RETURN VARCHAR2
   AS
      str_owner         VARCHAR2(30 Char) := UPPER(p_owner);
      num_count         NUMBER;

   BEGIN

      IF str_owner IS NULL
      THEN
         str_owner := USER;
         
      END IF;

      SELECT 
      COUNT(*)
      INTO num_count
      FROM 
      all_objects a 
      WHERE 
          a.owner       = str_owner
      AND a.object_name = p_object_type_name
      AND a.object_type = 'TYPE';

      IF num_count = 1
      THEN
         RETURN 'TRUE';
         
      ELSE
         RETURN 'FALSE';
         
      END IF;

   END object_exists;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION object_is_valid(
       p_owner            IN  VARCHAR2 DEFAULT NULL
      ,p_object_type_name IN  VARCHAR2
   ) RETURN VARCHAR2
   AS
      str_owner         VARCHAR2(30 Char) := UPPER(p_owner);
      ary_object_status MDSYS.SDO_STRING2_ARRAY;

   BEGIN

      IF str_owner IS NULL
      THEN
         str_owner := USER;
         
      END IF;

      SELECT 
      a.status 
      BULK COLLECT INTO 
      ary_object_status
      FROM 
      all_objects a 
      WHERE 
      a.owner = str_owner AND 
      a.object_name = p_object_type_name;

      IF ary_object_status.COUNT = 0
      THEN
         RAISE_APPLICATION_ERROR(-20001,'object not found');
         
      END IF;

      FOR i IN 1 .. ary_object_status.COUNT
      LOOP
         IF ary_object_status(i) = 'INVALID'
         THEN
            RETURN 'FALSE';
            
         END IF;
         
      END LOOP;

      RETURN 'TRUE';

   END object_is_valid;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION get_column_number(
       p_owner            IN  VARCHAR2 DEFAULT NULL
      ,p_table_name       IN  VARCHAR2
      ,p_column_name      IN  VARCHAR2
   ) RETURN NUMBER
   AS
      str_owner        VARCHAR2(30 Char) := UPPER(p_owner);
      num_columnid     NUMBER;

   BEGIN

      IF str_owner IS NULL
      THEN
         str_owner := USER;
      
      END IF;

      SELECT 
      a.column_id
      INTO num_columnid 
      FROM 
      all_tab_columns a 
      WHERE 
          a.owner       = str_owner 
      AND a.table_name  = p_table_name
      AND a.column_name = p_column_name;
      
      RETURN num_columnid;

   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         RAISE_APPLICATION_ERROR(-20001,'no column name '
            || p_column_name || ' found in '
            || str_owner || '.' || p_table_name);
            
      WHEN OTHERS
      THEN
         RAISE;

   END get_column_number;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION rename_to_x(
       p_owner            IN  VARCHAR2 DEFAULT NULL
      ,p_table_name       IN  VARCHAR2
      ,p_flush_objects    IN  VARCHAR2 DEFAULT 'FALSE'
   ) RETURN VARCHAR2
   AS
      int_xspot         PLS_INTEGER;
      str_base          VARCHAR2(30 Char) := p_table_name;
      str_renamed       VARCHAR2(4000 Char);
      str_owner         VARCHAR2(30 Char) := UPPER(p_owner);
      str_flush_objects VARCHAR2(5 Char)  := UPPER(p_flush_objects);

   BEGIN

      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF str_flush_objects IS NULL
      THEN
         str_flush_objects := 'FALSE';
         
      ELSIF str_flush_objects NOT IN ('TRUE','FALSE')
      THEN
         RAISE_APPLICATION_ERROR(-20001,'boolean error');
         
      END IF;

      IF str_owner IS NULL
      THEN
         str_owner := USER;
      
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Shrink the base table name if needed
      --------------------------------------------------------------------------
      IF LENGTH(str_base) > 26
      THEN
         str_base := REGEXP_REPLACE(str_base, '[aeiou]', '');
         
         IF LENGTH(str_base) > 26
         THEN
            RAISE_APPLICATION_ERROR(-20001,'table name is too long to shorten');
            
         END IF;

      END IF;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Check if exists already
      --------------------------------------------------------------------------
      str_renamed := str_base || '_X';
      
      IF table_exists(
          p_owner      => str_owner
         ,p_table_name => str_renamed
      ) = 'TRUE'
      THEN
         int_xspot := 1;
         <<topper>>

         IF int_xspot > 99
         THEN
            RAISE_APPLICATION_ERROR(-20001,'cannot get a proper temp table name');
         
         END IF;
         
         str_renamed := str_base || '_X' || TO_CHAR(int_xspot);
         
         IF table_exists(
             p_owner      => str_owner
            ,p_table_name => str_renamed
         ) = 'TRUE'
         THEN
            int_xspot := int_xspot + 1;
            GOTO topper;
            
         END IF;
         
      END IF;

      IF str_flush_objects = 'TRUE'
      THEN
         drop_constraints(
             p_owner      => str_owner
            ,p_table_name => p_table_name
         );
         
         drop_indexes(
             p_owner      => str_owner
            ,p_table_name => p_table_name
         );
            
      END IF;

      EXECUTE IMMEDIATE 
      'ALTER TABLE ' || str_owner || '.' || p_table_name || ' ' ||
      'RENAME TO ' || str_renamed;

      RETURN str_renamed;

   END rename_to_x;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE fast_not_null(
       p_owner            IN  VARCHAR2 DEFAULT NULL
      ,p_table_name       IN  VARCHAR2
      ,p_column_name      IN  VARCHAR2
   )
   AS
      str_owner VARCHAR2(30 Char) := UPPER(p_owner);
      
   BEGIN
   
      IF str_owner IS NULL
      THEN
         str_owner := USER;
      
      END IF;

      EXECUTE IMMEDIATE 
      'ALTER TABLE ' || str_owner || '.' || p_table_name || ' ' ||
      'MODIFY (' || p_column_name || ' NOT NULL) ';
      
   EXCEPTION
      WHEN OTHERS
      THEN
         IF SQLCODE = -1442
         THEN
            NULL;  -- do nothing
            
         ELSE
            RAISE;
            
         END IF;

   END fast_not_null;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE drop_indexes(
       p_owner            IN  VARCHAR2 DEFAULT NULL
      ,p_table_name       IN  VARCHAR2
   )
   AS
      str_owner       VARCHAR2(30 Char) := UPPER(p_owner);
      ary_index       MDSYS.SDO_STRING2_ARRAY;
      
   BEGIN

      IF str_owner IS NULL
      THEN
         str_owner := USER;
      
      END IF;

      SELECT 
      a.owner || '.' || a.index_name 
      BULK COLLECT INTO ary_index
      FROM 
      all_indexes a 
      WHERE 
      a.table_owner = str_owner  AND 
      a.index_type != 'LOB' AND 
      a.table_name  = p_table_name;

      FOR i IN 1 .. ary_index.COUNT
      LOOP
         EXECUTE IMMEDIATE 'DROP INDEX ' || ary_index(i);

      END LOOP;

   END drop_indexes;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE drop_index(
       p_owner            IN  VARCHAR2 DEFAULT NULL
      ,p_index_name       IN  VARCHAR2
      ,p_like_flag        IN  VARCHAR2 DEFAULT 'FALSE'
   )
   AS
      str_owner       VARCHAR2(30 Char) := UPPER(p_owner);
      ary_index       MDSYS.SDO_STRING2_ARRAY;
      str_like_flag   VARCHAR2(5 Char) := UPPER(p_like_flag);
      
   BEGIN

      IF str_owner IS NULL
      THEN
         str_owner := USER;
      
      END IF;

      IF str_like_flag = 'TRUE'
      THEN
         SELECT 
         a.owner || '.' || a.index_name
         BULK COLLECT INTO ary_index
         FROM 
         all_indexes a 
         WHERE 
         a.owner = str_owner AND
         a.index_name LIKE p_index_name;
         
      ELSIF str_like_flag = 'FALSE'
      THEN
         SELECT 
         a.owner || '.' || a.index_name 
         BULK COLLECT INTO ary_index
         FROM 
         all_indexes a 
         WHERE 
         a.owner = str_owner AND
         a.index_name = p_index_name;

      ELSE
         RAISE_APPLICATION_ERROR(-20001,'boolean error');
         
      END IF;

      FOR i IN 1 .. ary_index.COUNT
      LOOP
         EXECUTE IMMEDIATE 'DROP INDEX ' || ary_index(i);
         
      END LOOP;

   END drop_index;

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION index_exists(
       p_owner            IN  VARCHAR2 DEFAULT NULL
      ,p_index_name       IN  VARCHAR2
   ) RETURN VARCHAR2
   AS
      str_owner      VARCHAR2(30 Char) := UPPER(p_owner);
      num_counter    NUMBER;

   BEGIN

      IF str_owner IS NULL
      THEN
         str_owner := USER;
      
      END IF;

      SELECT 
      COUNT(*) 
      INTO num_counter
      FROM 
      all_indexes a 
      WHERE 
      a.table_owner = str_owner AND 
      a.index_name  = p_index_name;

      IF num_counter = 0
      THEN
         RETURN 'FALSE';
         
      ELSIF num_counter = 1
      THEN
         RETURN 'TRUE';
         
      ELSE
         RAISE_APPLICATION_ERROR(-20001,'error');
         
      END IF;

   END index_exists;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE drop_constraints(
       p_owner            IN  VARCHAR2 DEFAULT NULL
      ,p_table_name       IN  VARCHAR2
   )
   AS
      ary_list       MDSYS.SDO_STRING2_ARRAY;
      str_owner      VARCHAR2(30 Char) := UPPER(p_owner);

   BEGIN

      IF str_owner IS NULL
      THEN
         str_owner := USER;
      
      END IF;

      SELECT 
      a.constraint_name 
      BULK COLLECT INTO ary_list
      FROM 
      all_constraints a 
      WHERE 
      a.owner = str_owner AND 
      a.table_name = p_table_name;

      FOR i IN 1 .. ary_list.COUNT
      LOOP
         EXECUTE IMMEDIATE 
         'ALTER TABLE ' || str_owner || '.' || p_table_name || ' ' || 
         'DROP CONSTRAINT ' || ary_list(i) || ' ';

      END LOOP;

   END drop_constraints;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE drop_constraint(
       p_owner            IN  VARCHAR2 DEFAULT NULL
      ,p_constraint_name  IN  VARCHAR2
      ,p_like_flag        IN  VARCHAR2 DEFAULT 'FALSE'
   )
   AS
      str_owner           VARCHAR2(30 Char) := UPPER(p_owner);
      ary_tables          MDSYS.SDO_STRING2_ARRAY;
      ary_objects         MDSYS.SDO_STRING2_ARRAY;

   BEGIN

      IF str_owner IS NULL
      THEN
         str_owner := USER;
      
      END IF;

      IF p_like_flag = 'TRUE'
      THEN
         SELECT 
          a.table_name
         ,a.constraint_name
         BULK COLLECT INTO 
          ary_tables
         ,ary_objects
         FROM 
         all_constraints a 
         WHERE 
             a.owner = str_owner 
         AND a.constraint_name LIKE p_constraint_name;

      ELSIF p_like_flag = 'FALSE'
      THEN
         SELECT 
          a.table_name
         ,a.constraint_name
         BULK COLLECT INTO 
          ary_tables
         ,ary_objects
         FROM 
         all_constraints a 
         WHERE 
             a.owner = str_owner 
         AND a.constraint_name = p_constraint_name;
         
      ELSE
         RAISE_APPLICATION_ERROR(-20001,'boolean error');
         
      END IF;

      FOR i IN 1 .. ary_tables.COUNT
      LOOP
         EXECUTE IMMEDIATE 
         'ALTER TABLE '     || str_owner || '.' || ary_tables(i)  || ' ' || 
         'DROP CONSTRAINT ' || ary_objects(i) || ' ';

      END LOOP;

   END drop_constraint;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE drop_ref_constraints(
       p_owner            IN  VARCHAR2 DEFAULT NULL
      ,p_table_name       IN  VARCHAR2
   )
   AS
      str_owner      VARCHAR2(30 Char) := UPPER(p_owner);
      ary_ref_cons   MDSYS.SDO_STRING2_ARRAY;
      
   BEGIN
   
      IF str_owner IS NULL
      THEN
         str_owner := USER;
      
      END IF;
      
      SELECT 
      a.constraint_name 
      BULK COLLECT INTO ary_ref_cons
      FROM 
      all_constraints a 
      WHERE 
      a.owner = str_owner AND 
      a.table_name = p_table_name AND 
      a.constraint_type = 'R';
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Drop the referencial constraints
      --------------------------------------------------------------------------
      FOR i IN 1 .. ary_ref_cons.COUNT
      LOOP
         EXECUTE IMMEDIATE 
         'ALTER TABLE ' || str_owner || '.' || p_table_name || ' ' || 
         'DROP CONSTRAINT ' ||  ary_ref_cons(i) || ' ';
         
      END LOOP;
      
   END drop_ref_constraints;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE get_index_name(
       p_owner             IN  VARCHAR2 DEFAULT NULL
      ,p_table_name        IN  VARCHAR2
      ,p_column_name       IN  VARCHAR2
      ,p_index_owner       OUT VARCHAR2
      ,p_index_name        OUT VARCHAR2
   )
   AS
      str_table_owner VARCHAR2(30 Char) := UPPER(p_owner);
    
   BEGIN
   
      IF str_table_owner IS NULL
      THEN
         str_table_owner := USER;
         
      END IF;

      SELECT 
       a.owner
      ,a.index_name 
      INTO 
       p_index_owner
      ,p_index_name
      FROM 
      all_indexes a 
      JOIN 
      all_ind_columns b 
      ON 
      a.owner      = b.index_owner AND 
      a.table_name = b.table_name AND 
      a.index_name = b.index_name 
      WHERE 
      a.table_owner = str_table_owner AND 
      a.table_name  = p_table_name AND 
      b.column_name = p_column_name;

   EXCEPTION
      WHEN NO_DATA_FOUND
      THEN
         NULL;
         
      WHEN OTHERS
      THEN
         RAISE;

   END get_index_name;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION new_index_name(
       p_owner             IN  VARCHAR2 DEFAULT NULL
      ,p_table_name        IN  VARCHAR2
      ,p_column_name       IN  VARCHAR2
      ,p_suffix_ind        IN  VARCHAR2 DEFAULT 'I'
      ,p_full_suffix       IN  VARCHAR2 DEFAULT NULL
   ) RETURN VARCHAR2
   AS
      str_columnid    VARCHAR2(16 Char);
      str_suffix_ind  VARCHAR2(1 Char) := UPPER(p_suffix_ind);
      str_full_suffix VARCHAR2(3 Char) := SUBSTR(UPPER(p_full_suffix),1,3);
      str_index_name  VARCHAR2(60 Char);
      str_table_owner VARCHAR2(30 Char) := UPPER(p_owner);
      str_table_base  VARCHAR2(30 Char);

   BEGIN

      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF str_table_owner IS NULL
      THEN
         str_table_owner := USER;
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 20
      -- get the truncated tablename as a base
      --------------------------------------------------------------------------
      str_table_base := dz_dict_util.scrunch_name(
         p_input      => p_table_name,
         p_max_length => 26,
         p_method     => 'VOWELS'
      );

      --------------------------------------------------------------------------
      -- Step 30
      -- get the column id number
      --------------------------------------------------------------------------
      IF str_full_suffix IS NOT NULL
      THEN
         str_columnid := '_' || str_full_suffix;

      ELSE
         str_columnid := TO_CHAR(
            get_column_number(
                p_owner       => str_table_owner 
               ,p_table_name  => p_table_name
               ,p_column_name => p_column_name
            )
         );

         IF LENGTH(str_columnid) = 1
         THEN
            str_columnid := '_0' || str_columnid || str_suffix_ind;
            
         ELSIF LENGTH(str_columnid) = 2
         THEN
            str_columnid := '_' || str_columnid || str_suffix_ind;
            
         ELSE
            str_columnid := str_columnid || str_suffix_ind;
            
         END IF;

      END IF;

      str_index_name := str_table_base || str_columnid;

      RETURN UPPER(str_index_name);

   END new_index_name;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   PROCEDURE fast_index(
       p_owner        IN  VARCHAR2 DEFAULT NULL
      ,p_table_name   IN  VARCHAR2
      ,p_column_name  IN  VARCHAR2
      ,p_index_type   IN  VARCHAR2 DEFAULT NULL
      ,p_tablespace   IN  VARCHAR2 DEFAULT NULL
      ,p_logging      IN  VARCHAR2 DEFAULT NULL
   )
   AS
      str_sql         VARCHAR2(4000 Char);
      str_index_owner VARCHAR2(30 Char);
      str_index_name  VARCHAR2(30 Char);
      str_index_type  VARCHAR2(16 Char);
      str_owner       VARCHAR2(30 Char) := UPPER(p_owner);
      str_logging     VARCHAR2(4000 Char) := UPPER(p_logging);

   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------   
      IF str_owner IS NULL
      THEN
         str_owner := USER;
         
      END IF;
      
      IF str_logging IN ('NOLOGGING','FALSE')
      THEN
         str_logging := 'NOLOGGING ';
         
      ELSIF str_logging IN ('LOGGING','TRUE')
      THEN
         str_logging := 'LOGGING ';
         
      ELSE
         str_logging := NULL;
         
      END IF;

      IF p_index_type IS NULL
      THEN
         str_index_type := 'NORMAL';
         
      ELSE
         str_index_type := UPPER(p_index_type);
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Generate an index name
      --------------------------------------------------------------------------
      str_index_owner := str_owner;
      str_index_name  := new_index_name(
          p_owner       => str_owner
         ,p_table_name  => p_table_name
         ,p_column_name => p_column_name
      );

      --------------------------------------------------------------------------
      -- Step 30
      -- Verify that index does not already exist
      --------------------------------------------------------------------------
      IF index_exists(
          p_owner      => str_index_owner
         ,p_index_name => str_index_name
      ) = 'TRUE'
      THEN
         RAISE_APPLICATION_ERROR(-20001,'index ' || str_index_name || ' already exists');
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 40
      -- Add Bitmap clause if requested
      --------------------------------------------------------------------------
      IF str_index_type = 'BITMAP'
      THEN
         str_sql := 'CREATE BITMAP INDEX ';
         
      ELSE
         str_sql := 'CREATE INDEX ';
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 50
      -- Generate base DDL
      --------------------------------------------------------------------------
      str_sql := str_sql || 
         str_index_owner || '.' || str_index_name || ' ' || 
         'ON ' || str_owner || '.' || p_table_name || ' ' ||
         '(' || p_column_name || ') ';
         
      --------------------------------------------------------------------------
      -- Step 60
      -- Add logging clause if requested
      --------------------------------------------------------------------------
      IF str_logging IS NOT NULL
      THEN
         str_sql := str_sql || str_logging;
         
      END IF;

      --------------------------------------------------------------------------
      -- Step 70
      -- Add tablespace clause if requested
      --------------------------------------------------------------------------
      IF p_tablespace IS NOT NULL
      THEN
         str_sql := str_sql ||  'TABLESPACE ' || p_tablespace;
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 80
      -- Execute DDL
      --------------------------------------------------------------------------
      BEGIN
          EXECUTE IMMEDIATE str_sql;
          
      EXCEPTION
         WHEN OTHERS
         THEN
            RAISE_APPLICATION_ERROR(-20001,str_sql || CHR(10) || SQLERRM);
      
      END;

   END fast_index;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION table_index_ddl(
       p_owner        IN  VARCHAR2 DEFAULT NULL
      ,p_table_name   IN  VARCHAR2
   ) RETURN MDSYS.SDO_STRING2_ARRAY
   AS
      ary_list        MDSYS.SDO_STRING2_ARRAY;
      str_owner       VARCHAR2(30 Char) := UPPER(p_owner);

   BEGIN

      IF str_owner IS NULL
      THEN
         str_owner := USER;
      
      END IF;

      SELECT 
      TO_CHAR(DBMS_METADATA.GET_DDL(z.obj_type,z.obj_name)) myddl 
      BULK COLLECT INTO ary_list
      FROM (
         WITH 
         indexlist AS (
            SELECT 
            'INDEX' AS obj_type, 
            a.index_name AS obj_name 
            FROM 
            all_indexes a 
            WHERE 
            a.owner = str_owner AND (
               a.index_type = 'NORMAL' OR 
               a.index_type = 'DOMAIN' 
            ) AND 
            a.table_name = p_table_name
         ), 
         constraintlist AS ( 
            SELECT 
            'CONSTRAINT' AS obj_type, 
            b.constraint_name AS obj_name 
            FROM 
            all_constraints b 
            WHERE 
            b.owner = str_owner AND 
            b.table_name = p_table_name 
         ) 
         SELECT 
         c.obj_type, 
         c.obj_name 
         FROM 
         constraintlist c 
         WHERE 
         c.obj_name IN (SELECT obj_name FROM indexlist) 
         UNION SELECT 
         d.obj_type, 
         d.obj_name 
         FROM 
         indexlist d 
         WHERE 
         d.obj_name NOT IN (SELECT obj_name FROM constraintlist) 
      ) z;

      RETURN ary_list;

   END table_index_ddl;
   
END dz_dict_main;
/


--*************************--
PROMPT DZ_DICT_GUUID_GENERATOR.tps;

CREATE OR REPLACE TYPE dz_dict_guuid_generator FORCE
AUTHID CURRENT_USER
AS OBJECT (

    guuid_value VARCHAR2(40 Char)
    
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,CONSTRUCTOR FUNCTION dz_dict_guuid_generator
    RETURN SELF AS RESULT
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,CONSTRUCTOR FUNCTION dz_dict_guuid_generator(
       p_guuid_value     IN  VARCHAR2
    ) RETURN SELF AS RESULT
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,MEMBER PROCEDURE nextval
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,MEMBER FUNCTION nextval(
       self  IN OUT dz_dict_guuid_generator
    ) RETURN VARCHAR2
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,MEMBER FUNCTION getval(
       self  IN OUT dz_dict_guuid_generator
    ) RETURN VARCHAR2
   
);
/

GRANT EXECUTE ON dz_dict_guuid_generator TO PUBLIC;


--*************************--
PROMPT DZ_DICT_GUUID_GENERATOR.tpb;

CREATE OR REPLACE TYPE BODY dz_dict_guuid_generator
AS

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   CONSTRUCTOR FUNCTION dz_dict_guuid_generator
   RETURN SELF AS RESULT
   AS
   BEGIN
      RETURN;
      
   END dz_dict_guuid_generator;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   CONSTRUCTOR FUNCTION dz_dict_guuid_generator(
      p_guuid_value     IN  VARCHAR2
   ) RETURN SELF AS RESULT
   AS
   BEGIN
      self.guuid_value := p_guuid_value;  
          
      RETURN;
      
   END dz_dict_guuid_generator;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   MEMBER PROCEDURE nextval
   AS
      str_guuid VARCHAR2(4000 Char);
      
   BEGIN
      str_guuid := self.nextval();
      
   END nextval;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   MEMBER FUNCTION getval(
      self  IN OUT dz_dict_guuid_generator
   ) RETURN VARCHAR2
   AS
   BEGIN
   
      IF self.guuid_value IS NULL
      THEN
         self.guuid_value := dz_dict_util.get_guid();
         
      END IF;
      
      RETURN self.guuid_value;
   
   END getval;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   MEMBER FUNCTION nextval(
      self  IN OUT dz_dict_guuid_generator
   ) RETURN VARCHAR2
   AS
   BEGIN
   
      self.guuid_value := dz_dict_util.get_guid();
      RETURN self.guuid_value;
   
   END nextval;

END;
/


--*************************--
PROMPT DZ_DICT_SEQUENCE_GENERATOR.tps;

CREATE OR REPLACE TYPE dz_dict_sequence_generator FORCE
AUTHID CURRENT_USER
AS OBJECT(

    seed_number             NUMBER(11)
   ,sequence_owner          VARCHAR2(30 Char)    
   ,sequence_name           VARCHAR2(30 Char)
   ,current_seq_number      NUMBER(11)
    
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,CONSTRUCTOR FUNCTION dz_dict_sequence_generator
    RETURN SELF AS RESULT
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,CONSTRUCTOR FUNCTION dz_dict_sequence_generator(
       p_seed_number     IN  NUMBER
    ) RETURN SELF AS RESULT
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,CONSTRUCTOR FUNCTION dz_dict_sequence_generator(
        p_owner             IN  VARCHAR2 DEFAULT NULL
       ,p_sequence_name     IN  VARCHAR2
    ) RETURN SELF AS RESULT
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,STATIC FUNCTION fieldmax(
        p_owner             IN  VARCHAR2 DEFAULT NULL
       ,p_table_name        IN  VARCHAR2
       ,p_column_name       IN  VARCHAR2
    ) RETURN dz_dict_sequence_generator
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,MEMBER PROCEDURE nextval
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,MEMBER FUNCTION nextval(
       self  IN OUT dz_dict_sequence_generator
    ) RETURN NUMBER
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,MEMBER FUNCTION str_seq_nextval
    RETURN VARCHAR2
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   ,MEMBER FUNCTION getval(
       self  IN OUT dz_dict_sequence_generator
    ) RETURN NUMBER
   
);
/

GRANT EXECUTE ON dz_dict_sequence_generator TO PUBLIC;


--*************************--
PROMPT DZ_DICT_SEQUENCE_GENERATOR.tpb;

CREATE OR REPLACE TYPE BODY dz_dict_sequence_generator
AS

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   CONSTRUCTOR FUNCTION dz_dict_sequence_generator
   RETURN SELF AS RESULT
   AS
   BEGIN
      RETURN;
      
   END dz_dict_sequence_generator;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   CONSTRUCTOR FUNCTION dz_dict_sequence_generator(
      p_seed_number     IN  NUMBER
   ) RETURN SELF AS RESULT
   AS
   BEGIN
      self.seed_number := p_seed_number;
      self.current_seq_number := p_seed_number;
      self.sequence_name := NULL;
      RETURN;
      
   END dz_dict_sequence_generator;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   CONSTRUCTOR FUNCTION dz_dict_sequence_generator(
       p_owner             IN  VARCHAR2 DEFAULT NULL
      ,p_sequence_name     IN  VARCHAR2
   ) RETURN SELF AS RESULT
   AS
      str_owner VARCHAR2(30 Char) := UPPER(p_owner);
      
   BEGIN
   
      self.seed_number := NULL;
      self.sequence_name := p_sequence_name;
      
      IF str_owner IS NULL
      THEN
         self.sequence_owner := USER;
      
      ELSE
         self.sequence_owner := str_owner;
      
      END IF;
      
      IF dz_dict_main.sequence_exists(
          p_owner         => self.sequence_owner
         ,p_sequence_name => self.sequence_name
      ) = 'FALSE'
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'sequence ' || self.sequence_name || ' not found'
         );
         
      END IF;      
      
      RETURN;
      
   END dz_dict_sequence_generator;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   STATIC FUNCTION fieldmax(
       p_owner             IN  VARCHAR2 DEFAULT NULL
      ,p_table_name        IN  VARCHAR2
      ,p_column_name       IN  VARCHAR2
   ) RETURN dz_dict_sequence_generator
   AS
      str_sql    VARCHAR2(4000 Char);
      num_max    NUMBER;
      obj_output dz_dict_sequence_generator;
      
   BEGIN
   
      --------------------------------------------------------------------------
      -- Step 10
      -- Check over incoming parameters
      --------------------------------------------------------------------------
      IF p_table_name IS NULL
      THEN
         RAISE_APPLICATION_ERROR(-20001,'table name is required');
         
      END IF;
      
      IF p_column_name IS NULL
      THEN
         RAISE_APPLICATION_ERROR(-20001,'column name is required');
         
      END IF;
      
      --------------------------------------------------------------------------
      -- Step 20
      -- Fetch the maximum value
      --------------------------------------------------------------------------
      str_sql := 'SELECT '
              || 'MAX(' || p_column_name || ') '
              || 'FROM '
              || p_table_name;
              
      EXECUTE IMMEDIATE str_sql INTO num_max;
      
      --------------------------------------------------------------------------
      -- Step 30
      -- Create the sequence object
      --------------------------------------------------------------------------
      obj_output := dz_dict_sequence_generator(num_max + 1);
      
      --------------------------------------------------------------------------
      -- Step 40
      -- Return the results
      --------------------------------------------------------------------------
      RETURN obj_output;
      
   END fieldmax;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   MEMBER PROCEDURE nextval
   AS
      num_rez  NUMBER;
      
   BEGIN
      num_rez := self.nextval();
      
   END nextval;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   MEMBER FUNCTION nextval(
      self  IN OUT dz_dict_sequence_generator
   ) RETURN NUMBER
   AS
      num_current_seq NUMBER;
      str_sql         VARCHAR2(4000 Char);
      
   BEGIN
   
      IF self.seed_number IS NOT NULL
      THEN
         num_current_seq := self.current_seq_number;
         self.current_seq_number := self.current_seq_number + 1;
         RETURN num_current_seq;
         
      END IF;
      
      IF self.sequence_name IS NOT NULL
      THEN 
         str_sql := 'SELECT ' || self.sequence_name || '.NEXTVAL FROM dual';
         EXECUTE IMMEDIATE str_sql INTO num_current_seq;
         
         self.current_seq_number := num_current_seq;
         RETURN num_current_seq;
         
      END IF;
      
      RETURN NULL;
   
   END nextval;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   MEMBER FUNCTION str_seq_nextval
   RETURN VARCHAR2
   AS
   BEGIN
      IF self.sequence_name IS NULL
      THEN
         RAISE_APPLICATION_ERROR(
             -20001
            ,'no sequence set for this generator'
         );
         
      END IF;
      
      RETURN self.sequence_name || '.NEXTVAL';

   END str_seq_nextval;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   MEMBER FUNCTION getval(
      self  IN OUT dz_dict_sequence_generator
   ) RETURN NUMBER
   AS
   BEGIN
   
      IF self.current_seq_number IS NOT NULL
      THEN 
         RETURN self.current_seq_number;
         
      ELSE
         RETURN self.NEXTVAL(); 
         
      END IF;
   
   END getval;

END;
/


--*************************--
PROMPT DZ_DICT_TEST.pks;

CREATE OR REPLACE PACKAGE dz_dict_test
AUTHID DEFINER
AS

   C_TFS_CHANGESET CONSTANT NUMBER := 8297;
   C_JENKINS_JOBNM CONSTANT VARCHAR2(255 Char) := 'NULL';
   C_JENKINS_BUILD CONSTANT NUMBER := 4;
   C_JENKINS_BLDID CONSTANT VARCHAR2(255 Char) := 'NULL';
   
   C_PREREQUISITES CONSTANT MDSYS.SDO_STRING2_ARRAY := MDSYS.SDO_STRING2_ARRAY(
   );
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION prerequisites
   RETURN NUMBER;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION version
   RETURN VARCHAR2;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION inmemory_test
   RETURN NUMBER;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION scratch_test
   RETURN NUMBER;
      
END dz_dict_test;
/

GRANT EXECUTE on dz_dict_test TO public;


--*************************--
PROMPT DZ_DICT_TEST.pkb;

CREATE OR REPLACE PACKAGE BODY dz_dict_test
AS

   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION prerequisites
   RETURN NUMBER
   AS
      num_check NUMBER;
      
   BEGIN
      
      FOR i IN 1 .. C_PREREQUISITES.COUNT
      LOOP
         SELECT 
         COUNT(*)
         INTO num_check
         FROM 
         user_objects a
         WHERE 
             a.object_name = C_PREREQUISITES(i) || '_TEST'
         AND a.object_type = 'PACKAGE';
         
         IF num_check <> 1
         THEN
            RETURN 1;
         
         END IF;
      
      END LOOP;
      
      RETURN 0;
   
   END prerequisites;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION version
   RETURN VARCHAR2
   AS
   BEGIN
      RETURN '{"TFS":' || C_TFS_CHANGESET || ','
      || '"JOBN":"' || C_JENKINS_JOBNM || '",'   
      || '"BUILD":' || C_JENKINS_BUILD || ','
      || '"BUILDID":"' || C_JENKINS_BLDID || '"}';
      
   END version;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION inmemory_test
   RETURN NUMBER
   AS
   BEGIN
      RETURN 0;
      
   END inmemory_test;
   
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   FUNCTION scratch_test
   RETURN NUMBER
   AS
   BEGIN
      RETURN 0;
      
   END scratch_test;

END dz_dict_test;
/


--*************************--
PROMPT sqlplus_footer.sql;


SHOW ERROR;

DECLARE
   l_num_errors PLS_INTEGER;

BEGIN

   SELECT
   COUNT(*)
   INTO l_num_errors
   FROM
   user_errors a
   WHERE
   a.name LIKE 'DZ_DICT%';

   IF l_num_errors <> 0
   THEN
      RAISE_APPLICATION_ERROR(-20001,'COMPILE ERROR');

   END IF;

   l_num_errors := DZ_DICT_TEST.inmemory_test();

   IF l_num_errors <> 0
   THEN
      RAISE_APPLICATION_ERROR(-20001,'INMEMORY TEST ERROR');

   END IF;

END;
/

EXIT;

