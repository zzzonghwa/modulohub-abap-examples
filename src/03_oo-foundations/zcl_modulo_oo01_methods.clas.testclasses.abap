CLASS ltcl_counter DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO lcl_counter.   "검증 대상(CUT) — 로컬 클래스
    METHODS setup.
    METHODS starts_at_given_value FOR TESTING.
    METHODS increment_default_one  FOR TESTING.
    METHODS increment_by_amount    FOR TESTING.
    METHODS double_returns_twice   FOR TESTING.
    METHODS factory_builds_counter FOR TESTING.
ENDCLASS.


CLASS ltcl_counter IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( start = 10 ).
  ENDMETHOD.

  METHOD starts_at_given_value.
    " GIVEN start=10 (setup) / WHEN 값을 읽으면 / THEN 10
    cl_abap_unit_assert=>assert_equals( act = cut->value( ) exp = 10 ).
  ENDMETHOD.

  METHOD increment_default_one.
    " GIVEN 10 / WHEN by 생략 increment / THEN 11
    cut->increment( ).
    cl_abap_unit_assert=>assert_equals( act = cut->value( ) exp = 11 ).
  ENDMETHOD.

  METHOD increment_by_amount.
    " GIVEN 10 / WHEN +4 / THEN 14
    cut->increment( by = 4 ).
    cl_abap_unit_assert=>assert_equals( act = cut->value( ) exp = 14 ).
  ENDMETHOD.

  METHOD double_returns_twice.
    " 함수형 메서드는 상태를 바꾸지 않는다.
    cl_abap_unit_assert=>assert_equals( act = cut->double( ) exp = 20 ).
    cl_abap_unit_assert=>assert_equals( act = cut->value( )  exp = 10 ).
  ENDMETHOD.

  METHOD factory_builds_counter.
    " 정적 팩토리가 인스턴스를 돌려준다.
    DATA(made) = lcl_counter=>of( 7 ).
    cl_abap_unit_assert=>assert_bound( made ).
    cl_abap_unit_assert=>assert_equals( act = made->value( ) exp = 7 ).
  ENDMETHOD.
ENDCLASS.
