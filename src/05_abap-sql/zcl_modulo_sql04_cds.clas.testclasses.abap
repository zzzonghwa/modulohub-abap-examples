CLASS ltcl_cds DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_sql04_cds.
    METHODS setup.
    METHODS consume_counts_rows  FOR TESTING.
    METHODS single_seats_hit     FOR TESTING.
    METHODS single_seats_miss    FOR TESTING.
    METHODS load_factor_full     FOR TESTING.
    METHODS load_factor_partial  FOR TESTING.
    METHODS load_factor_miss     FOR TESTING.
    METHODS bands_case_labels    FOR TESTING.
    METHODS access_control_filter FOR TESTING.
    METHODS name_via_association  FOR TESTING.
    METHODS name_miss_blank       FOR TESTING.
ENDCLASS.


CLASS ltcl_cds IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD consume_counts_rows.
    cl_abap_unit_assert=>assert_equals( act = cut->consume_count( ) exp = 5 ).
  ENDMETHOD.

  METHOD single_seats_hit.
    cl_abap_unit_assert=>assert_equals(
      act = cut->single_maximum_seats( carrier = 'AA' connid = '0017' ) exp = 380 ).
  ENDMETHOD.

  METHOD single_seats_miss.
    cl_abap_unit_assert=>assert_equals(
      act = cut->single_maximum_seats( carrier = 'ZZ' connid = '9999' ) exp = 0 ).
  ENDMETHOD.

  METHOD load_factor_full.
    cl_abap_unit_assert=>assert_equals(
      act = cut->load_factor_percent( carrier = 'LH' connid = '0400' ) exp = 100 ).
  ENDMETHOD.

  METHOD load_factor_partial.
    " 342 * 100 / 380 = 90.
    cl_abap_unit_assert=>assert_equals(
      act = cut->load_factor_percent( carrier = 'AA' connid = '0017' ) exp = 90 ).
  ENDMETHOD.

  METHOD load_factor_miss.
    cl_abap_unit_assert=>assert_equals(
      act = cut->load_factor_percent( carrier = 'ZZ' connid = '9999' ) exp = 0 ).
  ENDMETHOD.

  METHOD bands_case_labels.
    " 정렬: AA/0017(occ 342)=FULL, AA/0064(240)=HIGH, LH/0400(280)=HIGH,
    "       LH/2402(90)=LOW, UA/0941(180)=HIGH.
    DATA(bands) = cut->load_bands( ).
    cl_abap_unit_assert=>assert_equals( act = lines( bands ) exp = 5 ).
    cl_abap_unit_assert=>assert_equals( act = bands[ 1 ]-band exp = `FULL` ).
    cl_abap_unit_assert=>assert_equals( act = bands[ 2 ]-band exp = `HIGH` ).
    cl_abap_unit_assert=>assert_equals( act = bands[ 4 ]-band exp = `LOW` ).
  ENDMETHOD.

  METHOD access_control_filter.
    " access condition(AA·LH 허용): AA 2건 + LH 2건 = 4, UA 제외.
    cl_abap_unit_assert=>assert_equals( act = cut->authorized_count( ) exp = 4 ).
  ENDMETHOD.

  METHOD name_via_association.
    cl_abap_unit_assert=>assert_equals( act = cut->carrier_name( 'AA' ) exp = 'Alpha Air' ).
  ENDMETHOD.

  METHOD name_miss_blank.
    cl_abap_unit_assert=>assert_equals( act = cut->carrier_name( 'XX' ) exp = space ).
  ENDMETHOD.
ENDCLASS.


CLASS ltcl_cds_path DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    " osql SQL 테스트 더블 — 경로식(JOIN) 등가 메서드는 실 Z 테이블을 읽으므로 더블로 주입한다.
    CLASS-DATA environment TYPE REF TO if_osql_test_environment.
    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.

    DATA cut TYPE REF TO zcl_modulo_sql04_cds.
    METHODS setup.
    METHODS path_text_join_rows FOR TESTING.
    METHODS base_only_no_join   FOR TESTING.
ENDCLASS.


CLASS ltcl_cds_path IMPLEMENTATION.
  METHOD class_setup.
    environment = cl_osql_test_environment=>create(
      i_dependency_list = VALUE #( ( 'ZMODULO_FLIGHT' ) ( 'ZMODULO_CARRIER' ) ) ).
  ENDMETHOD.

  METHOD class_teardown.
    environment->destroy( ).
  ENDMETHOD.

  METHOD setup.
    DATA carriers TYPE STANDARD TABLE OF zmodulo_carrier WITH EMPTY KEY.
    DATA flights  TYPE STANDARD TABLE OF zmodulo_flight WITH EMPTY KEY.

    environment->clear_doubles( ).
    cut = NEW #( ).

    carriers = VALUE #( ( carrid = 'AA' carrname = 'Alpha Air' )
                        ( carrid = 'LH' carrname = 'Luft Air' )
                        ( carrid = 'UA' carrname = 'Union Air' ) ).
    environment->insert_test_data( i_data = carriers ).

    flights = VALUE #( ( carrid = 'AA' connid = '0017' seatsmax = 380 seatsocc = 342 )
                       ( carrid = 'AA' connid = '0064' seatsmax = 320 seatsocc = 240 )
                       ( carrid = 'LH' connid = '0400' seatsmax = 280 seatsocc = 280 )
                       ( carrid = 'UA' connid = '0941' seatsmax = 240 seatsocc = 180 ) ).
    environment->insert_test_data( i_data = flights ).
  ENDMETHOD.

  METHOD path_text_join_rows.
    " AA 항공편 2건 — 경로식 등가 INNER JOIN으로 텍스트와 함께 읽는다.
    cl_abap_unit_assert=>assert_equals( act = cut->path_text_rows( 'AA' ) exp = 2 ).
  ENDMETHOD.

  METHOD base_only_no_join.
    " 텍스트 미조인 base 단독 SELECT도 같은 AA 2건.
    cl_abap_unit_assert=>assert_equals( act = cut->base_only_rows( 'AA' ) exp = 2 ).
  ENDMETHOD.
ENDCLASS.
