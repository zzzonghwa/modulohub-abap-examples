CLASS ltcl_control DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_pf01_control.
    METHODS setup.
    METHODS grade_a_for_high      FOR TESTING.
    METHODS grade_b_for_mid       FOR TESTING.
    METHODS grade_c_for_low       FOR TESTING.
    METHODS names_a_weekday       FOR TESTING.
    METHODS unknown_out_of_range  FOR TESTING.
    METHODS factorial_of_five     FOR TESTING.
    METHODS factorial_of_zero     FOR TESTING.
    METHODS factorial_negative_raises FOR TESTING.
    METHODS sums_digits           FOR TESTING.
    METHODS sums_only_positives   FOR TESTING.
    METHODS finds_first_over      FOR TESTING.
    METHODS none_over_raises      FOR TESTING.
    METHODS builds_fizzbuzz       FOR TESTING.
ENDCLASS.


CLASS ltcl_control IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD grade_a_for_high.
    cl_abap_unit_assert=>assert_equals( act = cut->classify( 95 ) exp = 'A' ).
  ENDMETHOD.

  METHOD grade_b_for_mid.
    cl_abap_unit_assert=>assert_equals( act = cut->classify( 85 ) exp = 'B' ).
  ENDMETHOD.

  METHOD grade_c_for_low.
    cl_abap_unit_assert=>assert_equals( act = cut->classify( 50 ) exp = 'C' ).
  ENDMETHOD.

  METHOD names_a_weekday.
    cl_abap_unit_assert=>assert_equals( act = cut->weekday_name( 1 ) exp = `Monday` ).
  ENDMETHOD.

  METHOD unknown_out_of_range.
    cl_abap_unit_assert=>assert_equals( act = cut->weekday_name( 8 ) exp = `Unknown` ).
  ENDMETHOD.

  METHOD factorial_of_five.
    cl_abap_unit_assert=>assert_equals( act = cut->factorial( 5 ) exp = 120 ).
  ENDMETHOD.

  METHOD factorial_of_zero.
    cl_abap_unit_assert=>assert_equals( act = cut->factorial( 0 ) exp = 1 ).
  ENDMETHOD.

  METHOD factorial_negative_raises.
    TRY.
        cut->factorial( -1 ).
        cl_abap_unit_assert=>fail( msg = '음수 팩토리얼은 예외여야 한다' ).
      CATCH cx_parameter_invalid_range.
    ENDTRY.
  ENDMETHOD.

  METHOD sums_digits.
    " GIVEN 12345 / WHEN WHILE 자릿수 합 / THEN 15
    cl_abap_unit_assert=>assert_equals( act = cut->digit_sum( 12345 ) exp = 15 ).
  ENDMETHOD.

  METHOD sums_only_positives.
    DATA(numbers) = VALUE zcl_modulo_pf01_control=>number_list(
      ( 1 ) ( -5 ) ( 2 ) ( 0 ) ( 3 ) ).
    cl_abap_unit_assert=>assert_equals( act = cut->sum_positives( numbers ) exp = 6 ).
  ENDMETHOD.

  METHOD finds_first_over.
    DATA(numbers) = VALUE zcl_modulo_pf01_control=>number_list(
      ( 3 ) ( 8 ) ( 5 ) ( 10 ) ).
    cl_abap_unit_assert=>assert_equals(
      act = cut->first_over( numbers = numbers threshold = 7 ) exp = 8 ).
  ENDMETHOD.

  METHOD none_over_raises.
    DATA(numbers) = VALUE zcl_modulo_pf01_control=>number_list( ( 1 ) ( 2 ) ).
    TRY.
        cut->first_over( numbers = numbers threshold = 9 ).
        cl_abap_unit_assert=>fail( msg = '초과값 없으면 예외여야 한다' ).
      CATCH cx_parameter_invalid_range.
    ENDTRY.
  ENDMETHOD.

  METHOD builds_fizzbuzz.
    " GIVEN n=15 / THEN 경계값들이 규칙대로
    DATA(lines) = cut->fizzbuzz( 15 ).
    cl_abap_unit_assert=>assert_equals( act = lines[ 1 ]  exp = `1` ).
    cl_abap_unit_assert=>assert_equals( act = lines[ 3 ]  exp = `Fizz` ).
    cl_abap_unit_assert=>assert_equals( act = lines[ 5 ]  exp = `Buzz` ).
    cl_abap_unit_assert=>assert_equals( act = lines[ 15 ] exp = `FizzBuzz` ).
  ENDMETHOD.
ENDCLASS.
