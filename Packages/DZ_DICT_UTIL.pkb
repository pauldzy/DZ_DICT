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

