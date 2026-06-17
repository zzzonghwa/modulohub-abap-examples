"! abaplint 전용 스텁(SAP 표준 IF_OO_ADT_CLASSRUN). /deps는 abapGit
"! STARTING_FOLDER(/src/) 밖이라 SAP에 import되지 않는다.
INTERFACE if_oo_adt_classrun PUBLIC.
  METHODS main
    IMPORTING out TYPE REF TO if_oo_adt_output.
ENDINTERFACE.
