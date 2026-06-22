CLASS ltcl_where DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_sql02_where.
    METHODS setup.
    METHODS min_seats_compare FOR TESTING.
    METHODS between_range      FOR TESTING.
    METHODS in_carrier_list    FOR TESTING.
    METHODS like_pattern       FOR TESTING.
    METHODS distinct_count     FOR TESTING.
    METHODS top_by_seats       FOR TESTING.
ENDCLASS.


CLASS ltcl_where IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD min_seats_compare.
    cl_abap_unit_assert=>assert_equals( act = cut->count_min_seats( 300 ) exp = 3 ).
  ENDMETHOD.

  METHOD between_range.
    cl_abap_unit_assert=>assert_equals(
      act = cut->count_between( low = 200 high = 330 ) exp = 4 ).
  ENDMETHOD.

  METHOD in_carrier_list.
    cl_abap_unit_assert=>assert_equals( act = cut->count_in_carriers( ) exp = 4 ).
  ENDMETHOD.

  METHOD like_pattern.
    cl_abap_unit_assert=>assert_equals( act = cut->count_like_carrier( `A%` ) exp = 2 ).
  ENDMETHOD.

  METHOD distinct_count.
    cl_abap_unit_assert=>assert_equals( act = cut->distinct_carriers( ) exp = 3 ).
  ENDMETHOD.

  METHOD top_by_seats.
    cl_abap_unit_assert=>assert_equals( act = cut->top_connid_by_seats( ) exp = '0017' ).
  ENDMETHOD.
ENDCLASS.
