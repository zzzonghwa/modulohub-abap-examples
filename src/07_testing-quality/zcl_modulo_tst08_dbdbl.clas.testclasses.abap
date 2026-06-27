"! ABAP SQL 테스트 더블 환경 — CL_OSQL_TEST_ENVIRONMENT이 ABAP SQL 문을 가로채
"! ZMODULO_FLIGHT 읽기를 주입 데이터로 리다이렉션한다. CUT의 직접 SELECT를 격리 검증한다.
"! class_setup에서 CREATE(i_dependency_list)로 환경 1회 생성, setup마다 clear_doubles + insert_test_data,
"! class_teardown에서 destroy(실 DB로 복귀).
CLASS ltcl_osql_double DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CLASS-DATA environment TYPE REF TO if_osql_test_environment.
    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.

    DATA cut TYPE REF TO zcl_modulo_tst08_dbdbl.
    METHODS setup.
    METHODS sum_over_doubled_rows FOR TESTING.
    METHODS count_for_carrier     FOR TESTING.
    METHODS empty_double_is_zero  FOR TESTING.
ENDCLASS.


CLASS ltcl_osql_double IMPLEMENTATION.
  METHOD class_setup.
    " ZMODULO_FLIGHT 읽기를 더블로 등록한다(등록 안 한 테이블은 실 DB를 그대로 읽음).
    environment = cl_osql_test_environment=>create(
      i_dependency_list = VALUE #( ( 'ZMODULO_FLIGHT' ) ) ).
  ENDMETHOD.

  METHOD class_teardown.
    environment->destroy( ).
  ENDMETHOD.

  METHOD setup.
    DATA flights TYPE STANDARD TABLE OF zmodulo_flight WITH EMPTY KEY.

    " 매 테스트 전 이전 더블 데이터를 지우고(누수 차단) 결정적 데이터를 주입한다.
    environment->clear_doubles( ).
    cut = NEW #( ).

    flights = VALUE #( ( carrid = 'AA' connid = '0017' seatsmax = 380 seatsocc = 342 )
                       ( carrid = 'AA' connid = '0064' seatsmax = 320 seatsocc = 240 )
                       ( carrid = 'LH' connid = '0400' seatsmax = 280 seatsocc = 280 )
                       ( carrid = 'UA' connid = '0941' seatsmax = 240 seatsocc = 180 ) ).
    environment->insert_test_data( i_data = flights ).
  ENDMETHOD.

  METHOD sum_over_doubled_rows.
    " 380 + 320 + 280 + 240 = 1220.
    cl_abap_unit_assert=>assert_equals( act = cut->seatsmax_total( ) exp = 1220 ).
  ENDMETHOD.

  METHOD count_for_carrier.
    cl_abap_unit_assert=>assert_equals( act = cut->flights_of( 'AA' ) exp = 2 ).
  ENDMETHOD.

  METHOD empty_double_is_zero.
    " 더블을 비우면 실 DB가 아니라 빈 더블을 읽는다 — 합계 0(환경 비의존성 입증).
    environment->clear_doubles( ).
    cl_abap_unit_assert=>assert_equals( act = cut->seatsmax_total( ) exp = 0 ).
  ENDMETHOD.
ENDCLASS.


"! CDS 테스트 더블 환경 — CL_CDS_TEST_ENVIRONMENT은 CDS 뷰가 읽는 베이스 테이블에 데이터를
"! 주입해 뷰 내부 로직(GROUP BY·SUM)을 격리 검증한다. osql 환경과 달리 뷰 정의 자체를 거친
"! 결과를 본다. create(i_for_entity = '<CDS 엔터티>')로 환경을 만들면 그 뷰의 베이스 테이블을 더블링한다.
CLASS ltcl_cds_double DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CLASS-DATA environment TYPE REF TO if_cds_test_environment.
    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.

    DATA cut TYPE REF TO zcl_modulo_tst08_dbdbl.
    METHODS setup.
    METHODS aggregates_over_threshold FOR TESTING.
    METHODS view_sums_per_carrier     FOR TESTING.
    METHODS missing_carrier_is_zero   FOR TESTING.
ENDCLASS.


CLASS ltcl_cds_double IMPLEMENTATION.
  METHOD class_setup.
    " CDS 엔터티명으로 환경 생성 — 뷰 ZMODULO_TST08_SEATS의 베이스(ZMODULO_FLIGHT)를 더블링한다.
    environment = cl_cds_test_environment=>create( i_for_entity = 'ZMODULO_TST08_SEATS' ).
  ENDMETHOD.

  METHOD class_teardown.
    environment->destroy( ).
  ENDMETHOD.

  METHOD setup.
    DATA flights TYPE STANDARD TABLE OF zmodulo_flight WITH EMPTY KEY.

    environment->clear_doubles( ).
    cut = NEW #( ).

    " 베이스 테이블에 주입하면 뷰가 carrid별로 집계한다: AA=700, LH=280, UA=240.
    flights = VALUE #( ( carrid = 'AA' connid = '0017' seatsmax = 380 seatsocc = 342 )
                       ( carrid = 'AA' connid = '0064' seatsmax = 320 seatsocc = 240 )
                       ( carrid = 'LH' connid = '0400' seatsmax = 280 seatsocc = 280 )
                       ( carrid = 'UA' connid = '0941' seatsmax = 240 seatsocc = 180 ) ).
    environment->insert_test_data( i_data = flights ).
  ENDMETHOD.

  METHOD aggregates_over_threshold.
    " 합계 >= 250: AA(700)·LH(280) -> 2. UA(240) 제외 — 뷰의 GROUP BY·SUM을 거친 결과.
    cl_abap_unit_assert=>assert_equals( act = cut->busy_carriers( 250 ) exp = 2 ).
  ENDMETHOD.

  METHOD view_sums_per_carrier.
    " AA의 두 항공편(380+320)이 뷰에서 700으로 집계된다.
    cl_abap_unit_assert=>assert_equals( act = cut->carrier_seats( 'AA' ) exp = 700 ).
  ENDMETHOD.

  METHOD missing_carrier_is_zero.
    cl_abap_unit_assert=>assert_equals( act = cut->carrier_seats( 'ZZ' ) exp = 0 ).
  ENDMETHOD.
ENDCLASS.
