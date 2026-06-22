CLASS ltcl_cond DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_expr02_cond.
    METHODS setup.
    METHODS cond_ranges      FOR TESTING.
    METHODS cond_abs_diff    FOR TESTING.
    METHODS switch_weekday   FOR TESTING.
    METHODS switch_no_match  FOR TESTING.
    METHODS switch_string    FOR TESTING.
ENDCLASS.


CLASS ltcl_cond IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD cond_ranges.
    cl_abap_unit_assert=>assert_equals( act = cut->classify_size( 5 )   exp = `small` ).
    cl_abap_unit_assert=>assert_equals( act = cut->classify_size( 50 )  exp = `medium` ).
    cl_abap_unit_assert=>assert_equals( act = cut->classify_size( 500 ) exp = `large` ).
  ENDMETHOD.

  METHOD cond_abs_diff.
    cl_abap_unit_assert=>assert_equals( act = cut->abs_diff( a = 3 b = 8 ) exp = 5 ).
    cl_abap_unit_assert=>assert_equals( act = cut->abs_diff( a = 8 b = 3 ) exp = 5 ).
  ENDMETHOD.

  METHOD switch_weekday.
    cl_abap_unit_assert=>assert_equals( act = cut->weekday_name( 7 ) exp = `Sun` ).
  ENDMETHOD.

  METHOD switch_no_match.
    cl_abap_unit_assert=>assert_equals( act = cut->weekday_name( 9 ) exp = `?` ).
  ENDMETHOD.

  METHOD switch_string.
    cl_abap_unit_assert=>assert_equals( act = cut->traffic_action( `green` ) exp = `go` ).
    cl_abap_unit_assert=>assert_equals( act = cut->traffic_action( `blue` )  exp = `?` ).
  ENDMETHOD.
ENDCLASS.
