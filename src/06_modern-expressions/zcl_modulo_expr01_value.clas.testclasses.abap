CLASS ltcl_value DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_expr01_value.
    METHODS setup.
    METHODS for_then_until    FOR TESTING.
    METHODS base_extends      FOR TESTING.
    METHODS range_in_match    FOR TESTING.
    METHODS range_in_miss     FOR TESTING.
    METHODS corresponding_map FOR TESTING.
ENDCLASS.


CLASS ltcl_value IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD for_then_until.
    cl_abap_unit_assert=>assert_equals( act = cut->squares_up_to( 4 ) exp = `1,4,9,16` ).
  ENDMETHOD.

  METHOD base_extends.
    cl_abap_unit_assert=>assert_equals( act = cut->extend_with_base( ) exp = 4 ).
  ENDMETHOD.

  METHOD range_in_match.
    cl_abap_unit_assert=>assert_equals( act = cut->range_includes( 15 ) exp = abap_true ).
  ENDMETHOD.

  METHOD range_in_miss.
    cl_abap_unit_assert=>assert_equals( act = cut->range_includes( 7 ) exp = abap_false ).
  ENDMETHOD.

  METHOD corresponding_map.
    cl_abap_unit_assert=>assert_equals( act = cut->map_employee( ) exp = `1 Kim 5000` ).
  ENDMETHOD.
ENDCLASS.
