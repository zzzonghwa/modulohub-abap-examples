CLASS ltcl_sum_amounts DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_verify_loop.   "code under test
    METHODS setup.
    METHODS sums_a_list        FOR TESTING.
    METHODS empty_list_is_zero FOR TESTING.
ENDCLASS.


CLASS ltcl_sum_amounts IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD sums_a_list.
    " GIVEN three amounts
    DATA(amounts) = VALUE zcl_modulo_verify_loop=>amount_list(
      ( CONV #( '10.00' ) ) ( CONV #( '20.50' ) ) ( CONV #( '4.50' ) ) ).

    " WHEN they are summed
    DATA(total) = cut->sum_amounts( amounts ).

    " THEN the total is their sum
    cl_abap_unit_assert=>assert_equals(
      act = total
      exp = CONV zcl_modulo_verify_loop=>amount_value( '35.00' ) ).
  ENDMETHOD.

  METHOD empty_list_is_zero.
    " GIVEN no amounts / WHEN summed / THEN the total is zero
    DATA(total) = cut->sum_amounts( VALUE #( ) ).

    cl_abap_unit_assert=>assert_equals(
      act = total
      exp = CONV zcl_modulo_verify_loop=>amount_value( 0 ) ).
  ENDMETHOD.
ENDCLASS.
