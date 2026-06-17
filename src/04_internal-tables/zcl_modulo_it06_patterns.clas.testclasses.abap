CLASS ltcl_patterns DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_it06_patterns.
    METHODS setup.
    METHODS grand_total_sums    FOR TESTING.
    METHODS join_fills_customer FOR TESTING.
    METHODS join_row_count      FOR TESTING.
    METHODS customer_of_order   FOR TESTING.
    METHODS order_miss_is_blank FOR TESTING.
    METHODS lookup_map          FOR TESTING.
    METHODS top_n_by_amount     FOR TESTING.
    METHODS summary_book_group  FOR TESTING.
    METHODS summary_tech_total  FOR TESTING.
ENDCLASS.


CLASS ltcl_patterns IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD grand_total_sums.
    DATA(expected) = CONV zcl_modulo_it06_patterns=>amount( '200.00' ).
    cl_abap_unit_assert=>assert_equals( act = cut->grand_total( ) exp = expected ).
  ENDMETHOD.

  METHOD join_fills_customer.
    DATA(list) = cut->enrich_orders( ).
    cl_abap_unit_assert=>assert_equals( act = list[ order_id = 3 ]-city exp = `Seoul` ).
  ENDMETHOD.

  METHOD join_row_count.
    cl_abap_unit_assert=>assert_equals( act = lines( cut->enrich_orders( ) ) exp = 6 ).
  ENDMETHOD.

  METHOD customer_of_order.
    cl_abap_unit_assert=>assert_equals( act = cut->customer_of_order( 3 ) exp = `Kim` ).
  ENDMETHOD.

  METHOD order_miss_is_blank.
    cl_abap_unit_assert=>assert_initial( cut->customer_of_order( 99 ) ).
  ENDMETHOD.

  METHOD lookup_map.
    cl_abap_unit_assert=>assert_equals( act = cut->lookup_map_name( 2 ) exp = `Lee` ).
  ENDMETHOD.

  METHOD top_n_by_amount.
    cl_abap_unit_assert=>assert_equals( act = cut->top_n( 2 ) exp = `3,5` ).
  ENDMETHOD.

  METHOD summary_book_group.
    DATA(rep) = cut->summary_by_category( ).
    DATA(book) = rep[ category = `BOOK` ].
    cl_abap_unit_assert=>assert_equals( act = book-count exp = 2 ).
  ENDMETHOD.

  METHOD summary_tech_total.
    DATA(rep) = cut->summary_by_category( ).
    DATA(tech) = rep[ category = `TECH` ].
    DATA(expected) = CONV zcl_modulo_it06_patterns=>amount( '150.00' ).
    cl_abap_unit_assert=>assert_equals( act = tech-total exp = expected ).
  ENDMETHOD.
ENDCLASS.
