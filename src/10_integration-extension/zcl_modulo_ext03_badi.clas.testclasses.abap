CLASS ltcl_badi DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_ext03_badi.
    METHODS setup.

    " 멀티캐스트: active 구현 전부 실행.
    METHODS multicast_all_pass        FOR TESTING.
    METHODS multicast_one_violation   FOR TESTING.
    METHODS multicast_other_violation FOR TESTING.
    METHODS multicast_both_violations FOR TESTING.

    " active/inactive override.
    METHODS inactive_excluded_pass    FOR TESTING.
    METHODS inactive_excluded_one     FOR TESTING.

    " single vs multiple — 구현 0개.
    METHODS empty_multi_is_noop       FOR TESTING.
    METHODS single_no_impl_raises     FOR TESTING.
    METHODS single_fallback_no_raise  FOR TESTING.
    METHODS single_multiply_raises    FOR TESTING.

    " 인스턴스 모드.
    METHODS instance_reuse_accumulates FOR TESTING.

    " filter 라우팅.
    METHODS filter_lower_case_matches FOR TESTING.
    METHODS filter_negative_route     FOR TESTING.
    METHODS filter_unknown_raises     FOR TESTING.
ENDCLASS.


CLASS ltcl_badi IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD multicast_all_pass.
    " 4: 음수 아님 + 짝수 -> 위반 0.
    cl_abap_unit_assert=>assert_equals( act = cut->validate( 4 ) exp = 0 ).
  ENDMETHOD.

  METHOD multicast_one_violation.
    " 3: 홀수만 위반 -> 1.
    cl_abap_unit_assert=>assert_equals( act = cut->validate( 3 ) exp = 1 ).
  ENDMETHOD.

  METHOD multicast_other_violation.
    " -4: 음수만 위반 -> 1.
    cl_abap_unit_assert=>assert_equals( act = cut->validate( -4 ) exp = 1 ).
  ENDMETHOD.

  METHOD multicast_both_violations.
    " -3: 음수 + 홀수 -> 두 구현 모두 위반 -> 2(멀티캐스트 확인).
    cl_abap_unit_assert=>assert_equals( act = cut->validate( -3 ) exp = 2 ).
  ENDMETHOD.

  METHOD inactive_excluded_pass.
    " 3은 홀수지만 짝수 구현이 inactive -> 위반 0(음수 구현만 active, 3은 음수 아님).
    cl_abap_unit_assert=>assert_equals( act = cut->validate_with_inactive( 3 ) exp = 0 ).
  ENDMETHOD.

  METHOD inactive_excluded_one.
    " -3: 음수 구현만 active -> 1(짝수 구현 inactive이므로 홀수는 무시).
    cl_abap_unit_assert=>assert_equals( act = cut->validate_with_inactive( -3 ) exp = 1 ).
  ENDMETHOD.

  METHOD empty_multi_is_noop.
    " multiple-use 구현 0개 -> 예외 없이 0(single-use와의 결정적 차이).
    cl_abap_unit_assert=>assert_equals( act = cut->validate_empty_multi( -3 ) exp = 0 ).
  ENDMETHOD.

  METHOD single_no_impl_raises.
    " single-use 구현 0개 + fallback 없음 -> NOT_IMPLEMENTED.
    cl_abap_unit_assert=>assert_true( cut->single_use_no_impl_raises( ) ).
  ENDMETHOD.

  METHOD single_fallback_no_raise.
    " fallback 등록 -> 폴백되어 예외 없음, fallback은 항상 통과 -> 0.
    cl_abap_unit_assert=>assert_equals( act = cut->single_use_fallback( -3 ) exp = 0 ).
  ENDMETHOD.

  METHOD single_multiply_raises.
    " single-use 구현 2개 -> MULTIPLY_IMPLEMENTED.
    cl_abap_unit_assert=>assert_true( cut->single_use_multiply_raises( ) ).
  ENDMETHOD.

  METHOD instance_reuse_accumulates.
    " 동일 plug-in 재사용 -> 2회 호출이 누적 -> 2.
    cl_abap_unit_assert=>assert_equals( act = cut->instance_reuse_calls( ) exp = 2 ).
  ENDMETHOD.

  METHOD filter_lower_case_matches.
    " 'even'(소문자)이 'EVEN'으로 정규화 매칭 -> 3은 홀수 위반 -> 1.
    cl_abap_unit_assert=>assert_equals(
      act = cut->validate_by_filter( filter = `even` value = 3 )
      exp = 1 ).
  ENDMETHOD.

  METHOD filter_negative_route.
    " 'NEG' 라우팅 -> 음수 구현 선택, -1은 음수 위반 -> 1.
    cl_abap_unit_assert=>assert_equals(
      act = cut->validate_by_filter( filter = `NEG` value = -1 )
      exp = 1 ).
  ENDMETHOD.

  METHOD filter_unknown_raises.
    " 미등록 filter -> 매칭 구현 없음.
    cl_abap_unit_assert=>assert_true( cut->unknown_filter_raises( ) ).
  ENDMETHOD.
ENDCLASS.
