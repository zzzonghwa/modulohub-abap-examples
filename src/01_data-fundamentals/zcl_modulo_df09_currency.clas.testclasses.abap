CLASS ltcl_currency DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_df09_currency.
    METHODS setup.
    METHODS adds_usd_amounts     FOR TESTING.
    METHODS scales_usd_amount    FOR TESTING.
    METHODS computes_percent     FOR TESTING.
    METHODS converts_to_krw      FOR TESTING.
    METHODS krw_has_no_decimals  FOR TESTING.
    METHODS splits_evenly        FOR TESTING.
    METHODS split_zero_raises    FOR TESTING.
    METHODS detects_zero_amount  FOR TESTING.
ENDCLASS.


CLASS ltcl_currency IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD adds_usd_amounts.
    cl_abap_unit_assert=>assert_equals(
      act = cut->add_usd( first = CONV #( '10.50' ) second = CONV #( '4.50' ) )
      exp = CONV zcl_modulo_df09_currency=>amount_usd( '15.00' ) ).
  ENDMETHOD.

  METHOD scales_usd_amount.
    cl_abap_unit_assert=>assert_equals(
      act = cut->scale_usd( amount = CONV #( '100.00' ) rate = CONV #( '1.5' ) )
      exp = CONV zcl_modulo_df09_currency=>amount_usd( '150.00' ) ).
  ENDMETHOD.

  METHOD computes_percent.
    " GIVEN 200.00 의 10% / THEN 20.00
    cl_abap_unit_assert=>assert_equals(
      act = cut->percent_of( amount = CONV #( '200.00' ) percent = CONV #( '10' ) )
      exp = CONV zcl_modulo_df09_currency=>amount_usd( '20.00' ) ).
  ENDMETHOD.

  METHOD converts_to_krw.
    cl_abap_unit_assert=>assert_equals(
      act = cut->to_krw( usd = CONV #( '10.00' ) rate = CONV #( '1300' ) )
      exp = CONV zcl_modulo_df09_currency=>amount_krw( '13000' ) ).
  ENDMETHOD.

  METHOD krw_has_no_decimals.
    cl_abap_unit_assert=>assert_equals(
      act = cut->to_krw( usd = CONV #( '1.00' ) rate = CONV #( '1234.56' ) )
      exp = CONV zcl_modulo_df09_currency=>amount_krw( '1235' ) ).
  ENDMETHOD.

  METHOD splits_evenly.
    " GIVEN 30.00 을 4명 / THEN 7.50
    cl_abap_unit_assert=>assert_equals(
      act = cut->split_evenly( amount = CONV #( '30.00' ) shares = 4 )
      exp = CONV zcl_modulo_df09_currency=>amount_usd( '7.50' ) ).
  ENDMETHOD.

  METHOD split_zero_raises.
    TRY.
        cut->split_evenly( amount = CONV #( '30.00' ) shares = 0 ).
        cl_abap_unit_assert=>fail( msg = '0명 분할은 예외여야 한다' ).
      CATCH cx_parameter_invalid_range.
    ENDTRY.
  ENDMETHOD.

  METHOD detects_zero_amount.
    cl_abap_unit_assert=>assert_true( cut->is_zero( 0 ) ).
    cl_abap_unit_assert=>assert_false( cut->is_zero( CONV #( '0.01' ) ) ).
  ENDMETHOD.
ENDCLASS.
