CLASS ltcl_calc DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO lcl_calc.
    METHODS setup.
    METHODS add_returns_sum         FOR TESTING.
    METHODS split_exports_two       FOR TESTING.
    METHODS accumulate_updates      FOR TESTING.
    METHODS greet_uses_default      FOR TESTING.
    METHODS greet_uses_supplied     FOR TESTING.
    METHODS label_prefers_text      FOR TESTING.
    METHODS divide_ok               FOR TESTING.
    METHODS divide_by_zero_raises   FOR TESTING.
ENDCLASS.


CLASS ltcl_calc IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD add_returns_sum.
    cl_abap_unit_assert=>assert_equals( act = cut->add( a = 3 b = 4 ) exp = 7 ).
  ENDMETHOD.

  METHOD split_exports_two.
    cut->split(
      EXPORTING total = 17 parts = 5
      IMPORTING quotient = DATA(quotient) remainder = DATA(remainder) ).

    cl_abap_unit_assert=>assert_equals( act = quotient  exp = 3 ).
    cl_abap_unit_assert=>assert_equals( act = remainder exp = 2 ).
  ENDMETHOD.

  METHOD accumulate_updates.
    DATA(running) = 100.
    cut->accumulate( EXPORTING amount = 25 CHANGING running_total = running ).
    cl_abap_unit_assert=>assert_equals( act = running exp = 125 ).
  ENDMETHOD.

  METHOD greet_uses_default.
    " name 미전달 -> world, greeting 미전달 -> 기본값 Hello.
    cl_abap_unit_assert=>assert_equals( act = cut->greet( ) exp = `Hello, world!` ).
  ENDMETHOD.

  METHOD greet_uses_supplied.
    cl_abap_unit_assert=>assert_equals(
      act = cut->greet( greeting = `Hi` name = `Lee` )
      exp = `Hi, Lee!` ).
  ENDMETHOD.

  METHOD label_prefers_text.
    " 이름 없이 넘긴 단일 인자가 PREFERRED PARAMETER(text)에 바인딩된다.
    cl_abap_unit_assert=>assert_equals( act = cut->label( `core` ) exp = `#core` ).
  ENDMETHOD.

  METHOD divide_ok.
    TRY.
        cl_abap_unit_assert=>assert_equals(
          act = cut->divide( dividend = 10 divisor = 2 )
          exp = CONV decfloat34( 5 ) ).
      CATCH cx_sy_zerodivide.
        cl_abap_unit_assert=>fail( `정상 나눗셈에서 예외가 나면 안 된다` ).
    ENDTRY.
  ENDMETHOD.

  METHOD divide_by_zero_raises.
    " 예외 검증의 표준 패턴: 호출 후 fail( ), 기대 예외를 CATCH.
    TRY.
        cut->divide( dividend = 10 divisor = 0 ).
        cl_abap_unit_assert=>fail( `0으로 나누면 예외가 나야 한다` ).
      CATCH cx_sy_zerodivide.
        " 기대대로 예외 발생 — 통과.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
