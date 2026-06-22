CLASS ltcl_reduce DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_expr03_reduce.
    METHODS setup.
    METHODS factorial_five  FOR TESTING.
    METHODS factorial_zero  FOR TESTING.
    METHODS join_separator  FOR TESTING.
    METHODS multi_accum      FOR TESTING.
    METHODS conditional_count FOR TESTING.
ENDCLASS.


CLASS ltcl_reduce IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD factorial_five.
    cl_abap_unit_assert=>assert_equals( act = cut->factorial( 5 ) exp = 120 ).
  ENDMETHOD.

  METHOD factorial_zero.
    cl_abap_unit_assert=>assert_equals( act = cut->factorial( 0 ) exp = 1 ).
  ENDMETHOD.

  METHOD join_separator.
    cl_abap_unit_assert=>assert_equals( act = cut->join_with( `-` ) exp = `ABAP-is-fun` ).
  ENDMETHOD.

  METHOD multi_accum.
    cl_abap_unit_assert=>assert_equals( act = cut->sum_and_count( ) exp = `15/5` ).
  ENDMETHOD.

  METHOD conditional_count.
    cl_abap_unit_assert=>assert_equals( act = cut->count_evens( ) exp = 2 ).
  ENDMETHOD.
ENDCLASS.
