"! <p>ADT에서 F9(Run As -> ABAP Application)로 데모 출력을, Ctrl+Shift+F10으로 테스트를 본다.</p>
"! <p>DB 격리 — 표준 테스트 더블 환경 둘. 단위 테스트에서 실제 DB를 읽으면 데이터가 환경마다 달라
"! 테스트가 불안정해진다. 두 프레임워크가 이를 각각 해결한다(둘 다 온프렘 7.54 존재):</p>
"! <ul>
"! <li>CL_OSQL_TEST_ENVIRONMENT: ABAP SQL 문을 가로채 등록된 테이블/뷰 읽기를 더블 데이터로
"! 리다이렉션한다. seatsmax_total·flights_of가 직접 읽는 ZMODULO_FLIGHT를 더블링한다.</li>
"! <li>CL_CDS_TEST_ENVIRONMENT: CDS 뷰가 읽는 베이스 테이블에 데이터를 주입해 뷰 내부 로직
"! (GROUP BY·SUM)을 격리 테스트한다. busy_carriers가 소비하는 CDS 뷰 ZMODULO_TST08_SEATS의
"! 베이스(ZMODULO_FLIGHT)를 더블링한다 — osql 환경은 뷰 내부까지 제어하지 못한다.</li>
"! </ul>
"! <p>표는 import 직후 비어 있다 — F9는 ensure_demo_data로 시드해 결과를 보이고, 결정적 검증은
"! ABAP Unit이 두 더블 환경으로 데이터를 주입해 수행한다(실 DB 미접촉).</p>
CLASS zcl_modulo_tst08_dbdbl DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    "! ABAP SQL 직접 집계 — 전체 좌석 합계(osql 더블 검증 대상).
    "! @parameter result | 모든 항공편 좌석 합계(빈 표면 0)
    METHODS seatsmax_total
      RETURNING VALUE(result) TYPE i.

    "! ABAP SQL 직접 조회 — 한 항공사의 항공편 수(osql 더블 검증 대상).
    "! @parameter carrid | 항공사 코드
    "! @parameter result | 해당 항공사 항공편 수
    METHODS flights_of
      IMPORTING carrid        TYPE zmodulo_flight-carrid
      RETURNING VALUE(result) TYPE i.

    "! CDS 뷰 소비 — 좌석 합계가 임계치 이상인 항공사 수(cds 더블 검증 대상).
    "! 뷰 ZMODULO_TST08_SEATS의 GROUP BY·SUM 로직을 거친 결과를 읽는다.
    "! @parameter min_seats | 좌석 합계 임계치(이상)
    "! @parameter result    | 조건을 만족하는 항공사 수
    METHODS busy_carriers
      IMPORTING min_seats     TYPE i
      RETURNING VALUE(result) TYPE i.

    "! CDS 뷰 소비 — 한 항공사의 집계 좌석 합계(cds 더블 검증 대상).
    "! @parameter carrier | 항공사 코드
    "! @parameter result  | 뷰가 집계한 좌석 합계(없으면 0)
    METHODS carrier_seats
      IMPORTING carrier       TYPE zmodulo_flight-carrid
      RETURNING VALUE(result) TYPE i.

  PRIVATE SECTION.
    "! 데모 데이터 시드 — 없으면 넣고 있으면 건너뛴다(멱등). F9에서 결과가 보이도록.
    "! (ABAP Unit은 이 메서드 대신 더블 환경으로 데이터를 주입하므로 실 DB를 건드리지 않는다.)
    METHODS ensure_demo_data.
ENDCLASS.


CLASS zcl_modulo_tst08_dbdbl IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    ensure_demo_data( ).
    out->write( `=== TST08 DB 격리 — osql·cds 테스트 더블 환경 ===` ).
    out->write( |seatsmax_total       = { seatsmax_total( ) } (osql 대상)| ).
    out->write( |flights_of(AA)       = { flights_of( 'AA' ) } (osql 대상)| ).
    out->write( |busy_carriers(250)   = { busy_carriers( 250 ) } (cds 뷰 소비)| ).
    out->write( |carrier_seats(AA)    = { carrier_seats( 'AA' ) } (cds 뷰 소비)| ).
    out->write( `더블 환경 주입 검증은 LTCL_OSQL_DOUBLE·LTCL_CDS_DOUBLE — Ctrl+Shift+F10.` ).
  ENDMETHOD.

  METHOD seatsmax_total.
    SELECT SUM( seatsmax ) FROM zmodulo_flight INTO @DATA(total).
    result = total.
  ENDMETHOD.

  METHOD flights_of.
    SELECT COUNT(*) FROM zmodulo_flight WHERE carrid = @carrid INTO @result.
  ENDMETHOD.

  METHOD busy_carriers.
    " CDS 뷰를 읽는다 — 뷰가 carrid별 SUM(seatsmax)을 TotalSeatsMax로 집계한 뒤 필터한다.
    SELECT COUNT(*) FROM zmodulo_tst08_seats WHERE totalseatsmax >= @min_seats INTO @result.
  ENDMETHOD.

  METHOD carrier_seats.
    SELECT SINGLE totalseatsmax FROM zmodulo_tst08_seats
      WHERE carrier = @carrier INTO @DATA(seats).
    result = seats.
  ENDMETHOD.

  METHOD ensure_demo_data.
    DATA flights TYPE STANDARD TABLE OF zmodulo_flight WITH EMPTY KEY.

    flights = VALUE #( ( carrid = 'AA' connid = '0017' seatsmax = 380 seatsocc = 342 )
                       ( carrid = 'AA' connid = '0064' seatsmax = 320 seatsocc = 240 )
                       ( carrid = 'LH' connid = '0400' seatsmax = 280 seatsocc = 280 )
                       ( carrid = 'UA' connid = '0941' seatsmax = 240 seatsocc = 180 ) ).

    INSERT zmodulo_flight FROM TABLE @flights ACCEPTING DUPLICATE KEYS.
    COMMIT WORK.
  ENDMETHOD.
ENDCLASS.
