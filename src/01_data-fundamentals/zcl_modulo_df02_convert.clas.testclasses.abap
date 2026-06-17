CLASS ltcl_convert DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_df02_convert.
    METHODS setup.
    METHODS conv_rounds_down       FOR TESTING.
    METHODS conv_rounds_up         FOR TESTING.
    METHODS exact_keeps_whole      FOR TESTING.
    METHODS exact_rejects_fraction FOR TESTING.
    METHODS converts_to_text       FOR TESTING.
    METHODS parses_digit_string    FOR TESTING.
    METHODS exact_ratio_quarter    FOR TESTING.
    METHODS exact_ratio_third_fails FOR TESTING.
ENDCLASS.


CLASS ltcl_convert IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD conv_rounds_down.
    cl_abap_unit_assert=>assert_equals(
      act = cut->to_int_rounded( CONV #( '2.4' ) ) exp = 2 ).
  ENDMETHOD.

  METHOD conv_rounds_up.
    cl_abap_unit_assert=>assert_equals(
      act = cut->to_int_rounded( CONV #( '2.6' ) ) exp = 3 ).
  ENDMETHOD.

  METHOD exact_keeps_whole.
    cl_abap_unit_assert=>assert_equals(
      act = cut->to_int_lossless( CONV #( '4' ) ) exp = 4 ).
  ENDMETHOD.

  METHOD exact_rejects_fraction.
    " GIVEN 4.5 / WHEN EXACT i / THEN 무손실 불가 → 예외
    TRY.
        cut->to_int_lossless( CONV #( '4.5' ) ).
        cl_abap_unit_assert=>fail( msg = 'EXACT가 예외를 던져야 한다' ).
      CATCH cx_sy_conversion_error.
    ENDTRY.
  ENDMETHOD.

  METHOD converts_to_text.
    cl_abap_unit_assert=>assert_equals(
      act = cut->to_text( 42 ) exp = `42` ).
  ENDMETHOD.

  METHOD parses_digit_string.
    " GIVEN '0000000042' (n 10) / WHEN CONV i / THEN 42
    cl_abap_unit_assert=>assert_equals(
      act = cut->digits_to_int( '0000000042' ) exp = 42 ).
  ENDMETHOD.

  METHOD exact_ratio_quarter.
    " GIVEN 1/4 = 0.25 (정확) / THEN 통과
    cl_abap_unit_assert=>assert_equals(
      act = cut->exact_ratio( dividend = 1 divisor = 4 )
      exp = CONV decfloat34( '0.25' ) ).
  ENDMETHOD.

  METHOD exact_ratio_third_fails.
    " GIVEN 1/3 = 무한소수 / THEN 무손실 불가 → 예외
    TRY.
        cut->exact_ratio( dividend = 1 divisor = 3 ).
        cl_abap_unit_assert=>fail( msg = '1/3은 EXACT 실패여야 한다' ).
      CATCH cx_sy_conversion_error.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
