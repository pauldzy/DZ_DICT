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

