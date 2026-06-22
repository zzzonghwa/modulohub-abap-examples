CLASS zcl_modulo_sql03_joinagg DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
    "!
    "! JOIN·집계 — 실제 DDIC 테이블(ZMODULO_FLIGHT·ZMODULO_CARRIER) 대상.
    "! 다중 테이블 JOIN은 내부 테이블로는 불가("문당 itab 1개")하므로 레포에 소형 Z 테이블을 동봉한다.
    "! 표는 import 직후 비어 있다 — F9 출력은 0일 수 있고, 결정적 검증은 ABAP Unit이
    "! osql SQL 테스트 더블(CL_OSQL_TEST_ENVIRONMENT)로 데이터를 주입해 수행한다. 적재는 08.6/수동.
    INTERFACES if_oo_adt_classrun.

    "! INNER JOIN: 항공사 마스터가 있는 항공편만 남는다.
    "! @parameter result | 매칭된 조인 결과 행 수
    METHODS inner_join_count
      RETURNING VALUE(result) TYPE i.

    "! LEFT OUTER JOIN: 왼쪽(flight) 전 행 유지, 오른쪽 미매칭 키는 초기값.
    "! @parameter result | 항공사 마스터가 없는(고아) 항공편 수
    METHODS left_join_orphans
      RETURNING VALUE(result) TYPE i.

    "! GROUP BY + SUM: 한 항공사의 좌석 합계.
    "! @parameter carrid | 항공사 코드
    "! @parameter result | 좌석 합계(없으면 0)
    METHODS sum_seats_by_carrier
      IMPORTING carrid        TYPE zmodulo_flight-carrid
      RETURNING VALUE(result) TYPE i.

    "! MAX 집계: 최대 좌석 수.
    "! @parameter result | 최대 좌석 수
    METHODS max_seats
      RETURNING VALUE(result) TYPE i.

    "! GROUP BY + HAVING: 좌석 합계가 임계치 초과인 항공사 수.
    "! @parameter threshold | 좌석 합계 임계치(초과)
    "! @parameter result    | 조건을 넘는 항공사 수
    METHODS carriers_over
      IMPORTING threshold     TYPE i
      RETURNING VALUE(result) TYPE i.

  PRIVATE SECTION.
    "! 데모 데이터 시드 — 값이 없으면 넣고 이미 있으면 건너뛴다(멱등). F9에서 결과가 보이도록.
    "! (ABAP Unit은 이 메서드 대신 osql 더블로 데이터를 주입하므로 실 DB를 건드리지 않는다.)
    METHODS ensure_demo_data.
ENDCLASS.


CLASS zcl_modulo_sql03_joinagg IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    " 데모 데이터를 먼저 시드한다 — 그래야 F9에서 실제 결과가 보인다(빈 표면 0).
    ensure_demo_data( ).
    out->write( `=== SQL03 JOIN·집계 (DDIC 테이블) ===` ).
    out->write( |inner_join_count         = { inner_join_count( ) }| ).
    out->write( |left_join_orphans        = { left_join_orphans( ) }| ).
    out->write( |sum_seats_by_carrier(AA) = { sum_seats_by_carrier( 'AA' ) }| ).
    out->write( |max_seats                = { max_seats( ) }| ).
    out->write( |carriers_over(250)       = { carriers_over( 250 ) }| ).
  ENDMETHOD.

  METHOD inner_join_count.
    SELECT flight~carrid, carrier~carrname
      FROM zmodulo_flight AS flight
      INNER JOIN zmodulo_carrier AS carrier ON carrier~carrid = flight~carrid
      INTO TABLE @DATA(joined).
    result = lines( joined ).
  ENDMETHOD.

  METHOD left_join_orphans.
    SELECT flight~carrid, carrier~carrid AS master
      FROM zmodulo_flight AS flight
      LEFT OUTER JOIN zmodulo_carrier AS carrier ON carrier~carrid = flight~carrid
      INTO TABLE @DATA(joined).
    " 미매칭 행은 오른쪽 키(master)가 NULL -> 읽으면 초기값. 키(CARRID)는 NOT NULL이라
    " 매칭된 행의 키는 절대 비지 않으므로 IS INITIAL이 unmatched를 정확히 가린다.
    result = REDUCE i( INIT n = 0
                       FOR row IN joined
                       NEXT n = COND #( WHEN row-master IS INITIAL THEN n + 1 ELSE n ) ).
  ENDMETHOD.

  METHOD sum_seats_by_carrier.
    SELECT carrid, SUM( seatsmax ) AS total
      FROM zmodulo_flight
      WHERE carrid = @carrid
      GROUP BY carrid
      INTO TABLE @DATA(totals).
    " SUM은 결과 타입을 넓힌다(INT4 -> INT8/DEC). 좌석 합은 INT4 범위라 i로 좁혀 받는다.
    result = COND #( WHEN totals IS NOT INITIAL THEN totals[ 1 ]-total ELSE 0 ).
  ENDMETHOD.

  METHOD max_seats.
    SELECT MAX( seatsmax ) AS top
      FROM zmodulo_flight
      INTO @DATA(top).
    result = top.
  ENDMETHOD.

  METHOD carriers_over.
    SELECT carrid, SUM( seatsmax ) AS total
      FROM zmodulo_flight
      GROUP BY carrid
      HAVING SUM( seatsmax ) > @threshold
      INTO TABLE @DATA(big).
    result = lines( big ).
  ENDMETHOD.

  METHOD ensure_demo_data.
    DATA carriers TYPE STANDARD TABLE OF zmodulo_carrier WITH EMPTY KEY.
    DATA flights  TYPE STANDARD TABLE OF zmodulo_flight WITH EMPTY KEY.

    carriers = VALUE #( ( carrid = 'AA' carrname = 'Alpha Air' )
                        ( carrid = 'LH' carrname = 'Luft Air' )
                        ( carrid = 'UA' carrname = 'Union Air' ) ).
    " XX는 항공사 마스터가 없는 고아 항공편(LEFT JOIN 데모).
    flights = VALUE #( ( carrid = 'AA' connid = '0017' seatsmax = 380 seatsocc = 342 )
                       ( carrid = 'AA' connid = '0064' seatsmax = 320 seatsocc = 240 )
                       ( carrid = 'LH' connid = '0400' seatsmax = 280 seatsocc = 280 )
                       ( carrid = 'UA' connid = '0941' seatsmax = 240 seatsocc = 180 )
                       ( carrid = 'XX' connid = '0001' seatsmax = 100 seatsocc = 90 ) ).

    " 값이 없으면 넣고, 이미 있는 키는 건너뛴다(ACCEPTING DUPLICATE KEYS = 멱등).
    INSERT zmodulo_carrier FROM TABLE @carriers ACCEPTING DUPLICATE KEYS.
    INSERT zmodulo_flight FROM TABLE @flights ACCEPTING DUPLICATE KEYS.
    COMMIT WORK.
  ENDMETHOD.
ENDCLASS.
