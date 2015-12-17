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

