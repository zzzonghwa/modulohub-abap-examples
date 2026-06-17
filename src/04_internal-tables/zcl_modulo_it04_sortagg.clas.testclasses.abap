CLASS ltcl_sortagg DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_it04_sortagg.
    METHODS setup.
    METHODS top_by_amount      FOR TESTING.
    METHODS multi_field_order  FOR TESTING.
    METHODS distinct_category  FOR TESTING.
    METHODS distinct_city      FOR TESTING.
    METHODS collect_sums_group FOR TESTING.
    METHODS collect_miss_zero  FOR TESTING.
    METHODS group_by_max_total FOR TESTING.
ENDCLASS.


CLASS ltcl_sortagg IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD top_by_amount.
    cl_abap_unit_assert=>assert_equals( act = cut->sort_by_amount_desc( ) exp = 4 ).
  ENDMETHOD.

  METHOD multi_field_order.
    cl_abap_unit_assert=>assert_equals(
      act = cut->sort_multi( ) exp = `6,8,2,4,7,3,1,5` ).
  ENDMETHOD.

  METHOD distinct_category.
    cl_abap_unit_assert=>assert_equals( act = cut->dedup_categories( ) exp = 3 ).
  ENDMETHOD.

  METHOD distinct_city.
    cl_abap_unit_assert=>assert_equals( act = cut->distinct_cities( ) exp = 3 ).
  ENDMETHOD.

  METHOD collect_sums_group.
    DATA(expected) = CONV zcl_modulo_it04_sortagg=>amount( '60.00' ).
    cl_abap_unit_assert=>assert_equals( act = cut->collect_by_category( `BOOK` ) exp = expected ).
  ENDMETHOD.

  METHOD collect_miss_zero.
    DATA(expected) = CONV zcl_modulo_it04_sortagg=>amount( '0.00' ).
    cl_abap_unit_assert=>assert_equals( act = cut->collect_by_category( `NONE` ) exp = expected ).
  ENDMETHOD.

  METHOD group_by_max_total.
    DATA(expected) = CONV zcl_modulo_it04_sortagg=>amount( '150.00' ).
    cl_abap_unit_assert=>assert_equals( act = cut->group_by_totals( ) exp = expected ).
  ENDMETHOD.
ENDCLASS.
