CLASS ltcl_except DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_tst01_except.
    METHODS setup.
    METHODS divide_happy        FOR TESTING.
    METHODS divide_absorbs_zero FOR TESTING.
    METHODS withdraw_happy      FOR TESTING.
    METHODS withdraw_rejected   FOR TESTING.
    METHODS contract_zero_raises     FOR TESTING.
    METHODS contract_overdraw_raises FOR TESTING.
ENDCLASS.


CLASS ltcl_except IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD divide_happy.
    cl_abap_unit_assert=>assert_equals( act = cut->divide_or_zero( dividend = 10 divisor = 2 ) exp = 5 ).
  ENDMETHOD.

  METHOD divide_absorbs_zero.
    cl_abap_unit_assert=>assert_equals( act = cut->divide_or_zero( dividend = 10 divisor = 0 ) exp = 0 ).
  ENDMETHOD.

  METHOD withdraw_happy.
    cl_abap_unit_assert=>assert_equals( act = cut->withdraw_or_reject( balance = 100 amount = 30 ) exp = 70 ).
  ENDMETHOD.

  METHOD withdraw_rejected.
    cl_abap_unit_assert=>assert_equals( act = cut->withdraw_or_reject( balance = 100 amount = 150 ) exp = -1 ).
  ENDMETHOD.

  METHOD contract_zero_raises.
    " 사전조건(divisor<>0) 위반 시 도메인 예외가 던져짐을 직접 검증한다.
    TRY.
        NEW lcl_calculator( )->divide( dividend = 10 divisor = 0 ).
        cl_abap_unit_assert=>fail( msg = `expected lcx_invalid_arg` ).
      CATCH lcx_invalid_arg.
        " 기대한 예외 — 통과.
    ENDTRY.
  ENDMETHOD.

  METHOD contract_overdraw_raises.
    TRY.
        NEW lcl_calculator( )->withdraw( balance = 100 amount = 150 ).
        cl_abap_unit_assert=>fail( msg = `expected lcx_invalid_arg` ).
      CATCH lcx_invalid_arg.
        " 기대한 예외 — 통과.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
