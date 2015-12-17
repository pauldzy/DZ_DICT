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

