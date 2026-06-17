"! abaplint 전용 스텁(SAP 표준 IF_OO_ADT_OUTPUT). /deps는 abapGit
"! STARTING_FOLDER(/src/) 밖이라 SAP에 import되지 않는다.
INTERFACE if_oo_adt_output PUBLIC.
  METHODS write
    IMPORTING data TYPE data
              name TYPE csequence OPTIONAL.
ENDINTERFACE.
