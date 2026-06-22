CLASS ltcl_api DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_sql07_api.
    METHODS setup.
    " 시스템 날짜·시간은 비결정적(시점 의존)이라 released API가 값을 돌려주는지 스모크만 본다.
    METHODS date_is_filled         FOR TESTING.
    METHODS time_is_filled         FOR TESTING.
    " 카탈로그 모사 데이터는 결정적이라 기댓값을 시드에서 재계산해 단정한다.
    METHODS released_total         FOR TESTING.
    METHODS released_clas_names    FOR TESTING.
    METHODS released_flag_hit_miss FOR TESTING.
    METHODS contract_lookup        FOR TESTING.
    METHODS consume_internal_c1    FOR TESTING.
    METHODS consume_remote_needs_c2 FOR TESTING.
    METHODS consume_not_released   FOR TESTING.
    METHODS successor_lookup       FOR TESTING.
    METHODS deprecated_pairs       FOR TESTING.
ENDCLASS.


CLASS ltcl_api IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD date_is_filled.
    " 실 시스템에서 시스템 날짜는 항상 채워진다(오늘) -> 초기값이 아니다.
    cl_abap_unit_assert=>assert_not_initial( act = cut->system_date( ) ).
  ENDMETHOD.

  METHOD time_is_filled.
    cl_abap_unit_assert=>assert_not_initial( act = cut->system_time( ) ).
  ENDMETHOD.

  METHOD released_total.
    " 카탈로그 RELEASED 5건: CONTEXT_INFO·RANDOM_INT·GATEWAY_REMOTE·PROB_TYPES·I_COMPANYCODE.
    cl_abap_unit_assert=>assert_equals( act = cut->released_count( ) exp = 5 ).
  ENDMETHOD.

  METHOD released_clas_names.
    " RELEASED + CLAS 3건, 이름 오름차순: CONTEXT_INFO < RANDOM_INT < GATEWAY_REMOTE? -> 알파벳순.
    DATA(names) = cut->released_names_of_type( 'CLAS' ).
    cl_abap_unit_assert=>assert_equals( act = lines( names ) exp = 3 ).
    " 오름차순: CL_ABAP_CONTEXT_INFO < CL_ABAP_RANDOM_INT < CL_GATEWAY_REMOTE.
    cl_abap_unit_assert=>assert_equals( act = names[ 1 ] exp = `CL_ABAP_CONTEXT_INFO` ).
    cl_abap_unit_assert=>assert_equals( act = names[ 3 ] exp = `CL_GATEWAY_REMOTE` ).
  ENDMETHOD.

  METHOD released_flag_hit_miss.
    cl_abap_unit_assert=>assert_equals(
      act = cut->is_released( 'CL_ABAP_CONTEXT_INFO' ) exp = abap_true ).
    " NOT_RELEASED 객체는 카탈로그엔 있으나 RELEASED 아님 -> false.
    cl_abap_unit_assert=>assert_equals(
      act = cut->is_released( 'CL_INTERNAL_HELPER' ) exp = abap_false ).
    cl_abap_unit_assert=>assert_equals(
      act = cut->is_released( 'CL_DOES_NOT_EXIST' ) exp = abap_false ).
  ENDMETHOD.

  METHOD contract_lookup.
    cl_abap_unit_assert=>assert_equals(
      act = cut->contract_of( 'CL_ABAP_CONTEXT_INFO' ) exp = 'C1' ).
    cl_abap_unit_assert=>assert_equals(
      act = cut->contract_of( 'CL_GATEWAY_REMOTE' ) exp = 'C2' ).
    cl_abap_unit_assert=>assert_equals(
      act = cut->contract_of( 'CL_DOES_NOT_EXIST' ) exp = space ).
  ENDMETHOD.

  METHOD consume_internal_c1.
    " 내부 호출은 C1·C2 모두 OK.
    cl_abap_unit_assert=>assert_equals(
      act = cut->may_consume( object_name = 'CL_ABAP_CONTEXT_INFO' remote = abap_false ) exp = abap_true ).
    cl_abap_unit_assert=>assert_equals(
      act = cut->may_consume( object_name = 'CL_GATEWAY_REMOTE' remote = abap_false ) exp = abap_true ).
  ENDMETHOD.

  METHOD consume_remote_needs_c2.
    " 원격 호출은 C2만 OK — C1 객체는 원격 소비 불가.
    cl_abap_unit_assert=>assert_equals(
      act = cut->may_consume( object_name = 'CL_GATEWAY_REMOTE' remote = abap_true ) exp = abap_true ).
    cl_abap_unit_assert=>assert_equals(
      act = cut->may_consume( object_name = 'CL_ABAP_CONTEXT_INFO' remote = abap_true ) exp = abap_false ).
  ENDMETHOD.

  METHOD consume_not_released.
    " 카탈로그에 RELEASED로 없으면 호출 경계와 무관하게 불가.
    cl_abap_unit_assert=>assert_equals(
      act = cut->may_consume( object_name = 'CL_INTERNAL_HELPER' remote = abap_false ) exp = abap_false ).
  ENDMETHOD.

  METHOD successor_lookup.
    cl_abap_unit_assert=>assert_equals(
      act = cut->successor_of( 'CL_OLD_THING' ) exp = 'CL_NEW_THING' ).
    cl_abap_unit_assert=>assert_equals(
      act = cut->successor_of( 'CL_ABAP_CONTEXT_INFO' ) exp = space ).
  ENDMETHOD.

  METHOD deprecated_pairs.
    " DEPRECATED 2건, 이름 오름차순: CL_LEGACY_READER < CL_OLD_THING.
    DATA(pairs) = cut->deprecated_with_successor( ).
    cl_abap_unit_assert=>assert_equals( act = lines( pairs ) exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = pairs[ 1 ]-predecessor exp = 'CL_LEGACY_READER' ).
    cl_abap_unit_assert=>assert_equals( act = pairs[ 1 ]-successor exp = 'CL_MODERN_READER' ).
    cl_abap_unit_assert=>assert_equals( act = pairs[ 2 ]-predecessor exp = 'CL_OLD_THING' ).
    cl_abap_unit_assert=>assert_equals( act = pairs[ 2 ]-successor exp = 'CL_NEW_THING' ).
  ENDMETHOD.
ENDCLASS.
