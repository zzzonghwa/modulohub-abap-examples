CLASS ltcl_joinagg DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    " osql SQL 테스트 더블 — 실제 DB를 건드리지 않고 Z 테이블에 결정적 데이터를 주입한다.
    CLASS-DATA environment TYPE REF TO if_osql_test_environment.
    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.

    DATA cut TYPE REF TO zcl_modulo_sql03_joinagg.
    METHODS setup.
    METHODS inner_join_matches    FOR TESTING.
    METHODS left_join_finds_orphan FOR TESTING.
    METHODS group_sum_carrier     FOR TESTING.
    METHODS aggregate_max         FOR TESTING.
    METHODS having_over_threshold FOR TESTING.
ENDCLASS.


CLASS ltcl_joinagg IMPLEMENTATION.
  METHOD class_setup.
    " 더블 환경 생성 — 두 Z 테이블을 더블로 등록.
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

    " XX는 항공사 마스터가 없는 고아 항공편(LEFT JOIN 데모).
    flights = VALUE #( ( carrid = 'AA' connid = '0017' seatsmax = 380 seatsocc = 342 )
                       ( carrid = 'AA' connid = '0064' seatsmax = 320 seatsocc = 240 )
                       ( carrid = 'LH' connid = '0400' seatsmax = 280 seatsocc = 280 )
                       ( carrid = 'UA' connid = '0941' seatsmax = 240 seatsocc = 180 )
                       ( carrid = 'XX' connid = '0001' seatsmax = 100 seatsocc = 90 ) ).
    environment->insert_test_data( i_data = flights ).
  ENDMETHOD.

  METHOD inner_join_matches.
    " 마스터가 있는 항공편: AA(2)+LH(1)+UA(1)=4, XX 제외.
    cl_abap_unit_assert=>assert_equals( act = cut->inner_join_count( ) exp = 4 ).
  ENDMETHOD.

  METHOD left_join_finds_orphan.
    cl_abap_unit_assert=>assert_equals( act = cut->left_join_orphans( ) exp = 1 ).
  ENDMETHOD.

  METHOD group_sum_carrier.
    cl_abap_unit_assert=>assert_equals( act = cut->sum_seats_by_carrier( 'AA' ) exp = 700 ).
  ENDMETHOD.

  METHOD aggregate_max.
    cl_abap_unit_assert=>assert_equals( act = cut->max_seats( ) exp = 380 ).
  ENDMETHOD.

  METHOD having_over_threshold.
    " 합계 > 250: AA(700)·LH(280) -> 2 (UA 240, XX 100 제외).
    cl_abap_unit_assert=>assert_equals( act = cut->carriers_over( 250 ) exp = 2 ).
  ENDMETHOD.
ENDCLASS.
