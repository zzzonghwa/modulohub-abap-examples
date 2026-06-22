"! abaplint 전용 스텁(SAP 표준 IF_CONSTRAINT, SABP_UNIT_CONSTRAINT_API). /deps는 abapGit
"! STARTING_FOLDER(/src/) 밖이라 SAP에 import되지 않는다(SAP엔 실제 표준 인터페이스 존재).
INTERFACE if_constraint PUBLIC.
  METHODS is_valid
    IMPORTING data_object   TYPE data
    RETURNING VALUE(result) TYPE abap_bool.
  METHODS get_description
    RETURNING VALUE(result) TYPE string_table.
ENDINTERFACE.
