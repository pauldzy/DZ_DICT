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

