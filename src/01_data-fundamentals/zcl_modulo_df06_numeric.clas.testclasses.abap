CLASS ltcl_numeric DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_df06_numeric.
    METHODS setup.
    METHODS div_drops_remainder  FOR TESTING.
    METHODS mod_returns_rest     FOR TESTING.
    METHODS safe_div_works       FOR TESTING.
    METHODS safe_div_zero_raises FOR TESTING.
    METHODS ipow_stays_integer   FOR TESTING.
    METHODS ratio_keeps_decimal  FOR TESTING.
    METHODS absolute_of_negative FOR TESTING.
    METHODS sign_of_values       FOR TESTING.
    METHODS fraction_part        FOR TESTING.
    METHODS truncates_toward_zero FOR TESTING.
ENDCLASS.


CLASS ltcl_numeric IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD div_drops_remainder.
    cl_abap_unit_assert=>assert_equals(
      act = cut->quotient( dividend = 7 divisor = 2 ) exp = 3 ).
  ENDMETHOD.

  METHOD mod_returns_rest.
    cl_abap_unit_assert=>assert_equals(
      act = cut->remainder( dividend = 7 divisor = 2 ) exp = 1 ).
  ENDMETHOD.

  METHOD safe_div_works.
    cl_abap_unit_assert=>assert_equals(
      act = cut->safe_quotient( dividend = 8 divisor = 2 ) exp = 4 ).
  ENDMETHOD.

  METHOD safe_div_zero_raises.
    " GIVEN 0으로 나눔 / THEN 가드 예외
    TRY.
        cut->safe_quotient( dividend = 8 divisor = 0 ).
        cl_abap_unit_assert=>fail( msg = '0 나눗셈은 예외여야 한다' ).
      CATCH cx_sy_zerodivide.
    ENDTRY.
  ENDMETHOD.

  METHOD ipow_stays_integer.
    cl_abap_unit_assert=>assert_equals(
      act = cut->power( base = 2 exponent = 5 ) exp = 32 ).
  ENDMETHOD.

  METHOD ratio_keeps_decimal.
    cl_abap_unit_assert=>assert_equals(
      act = cut->ratio( dividend = 1 divisor = 4 )
      exp = CONV decfloat34( '0.25' ) ).
  ENDMETHOD.

  METHOD absolute_of_negative.
    cl_abap_unit_assert=>assert_equals( act = cut->absolute( -5 ) exp = 5 ).
  ENDMETHOD.

  METHOD sign_of_values.
    cl_abap_unit_assert=>assert_equals( act = cut->sign_of( -9 ) exp = -1 ).
    cl_abap_unit_assert=>assert_equals( act = cut->sign_of( 0 )  exp = 0 ).
    cl_abap_unit_assert=>assert_equals( act = cut->sign_of( 9 )  exp = 1 ).
  ENDMETHOD.

  METHOD fraction_part.
    cl_abap_unit_assert=>assert_equals(
      act = cut->fraction( CONV decfloat34( '3.25' ) )
      exp = CONV decfloat34( '0.25' ) ).
  ENDMETHOD.

  METHOD truncates_toward_zero.
    cl_abap_unit_assert=>assert_equals(
      act = cut->truncate( CONV decfloat34( '3.9' ) ) exp = 3 ).
    cl_abap_unit_assert=>assert_equals(
      act = cut->truncate( CONV decfloat34( '-3.9' ) ) exp = -3 ).
  ENDMETHOD.
ENDCLASS.
