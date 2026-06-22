CLASS ltcl_pushdown DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_sql06_pushdown.
    METHODS setup.
    METHODS sum_pushdown        FOR TESTING.
    METHODS filter_count        FOR TESTING.
    METHODS pushdown_eq_abap    FOR TESTING.
ENDCLASS.


CLASS ltcl_pushdown IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD sum_pushdown.
    cl_abap_unit_assert=>assert_equals( act = cut->total_seats_pushdown( ) exp = 1700 ).
  ENDMETHOD.

  METHOD filter_count.
    cl_abap_unit_assert=>assert_equals( act = cut->high_demand_pushdown( 300 ) exp = 3 ).
  ENDMETHOD.

  METHOD pushdown_eq_abap.
    " 같은 임계치에서 pushdown과 ABAP loop 결과가 동일함을 보증한다.
    cl_abap_unit_assert=>assert_equals(
      act = cut->high_demand_in_abap( 250 ) exp = cut->high_demand_pushdown( 250 ) ).
  ENDMETHOD.
ENDCLASS.
