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

