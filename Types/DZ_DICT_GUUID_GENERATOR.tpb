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

