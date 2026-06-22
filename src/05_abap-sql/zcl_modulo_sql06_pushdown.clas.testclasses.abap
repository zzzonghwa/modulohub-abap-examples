CLASS ltcl_pushdown DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    " osql SQL 테스트 더블 — 실 Z 테이블에 결정적 데이터를 주입한다(버퍼/FAE/힌트 데모용).
    CLASS-DATA environment TYPE REF TO if_osql_test_environment.
    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.

    DATA cut TYPE REF TO zcl_modulo_sql06_pushdown.
    METHODS setup.
    METHODS sum_pushdown        FOR TESTING.
    METHODS filter_count        FOR TESTING.
    METHODS pushdown_eq_abap    FOR TESTING.
    METHODS case_pushdown       FOR TESTING.
    METHODS exists_hit_miss     FOR TESTING.
    METHODS for_all_entries     FOR TESTING.
    METHODS bypassing_buffer    FOR TESTING.
    METHODS db_hint_count       FOR TESTING.
ENDCLASS.


CLASS ltcl_pushdown IMPLEMENTATION.
  METHOD class_setup.
    environment = cl_osql_test_environment=>create(
      i_dependency_list = VALUE #( ( 'ZMODULO_FLIGHT' ) ) ).
  ENDMETHOD.

  METHOD class_teardown.
    environment->destroy( ).
  ENDMETHOD.

  METHOD setup.
    DATA flights TYPE STANDARD TABLE OF zmodulo_flight WITH EMPTY KEY.

    environment->clear_doubles( ).
    cut = NEW #( ).

    " 실 Z 테이블 더블 — itab 데모(sample)와 분리된 4건. carrid별: AA(2)·LH(1)·UA(1).
    flights = VALUE #( ( carrid = 'AA' connid = '0017' seatsmax = 380 seatsocc = 342 )
                       ( carrid = 'AA' connid = '0064' seatsmax = 320 seatsocc = 240 )
                       ( carrid = 'LH' connid = '0400' seatsmax = 280 seatsocc = 280 )
                       ( carrid = 'UA' connid = '0941' seatsmax = 240 seatsocc = 180 ) ).
    environment->insert_test_data( i_data = flights ).
  ENDMETHOD.

  METHOD sum_pushdown.
    " itab sample 6건 좌석 합: 380+320+280+180+240+300 = 1700.
    cl_abap_unit_assert=>assert_equals( act = cut->total_seats_pushdown( ) exp = 1700 ).
  ENDMETHOD.

  METHOD filter_count.
    " seats >= 300: 380·320·300 -> 3.
    cl_abap_unit_assert=>assert_equals( act = cut->high_demand_pushdown( 300 ) exp = 3 ).
  ENDMETHOD.

  METHOD pushdown_eq_abap.
    " 같은 임계치에서 pushdown과 ABAP loop 결과가 동일함을 보증한다.
    cl_abap_unit_assert=>assert_equals(
      act = cut->high_demand_in_abap( 250 ) exp = cut->high_demand_pushdown( 250 ) ).
  ENDMETHOD.

  METHOD case_pushdown.
    " SELECT CASE로 BIG(>=300) 분류: 380·320·300 -> 3.
    cl_abap_unit_assert=>assert_equals( act = cut->big_flights_pushdown( ) exp = 3 ).
  ENDMETHOD.

  METHOD exists_hit_miss.
    cl_abap_unit_assert=>assert_equals( act = cut->flight_exists( 'AA' ) exp = abap_true ).
    cl_abap_unit_assert=>assert_equals( act = cut->flight_exists( 'ZZ' ) exp = abap_false ).
  ENDMETHOD.

  METHOD for_all_entries.
    " driver AA·LH -> AA(2)+LH(1) = 3 (UA 제외).
    cl_abap_unit_assert=>assert_equals(
      act = cut->flights_for_carriers( VALUE #( ( 'AA' ) ( 'LH' ) ) ) exp = 3 ).
    " 빈 driver는 가드로 0(FAE의 "빈 driver=전체" 함정 회피).
    cl_abap_unit_assert=>assert_equals(
      act = cut->flights_for_carriers( VALUE #( ) ) exp = 0 ).
  ENDMETHOD.

  METHOD bypassing_buffer.
    " 버퍼 우회 전체 카운트 = 더블 4건.
    cl_abap_unit_assert=>assert_equals( act = cut->count_bypassing_buffer( ) exp = 4 ).
  ENDMETHOD.

  METHOD db_hint_count.
    " 힌트는 결과 불변 — 힌트 부여 카운트도 4건.
    cl_abap_unit_assert=>assert_equals( act = cut->count_with_db_hint( ) exp = 4 ).
  ENDMETHOD.
ENDCLASS.
