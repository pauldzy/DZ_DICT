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

