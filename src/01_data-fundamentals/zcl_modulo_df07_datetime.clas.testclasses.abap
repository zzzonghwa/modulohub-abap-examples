CLASS ltcl_datetime DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_df07_datetime.
    METHODS setup.
    METHODS counts_days_in_january FOR TESTING.
    METHODS checked_rejects_order  FOR TESTING.
    METHODS adds_days              FOR TESTING.
    METHODS finds_first_of_month   FOR TESTING.
    METHODS month_end_is_true      FOR TESTING.
    METHODS mid_month_is_false     FOR TESTING.
    METHODS computes_quarter       FOR TESTING.
ENDCLASS.


CLASS ltcl_datetime IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD counts_days_in_january.
    cl_abap_unit_assert=>assert_equals(
      act = cut->days_between( from_date = CONV d( '20260101' )
                               to_date   = CONV d( '20260201' ) )
      exp = 31 ).
  ENDMETHOD.

  METHOD checked_rejects_order.
    " GIVEN to < from / THEN 가드 예외
    TRY.
        cut->days_between_checked( from_date = CONV d( '20260201' )
                                   to_date   = CONV d( '20260101' ) ).
        cl_abap_unit_assert=>fail( msg = '역순 날짜는 예외여야 한다' ).
      CATCH cx_parameter_invalid_range.
    ENDTRY.
  ENDMETHOD.

  METHOD adds_days.
    cl_abap_unit_assert=>assert_equals(
      act = cut->add_days( date = CONV d( '20260101' ) days = 31 )
      exp = CONV d( '20260201' ) ).
  ENDMETHOD.

  METHOD finds_first_of_month.
    cl_abap_unit_assert=>assert_equals(
      act = cut->first_day_of_month( CONV d( '20260217' ) )
      exp = CONV d( '20260201' ) ).
  ENDMETHOD.

  METHOD month_end_is_true.
    cl_abap_unit_assert=>assert_true(
      cut->is_month_end( CONV d( '20260131' ) ) ).
  ENDMETHOD.

  METHOD mid_month_is_false.
    cl_abap_unit_assert=>assert_false(
      cut->is_month_end( CONV d( '20260130' ) ) ).
  ENDMETHOD.

  METHOD computes_quarter.
    cl_abap_unit_assert=>assert_equals(
      act = cut->quarter_of( CONV d( '20260101' ) ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals(
      act = cut->quarter_of( CONV d( '20260815' ) ) exp = 3 ).
    cl_abap_unit_assert=>assert_equals(
      act = cut->quarter_of( CONV d( '20261231' ) ) exp = 4 ).
  ENDMETHOD.
ENDCLASS.
