CREATE OR REPLACE PACKAGE dz_dict_main
AUTHID CURRENT_USER
AS
   -----------------------------------------------------------------------------
   -----------------------------------------------------------------------------
   /*
   header: DZ_DICT
     
   - Release: %GITRELEASE%
   - Commit Date: %GITCOMMITDATE%
   
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

