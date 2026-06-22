CLASS ltcl_badi DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_ext03_badi.
    METHODS setup.
    METHODS all_pass         FOR TESTING.
    METHODS one_violation    FOR TESTING.
    METHODS other_violation  FOR TESTING.
    METHODS both_violations   FOR TESTING.
ENDCLASS.


CLASS ltcl_badi IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD all_pass.
    " 4: 음수 아님 + 짝수 -> 위반 0.
    cl_abap_unit_assert=>assert_equals( act = cut->validate( 4 ) exp = 0 ).
  ENDMETHOD.

  METHOD one_violation.
    " 3: 홀수만 위반 -> 1.
    cl_abap_unit_assert=>assert_equals( act = cut->validate( 3 ) exp = 1 ).
  ENDMETHOD.

  METHOD other_violation.
    " -4: 음수만 위반 -> 1.
    cl_abap_unit_assert=>assert_equals( act = cut->validate( -4 ) exp = 1 ).
  ENDMETHOD.

  METHOD both_violations.
    " -3: 음수 + 홀수 -> 두 구현 모두 위반 -> 2(멀티캐스트 확인).
    cl_abap_unit_assert=>assert_equals( act = cut->validate( -3 ) exp = 2 ).
  ENDMETHOD.
ENDCLASS.
