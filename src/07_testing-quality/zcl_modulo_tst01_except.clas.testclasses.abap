CLASS ltcl_except DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_tst01_except.
    METHODS setup.
    METHODS divide_happy             FOR TESTING.
    METHODS divide_absorbs_zero      FOR TESTING.
    METHODS divide_strict_propagates FOR TESTING.
    METHODS withdraw_happy           FOR TESTING.
    METHODS withdraw_rejected        FOR TESTING.
    METHODS classified_overdrawn     FOR TESTING.
    METHODS classified_negative      FOR TESTING.
    METHODS classified_happy         FOR TESTING.
    METHODS shortfall_read           FOR TESTING.
    METHODS retry_tops_up            FOR TESTING.
    METHODS cleanup_only_on_propagate FOR TESTING.
    METHODS parse_happy              FOR TESTING.
    METHODS parse_absorbs_bad_text   FOR TESTING.
    METHODS zero_divide_has_text     FOR TESTING.
    METHODS source_line_positive     FOR TESTING.
    METHODS rtti_type_name           FOR TESTING.
    METHODS cond_throw_happy         FOR TESTING.
    METHODS cond_throw_absorbed      FOR TESTING.
    METHODS require_satisfied        FOR TESTING.
    METHODS require_violated         FOR TESTING.
    METHODS contract_zero_raises     FOR TESTING.
    METHODS contract_overdraw_raises FOR TESTING.
    METHODS resumable_continues      FOR TESTING.
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

  METHOD divide_strict_propagates.
    " 전파 전략: 정상은 결과, 0 제수는 예외가 호출부(이 테스트)까지 올라온다.
    TRY.
        cl_abap_unit_assert=>assert_equals( act = cut->divide_strict( dividend = 10 divisor = 2 ) exp = 5 ).
        cut->divide_strict( dividend = 10 divisor = 0 ).
        cl_abap_unit_assert=>fail( msg = `expected lcx_invalid_arg` ).
      CATCH lcx_invalid_arg.
        " 기대한 전파 — 통과.
    ENDTRY.
  ENDMETHOD.

  METHOD withdraw_happy.
    cl_abap_unit_assert=>assert_equals( act = cut->withdraw_or_reject( balance = 100 amount = 30 ) exp = 70 ).
  ENDMETHOD.

  METHOD withdraw_rejected.
    cl_abap_unit_assert=>assert_equals( act = cut->withdraw_or_reject( balance = 100 amount = 150 ) exp = -1 ).
  ENDMETHOD.

  METHOD classified_overdrawn.
    " 초과 출금은 구체 하위 예외 lcx_overdrawn으로 -2가 된다.
    cl_abap_unit_assert=>assert_equals( act = cut->withdraw_classified( balance = 100 amount = 150 ) exp = -2 ).
  ENDMETHOD.

  METHOD classified_negative.
    " 음수 출금은 lcx_invalid_arg로 -1.
    cl_abap_unit_assert=>assert_equals( act = cut->withdraw_classified( balance = 100 amount = -5 ) exp = -1 ).
  ENDMETHOD.

  METHOD classified_happy.
    cl_abap_unit_assert=>assert_equals( act = cut->withdraw_classified( balance = 100 amount = 30 ) exp = 70 ).
  ENDMETHOD.

  METHOD shortfall_read.
    " 부족액 = amount - balance = 150 - 100 = 50.
    cl_abap_unit_assert=>assert_equals( act = cut->shortfall_of_overdraw( balance = 100 amount = 150 ) exp = 50 ).
    cl_abap_unit_assert=>assert_equals( act = cut->shortfall_of_overdraw( balance = 100 amount = 30 ) exp = 0 ).
  ENDMETHOD.

  METHOD retry_tops_up.
    " 첫 시도 초과 -> 잔액 보충 -> RETRY -> withdraw(150,150)=0.
    cl_abap_unit_assert=>assert_equals( act = cut->withdraw_with_retry( 150 ) exp = 0 ).
  ENDMETHOD.

  METHOD cleanup_only_on_propagate.
    " local: 로컬 CATCH라 CLEANUP 미실행(공백). propagated: 외부 처리라 실행(X).
    cl_abap_unit_assert=>assert_equals( act = cut->cleanup_observed( ) exp = |local={ space } propagated={ 'X' }| ).
  ENDMETHOD.

  METHOD parse_happy.
    cl_abap_unit_assert=>assert_equals( act = cut->parse_or_default( text = `42` fallback = -1 ) exp = 42 ).
  ENDMETHOD.

  METHOD parse_absorbs_bad_text.
    cl_abap_unit_assert=>assert_equals( act = cut->parse_or_default( text = `x` fallback = -1 ) exp = -1 ).
  ENDMETHOD.

  METHOD zero_divide_has_text.
    " 표준 예외는 비어있지 않은 단문 메시지를 가진다.
    cl_abap_unit_assert=>assert_true( xsdbool( cut->zero_divide_text_len( ) > 0 ) ).
  ENDMETHOD.

  METHOD source_line_positive.
    cl_abap_unit_assert=>assert_true( xsdbool( cut->error_source_line( ) > 0 ) ).
  ENDMETHOD.

  METHOD rtti_type_name.
    cl_abap_unit_assert=>assert_equals( act = cut->error_type_name( ) exp = `CX_SY_ITAB_LINE_NOT_FOUND` ).
  ENDMETHOD.

  METHOD cond_throw_happy.
    cl_abap_unit_assert=>assert_equals( act = cut->double_or_throw( 7 ) exp = 14 ).
  ENDMETHOD.

  METHOD cond_throw_absorbed.
    cl_abap_unit_assert=>assert_equals( act = cut->double_or_throw( -3 ) exp = -1 ).
  ENDMETHOD.

  METHOD require_satisfied.
    cl_abap_unit_assert=>assert_true( cut->require_non_negative_age( 20 ) ).
  ENDMETHOD.

  METHOD require_violated.
    cl_abap_unit_assert=>assert_false( cut->require_non_negative_age( -1 ) ).
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
    " 초과 출금은 lcx_overdrawn(하위)이며 상위 타입 CATCH로도 잡힌다.
    TRY.
        NEW lcl_calculator( )->withdraw( balance = 100 amount = 150 ).
        cl_abap_unit_assert=>fail( msg = `expected lcx_overdrawn` ).
      CATCH lcx_overdrawn INTO DATA(overdraw_error).
        cl_abap_unit_assert=>assert_equals( act = overdraw_error->shortfall exp = 50 ).
    ENDTRY.
  ENDMETHOD.

  METHOD resumable_continues.
    " RESUMABLE: 불량 행(-2)에서 예외 -> RESUME으로 이어가 [1,-2,3] 3행 모두 처리.
    cl_abap_unit_assert=>assert_equals( act = cut->resumable_demo( ) exp = 3 ).
  ENDMETHOD.
ENDCLASS.
