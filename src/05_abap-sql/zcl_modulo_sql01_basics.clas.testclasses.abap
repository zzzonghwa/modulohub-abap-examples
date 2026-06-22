CLASS ltcl_basics DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_sql01_basics.
    METHODS setup.
    METHODS into_table_counts_rows  FOR TESTING.
    METHODS scalar_counts_rows      FOR TESTING.
    METHODS single_row_hit          FOR TESTING.
    METHODS single_row_miss_zero    FOR TESTING.
    METHODS subrc_hit_and_empty     FOR TESTING.
    METHODS star_struct_summary     FOR TESTING.
    METHODS corresponding_maps_seats FOR TESTING.
    METHODS appending_accumulates   FOR TESTING.
    METHODS loop_sums_seats         FOR TESTING.
    METHODS top_row_by_seats        FOR TESTING.
ENDCLASS.


CLASS ltcl_basics IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD into_table_counts_rows.
    cl_abap_unit_assert=>assert_equals( act = cut->read_into_table( ) exp = 4 ).
  ENDMETHOD.

  METHOD scalar_counts_rows.
    cl_abap_unit_assert=>assert_equals( act = cut->count_into_scalar( ) exp = 4 ).
  ENDMETHOD.

  METHOD single_row_hit.
    cl_abap_unit_assert=>assert_equals(
      act = cut->read_single_row( carrier = 'AA' connid = '0017' ) exp = 380 ).
  ENDMETHOD.

  METHOD single_row_miss_zero.
    cl_abap_unit_assert=>assert_equals(
      act = cut->read_single_row( carrier = 'ZZ' connid = '9999' ) exp = 0 ).
  ENDMETHOD.

  METHOD subrc_hit_and_empty.
    " W-12: hit -> sy-subrc 0, 빈 결과 -> 4.
    cl_abap_unit_assert=>assert_equals(
      act = cut->single_subrc( carrier = 'AA' connid = '0017' ) exp = 0 ).
    cl_abap_unit_assert=>assert_equals(
      act = cut->single_subrc( carrier = 'ZZ' connid = '9999' ) exp = 4 ).
  ENDMETHOD.

  METHOD star_struct_summary.
    " 0400 -> LH 0400 280.
    cl_abap_unit_assert=>assert_equals(
      act = cut->read_star_struct( '0400' ) exp = |LH 0400 280| ).
  ENDMETHOD.

  METHOD corresponding_maps_seats.
    cl_abap_unit_assert=>assert_equals(
      act = cut->read_corresponding( '0017' ) exp = 380 ).
  ENDMETHOD.

  METHOD appending_accumulates.
    " AA 2건 + LH 2건 = 4.
    cl_abap_unit_assert=>assert_equals( act = cut->append_two_selects( ) exp = 4 ).
  ENDMETHOD.

  METHOD loop_sums_seats.
    " 380 + 320 + 280 + 180 = 1160.
    cl_abap_unit_assert=>assert_equals( act = cut->sum_via_loop( ) exp = 1160 ).
  ENDMETHOD.

  METHOD top_row_by_seats.
    " 최다 좌석 380 -> connid 0017.
    cl_abap_unit_assert=>assert_equals( act = cut->top_one_row( ) exp = '0017' ).
  ENDMETHOD.
ENDCLASS.


CLASS ltcl_db_source DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    " osql SQL 테스트 더블 — 실제 DB를 건드리지 않고 Z 테이블에 결정적 데이터를 주입한다.
    CLASS-DATA environment TYPE REF TO if_osql_test_environment.
    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.

    DATA cut TYPE REF TO zcl_modulo_sql01_basics.
    METHODS setup.
    METHODS db_table_count   FOR TESTING.
    METHODS db_single_hit    FOR TESTING.
    METHODS db_single_miss   FOR TESTING.
ENDCLASS.


CLASS ltcl_db_source IMPLEMENTATION.
  METHOD class_setup.
    environment = cl_osql_test_environment=>create(
      i_dependency_list = VALUE #( ( 'ZMODULO_CARRIER' ) ) ).
  ENDMETHOD.

  METHOD class_teardown.
    environment->destroy( ).
  ENDMETHOD.

  METHOD setup.
    DATA carriers TYPE STANDARD TABLE OF zmodulo_carrier WITH EMPTY KEY.

    environment->clear_doubles( ).
    cut = NEW #( ).

    carriers = VALUE #( ( carrid = 'AA' carrname = 'Alpha Air' )
                        ( carrid = 'LH' carrname = 'Luft Air' )
                        ( carrid = 'UA' carrname = 'Union Air' ) ).
    environment->insert_test_data( i_data = carriers ).
  ENDMETHOD.

  METHOD db_table_count.
    " DDIC 테이블 소스(W-01): 더블에 주입한 항공사 3건.
    cl_abap_unit_assert=>assert_equals( act = cut->count_db_table( ) exp = 3 ).
  ENDMETHOD.

  METHOD db_single_hit.
    cl_abap_unit_assert=>assert_equals(
      act = cut->read_db_single( 'AA' ) exp = 'Alpha Air' ).
  ENDMETHOD.

  METHOD db_single_miss.
    cl_abap_unit_assert=>assert_equals( act = cut->read_db_single( 'ZZ' ) exp = space ).
  ENDMETHOD.
ENDCLASS.
