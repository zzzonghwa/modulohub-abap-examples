CLASS zcl_modulo_sql06_pushdown DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
    "!
    "! Code Pushdown(개념): 같은 결과를 두 방식으로 구한다.
    "! - pushdown: 집계·필터를 SQL로 표현 -> DB(예: HANA)에서 계산, 결과만 ABAP으로.
    "! - ABAP loop: 전 행을 ABAP으로 가져와 LOOP로 계산 -> 데이터 전송·반복 비용.
    "! 두 결과는 같지만 작업 위치가 다르다. "필요한 데이터만, DB에서 계산"이 원칙.
    "! 측정: ST05(SQL Trace)·SAT(Runtime Analysis)·SQLM. ATC도 일부 성능 룰을 잡는다.
    "! 버퍼링(개념): 자주 안 변하는 작은 테이블은 테이블 버퍼(SINGLE/GENERIC/FULL)로
    "! DB 왕복을 줄인다. 최신 데이터가 꼭 필요하면 SELECT ... BYPASSING BUFFER로 우회한다.
    "! (내부 테이블 소스에는 버퍼가 없으므로 여기선 개념만 서술한다.)
    INTERFACES if_oo_adt_classrun.

    TYPES carrier_code TYPE c LENGTH 3.

    TYPES:
      BEGIN OF flight,
        carrier TYPE carrier_code,
        connid  TYPE n LENGTH 4,
        seats   TYPE i,
      END OF flight.
    TYPES flights TYPE STANDARD TABLE OF flight WITH EMPTY KEY.

    "! pushdown: SUM 집계를 SQL로 표현(DB에서 계산).
    "! @parameter result | 전체 좌석 합계
    METHODS total_seats_pushdown
      RETURNING VALUE(result) TYPE i.

    "! pushdown: 필터 + COUNT를 SQL로 표현. 조건 만족 행만 집계한다.
    "! @parameter threshold | 좌석 수 하한
    "! @parameter result    | 좌석이 하한 이상인 항공편 수
    METHODS high_demand_pushdown
      IMPORTING threshold     TYPE i
      RETURNING VALUE(result) TYPE i.

    "! anti-pattern: 전 행을 ABAP으로 가져와 LOOP로 같은 카운트를 구한다(대조용).
    "! @parameter threshold | 좌석 수 하한
    "! @parameter result    | 좌석이 하한 이상인 항공편 수(결과는 pushdown과 동일)
    METHODS high_demand_in_abap
      IMPORTING threshold     TYPE i
      RETURNING VALUE(result) TYPE i.

  PRIVATE SECTION.
    "! 데모용 항공편 6건.
    METHODS sample
      RETURNING VALUE(result) TYPE flights.
ENDCLASS.


CLASS zcl_modulo_sql06_pushdown IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== SQL06 버퍼링·Code Pushdown (개념) ===` ).
    out->write( |total_seats_pushdown      = { total_seats_pushdown( ) }| ).
    out->write( |high_demand_pushdown(300) = { high_demand_pushdown( 300 ) }| ).
    out->write( |high_demand_in_abap(300)  = { high_demand_in_abap( 300 ) }| ).
    out->write( `두 high_demand 결과는 같다 — 차이는 "어디서 계산하느냐"(DB vs ABAP).` ).
  ENDMETHOD.

  METHOD total_seats_pushdown.
    " @source가 FROM에 쓰이나 정적분석이 못 봄 -> ##NEEDED로 false positive 억제.
    DATA(flights) = sample( ) ##NEEDED.
    " 집계를 SQL로 — DB에서 합산하고 결과 한 값만 받는다.
    SELECT SUM( seats ) AS total
      FROM @flights AS flight
      INTO @DATA(total).
    " SUM은 결과 타입을 넓힌다(INT4 -> INT8/DEC). 좌석 합은 INT4 범위라 i로 좁혀 받는다.
    result = total.
  ENDMETHOD.

  METHOD high_demand_pushdown.
    DATA(flights) = sample( ) ##NEEDED.
    " 필터 + 집계를 SQL로 — 조건 만족 행만 DB에서 센다.
    SELECT COUNT(*)
      FROM @flights AS flight
      WHERE seats >= @threshold
      INTO @DATA(matches).
    result = matches.
  ENDMETHOD.

  METHOD high_demand_in_abap.
    " 대조: 전 행을 ABAP으로 가져온 뒤 LOOP로 센다 — 전송·반복 비용이 든다.
    DATA(rows) = sample( ).
    result = REDUCE i( INIT n = 0
                       FOR row IN rows
                       NEXT n = COND #( WHEN row-seats >= threshold THEN n + 1 ELSE n ) ).
  ENDMETHOD.

  METHOD sample.
    result = VALUE #(
      ( carrier = 'AA' connid = '0017' seats = 380 )
      ( carrier = 'AA' connid = '0064' seats = 320 )
      ( carrier = 'LH' connid = '0400' seats = 280 )
      ( carrier = 'LH' connid = '2402' seats = 180 )
      ( carrier = 'UA' connid = '0941' seats = 240 )
      ( carrier = 'UA' connid = '3517' seats = 300 ) ).
  ENDMETHOD.
ENDCLASS.
