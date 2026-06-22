CLASS ltcl_where DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_sql02_where.
    METHODS setup.
    METHODS min_seats_compare FOR TESTING.
    METHODS fields_form       FOR TESTING.
    METHODS between_range      FOR TESTING.
    METHODS in_carrier_list    FOR TESTING.
    METHODS like_pattern       FOR TESTING.
    METHODS host_expression    FOR TESTING.
    METHODS distinct_count     FOR TESTING.
    METHODS case_label         FOR TESTING.
    METHODS exists_hit_miss    FOR TESTING.
    METHODS dbcnt_rows         FOR TESTING.
    METHODS top_by_seats       FOR TESTING.
    METHODS offset_second_page FOR TESTING.
ENDCLASS.


CLASS ltcl_where IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD min_seats_compare.
    cl_abap_unit_assert=>assert_equals( act = cut->count_min_seats( 300 ) exp = 3 ).
  ENDMETHOD.

  METHOD fields_form.
    " 모던 FIELDS형: AA 항공편 2건(0017, 0064).
    cl_abap_unit_assert=>assert_equals( act = cut->count_by_carrier_fields( 'AA' ) exp = 2 ).
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

  METHOD host_expression.
    " base*2 = 300 초과: 380, 320 -> 2.
    cl_abap_unit_assert=>assert_equals( act = cut->count_above_double( 150 ) exp = 2 ).
  ENDMETHOD.

  METHOD distinct_count.
    cl_abap_unit_assert=>assert_equals( act = cut->distinct_carriers( ) exp = 3 ).
  ENDMETHOD.

  METHOD case_label.
    cl_abap_unit_assert=>assert_equals( act = cut->size_label( '0017' ) exp = `BIG` ).
    cl_abap_unit_assert=>assert_equals( act = cut->size_label( '2402' ) exp = `SMALL` ).
  ENDMETHOD.

  METHOD exists_hit_miss.
    cl_abap_unit_assert=>assert_equals( act = cut->carrier_exists( 'AA' ) exp = abap_true ).
    cl_abap_unit_assert=>assert_equals( act = cut->carrier_exists( 'ZZ' ) exp = abap_false ).
  ENDMETHOD.

  METHOD dbcnt_rows.
    cl_abap_unit_assert=>assert_equals( act = cut->rows_read( ) exp = 6 ).
  ENDMETHOD.

  METHOD top_by_seats.
    cl_abap_unit_assert=>assert_equals( act = cut->top_connid_by_seats( ) exp = '0017' ).
  ENDMETHOD.

  METHOD offset_second_page.
    " connid 정렬: 0017 0064 | 0400 0941 | 2402 3517 — OFFSET 2 UP TO 2 -> 2행.
    cl_abap_unit_assert=>assert_equals( act = cut->second_page( ) exp = 2 ).
  ENDMETHOD.
ENDCLASS.
