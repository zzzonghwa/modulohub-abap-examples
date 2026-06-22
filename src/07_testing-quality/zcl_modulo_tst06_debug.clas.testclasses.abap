CLASS ltcl_debug DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_tst06_debug.
    METHODS setup.
    METHODS already_one    FOR TESTING.
    METHODS six_steps      FOR TESTING.
    METHODS power_of_two   FOR TESTING.
    METHODS long_chain     FOR TESTING.
    METHODS guard_non_positive FOR TESTING.
ENDCLASS.


CLASS ltcl_debug IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD already_one.
    cl_abap_unit_assert=>assert_equals( act = cut->collatz_steps( 1 ) exp = 0 ).
  ENDMETHOD.

  METHOD six_steps.
    " 6 -> 3 -> 10 -> 5 -> 16 -> 8 -> 4 -> 2 -> 1 = 8 단계.
    cl_abap_unit_assert=>assert_equals( act = cut->collatz_steps( 6 ) exp = 8 ).
  ENDMETHOD.

  METHOD power_of_two.
    " 4 -> 2 -> 1 = 2 단계.
    cl_abap_unit_assert=>assert_equals( act = cut->collatz_steps( 4 ) exp = 2 ).
  ENDMETHOD.

  METHOD long_chain.
    " 27은 정점 9232까지 오르내리며 111단계에 1로 수렴 — 디버거 watchpoint 연습에 좋다.
    cl_abap_unit_assert=>assert_equals( act = cut->collatz_steps( 27 ) exp = 111 ).
  ENDMETHOD.

  METHOD guard_non_positive.
    cl_abap_unit_assert=>assert_equals( act = cut->collatz_steps( 0 ) exp = 0 ).
  ENDMETHOD.
ENDCLASS.
