CREATE OR REPLACE TYPE dz_dict_oracle_object_list FORCE             
AS 
TABLE OF dz_dict_oracle_object;
/

GRANT EXECUTE ON dz_dict_oracle_object_list TO PUBLIC;

