CLASS ltcl_ctorexpr DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_it05_ctorexpr.
    METHODS setup.
    METHODS comprehension_names FOR TESTING.
    METHODS for_where_filters   FOR TESTING.
    METHODS reduce_sum_salary   FOR TESTING.
    METHODS reduce_max          FOR TESTING.
    METHODS filter_counts_dept  FOR TESTING.
    METHODS corresponding_maps  FOR TESTING.
    METHODS nested_for_product  FOR TESTING.
ENDCLASS.


CLASS ltcl_ctorexpr IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD comprehension_names.
    cl_abap_unit_assert=>assert_equals(
      act = cut->map_names( ) exp = `Kim,Lee,Park,Choi,Ahn,Yoon` ).
  ENDMETHOD.

  METHOD for_where_filters.
    cl_abap_unit_assert=>assert_equals(
      act = cut->names_where_active( ) exp = `Kim,Lee,Choi,Ahn` ).
  ENDMETHOD.

  METHOD reduce_sum_salary.
    DATA(expected) = CONV zcl_modulo_it05_ctorexpr=>salary( '320.00' ).
    cl_abap_unit_assert=>assert_equals( act = cut->reduce_total_salary( ) exp = expected ).
  ENDMETHOD.

  METHOD reduce_max.
    DATA(expected) = CONV zcl_modulo_it05_ctorexpr=>salary( '70.00' ).
    cl_abap_unit_assert=>assert_equals( act = cut->reduce_max_salary( ) exp = expected ).
  ENDMETHOD.

  METHOD filter_counts_dept.
    cl_abap_unit_assert=>assert_equals( act = cut->filter_by_dept( `ENG` ) exp = 3 ).
  ENDMETHOD.

  METHOD corresponding_maps.
    cl_abap_unit_assert=>assert_equals( act = cut->correspond_to_cards( ) exp = `Kim` ).
  ENDMETHOD.

  METHOD nested_for_product.
    cl_abap_unit_assert=>assert_equals( act = cut->nested_for( ) exp = 6 ).
  ENDMETHOD.
ENDCLASS.
