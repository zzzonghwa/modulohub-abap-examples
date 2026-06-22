CLASS ltcl_xco DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_ext01_xco.
    METHODS setup.
    METHODS upper_case        FOR TESTING.
    METHODS upper_matches_classic FOR TESTING.
    METHODS lower_case        FOR TESTING.
    METHODS reverse_string    FOR TESTING.
    METHODS resplit_codes     FOR TESTING.
    METHODS split_count_codes FOR TESTING.
    METHODS matches_hit       FOR TESTING.
    METHODS matches_miss      FOR TESTING.
    METHODS prefix_hit        FOR TESTING.
    METHODS prefix_miss       FOR TESTING.
    METHODS uuid_filled       FOR TESTING.
    METHODS uuid_c36_shape    FOR TESTING.
    METHODS uuid_system_shape FOR TESTING.
    METHODS user_filled       FOR TESTING.
    METHODS random_in_range   FOR TESTING.
ENDCLASS.


CLASS ltcl_xco IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD upper_case.
    cl_abap_unit_assert=>assert_equals( act = cut->to_upper( `abap` ) exp = `ABAP` ).
  ENDMETHOD.

  METHOD upper_matches_classic.
    " XCO 결과와 전통 TRANSLATE 결과가 동일해야 한다(대조 불변식).
    cl_abap_unit_assert=>assert_equals( act = cut->to_upper( `MixedCase` )
                                        exp = cut->to_upper_classic( `MixedCase` ) ).
  ENDMETHOD.

  METHOD lower_case.
    cl_abap_unit_assert=>assert_equals( act = cut->to_lower( `ABAP` ) exp = `abap` ).
  ENDMETHOD.

  METHOD reverse_string.
    cl_abap_unit_assert=>assert_equals( act = cut->reverse( `abc` ) exp = `cba` ).
  ENDMETHOD.

  METHOD resplit_codes.
    " 'a.b.c' 를 '.' 로 분리 후 '/' 로 재결합 -> 'a/b/c'.
    cl_abap_unit_assert=>assert_equals(
      act = cut->resplit( text = `a.b.c` separator = `.` joiner = `/` )
      exp = `a/b/c` ).
  ENDMETHOD.

  METHOD split_count_codes.
    " 'a.b.c' 는 '.' 로 3조각.
    cl_abap_unit_assert=>assert_equals(
      act = cut->split_count( text = `a.b.c` separator = `.` )
      exp = 3 ).
  ENDMETHOD.

  METHOD matches_hit.
    " 'A1' 은 \w\d (단어문자+숫자) 전체 매치.
    cl_abap_unit_assert=>assert_equals( act = cut->matches_pattern( text = `A1` pattern = `\w\d` )
                                        exp = abap_true ).
  ENDMETHOD.

  METHOD matches_miss.
    " 'AA' 는 두 번째 자리가 숫자가 아니라 미매치.
    cl_abap_unit_assert=>assert_equals( act = cut->matches_pattern( text = `AA` pattern = `\w\d` )
                                        exp = abap_false ).
  ENDMETHOD.

  METHOD prefix_hit.
    cl_abap_unit_assert=>assert_equals( act = cut->starts_with( text = `ZCL_X` prefix = `ZCL_` )
                                        exp = abap_true ).
  ENDMETHOD.

  METHOD prefix_miss.
    cl_abap_unit_assert=>assert_equals( act = cut->starts_with( text = `Z` prefix = `ZCL_` )
                                        exp = abap_false ).
  ENDMETHOD.

  METHOD uuid_filled.
    " UUID 값은 비결정적 -> "비지 않음"과 hex 길이 32만 검증.
    DATA(uuid) = cut->new_uuid( ).
    cl_abap_unit_assert=>assert_not_initial( act = uuid ).
    cl_abap_unit_assert=>assert_equals( act = strlen( uuid ) exp = 32 ).
  ENDMETHOD.

  METHOD uuid_c36_shape.
    " c36(RFC4122) = 길이 36, 하이픈 4개(8-4-4-4-12).
    DATA(uuid) = cut->new_uuid_c36( ).
    cl_abap_unit_assert=>assert_equals( act = strlen( uuid ) exp = 36 ).
    cl_abap_unit_assert=>assert_equals( act = count( val = uuid sub = `-` ) exp = 4 ).
  ENDMETHOD.

  METHOD uuid_system_shape.
    " cl_system_uuid 경로도 동일한 c36 형식이어야 한다.
    DATA(uuid) = cut->new_uuid_via_system( ).
    cl_abap_unit_assert=>assert_equals( act = strlen( uuid ) exp = 36 ).
    cl_abap_unit_assert=>assert_equals( act = count( val = uuid sub = `-` ) exp = 4 ).
  ENDMETHOD.

  METHOD user_filled.
    " 실행 컨텍스트의 sy-uname 은 항상 채워져 있다.
    cl_abap_unit_assert=>assert_not_initial( act = cut->current_user( ) ).
  ENDMETHOD.

  METHOD random_in_range.
    " 시드 고정. PRNG 출력값 자체는 환경의존이라 범위(폐구간)만 단언한다.
    DATA(value) = cut->random_int( seed = 1 low = 1 high = 6 ).
    cl_abap_unit_assert=>assert_true( xsdbool( value >= 1 AND value <= 6 ) ).
  ENDMETHOD.
ENDCLASS.
