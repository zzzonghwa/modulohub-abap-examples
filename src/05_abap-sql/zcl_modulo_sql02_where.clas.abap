CLASS zcl_modulo_sql02_where DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
    INTERFACES if_oo_adt_classrun.

    TYPES carrier_code TYPE c LENGTH 3.
    "! SELECT-OPTIONS식 레인지 테이블 타입(WHERE ... IN @range 데모용).
    TYPES range_of_carrier TYPE RANGE OF carrier_code.

    "! 항공편 한 건. WHERE·정렬 데모의 공통 행 타입.
    TYPES:
      BEGIN OF flight,
        carrier TYPE carrier_code,
        connid  TYPE n LENGTH 4,
        seats   TYPE i,
      END OF flight.
    TYPES flights TYPE STANDARD TABLE OF flight WITH EMPTY KEY.

    "! WHERE 비교 연산: 좌석 수가 하한 이상인 행을 센다.
    "! @parameter min_seats | 좌석 수 하한
    "! @parameter result    | 조건을 만족하는 행 수
    METHODS count_min_seats
      IMPORTING min_seats     TYPE i
      RETURNING VALUE(result) TYPE i.

    "! WHERE ... BETWEEN: 좌석 수가 구간 안인 행을 센다.
    "! @parameter low    | 구간 하한(포함)
    "! @parameter high   | 구간 상한(포함)
    "! @parameter result | 구간 안 행 수
    METHODS count_between
      IMPORTING low           TYPE i
                high          TYPE i
      RETURNING VALUE(result) TYPE i.

    "! WHERE ... IN @ranges: SELECT-OPTIONS식 레인지 테이블로 다중 값 필터.
    "! @parameter result | carrier가 AA 또는 LH인 행 수
    METHODS count_in_carriers
      RETURNING VALUE(result) TYPE i.

    "! WHERE ... LIKE: 패턴 매칭(%=임의 길이, _=한 글자).
    "! @parameter pattern | LIKE 패턴(예: 'A%')
    "! @parameter result  | 패턴에 맞는 행 수
    METHODS count_like_carrier
      IMPORTING pattern       TYPE string
      RETURNING VALUE(result) TYPE i.

    "! SELECT DISTINCT: 중복 제거 후 서로 다른 carrier 수.
    "! @parameter result | 서로 다른 carrier 수
    METHODS distinct_carriers
      RETURNING VALUE(result) TYPE i.

    "! ORDER BY ... DESCENDING + UP TO 1 ROWS: 좌석 최다 1편의 connid.
    "! @parameter result | 좌석이 가장 많은 항공편의 connid
    METHODS top_connid_by_seats
      RETURNING VALUE(result) TYPE flight-connid.

  PRIVATE SECTION.
    "! 데모용 항공편 6건 샘플 데이터.
    METHODS sample
      RETURNING VALUE(result) TYPE flights.
ENDCLASS.


CLASS zcl_modulo_sql02_where IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== SQL02 SELECT·WHERE ===` ).
    out->write( |count_min_seats(300)       = { count_min_seats( 300 ) }| ).
    out->write( |count_between(200,330)      = { count_between( low = 200 high = 330 ) }| ).
    out->write( |count_in_carriers(AA,LH)    = { count_in_carriers( ) }| ).
    out->write( |count_like_carrier('A%')    = { count_like_carrier( `A%` ) }| ).
    out->write( |distinct_carriers           = { distinct_carriers( ) }| ).
    out->write( |top_connid_by_seats         = { top_connid_by_seats( ) }| ).
  ENDMETHOD.

  METHOD count_min_seats.
    " @source가 FROM에 쓰이나 정적분석이 못 봄 -> ##NEEDED로 false positive 억제.
    DATA(source) = sample( ) ##NEEDED.
    SELECT COUNT(*)
      FROM @source AS flight
      WHERE seats >= @min_seats
      INTO @DATA(matches).
    result = matches.
  ENDMETHOD.

  METHOD count_between.
    DATA(source) = sample( ) ##NEEDED.
    SELECT COUNT(*)
      FROM @source AS flight
      WHERE seats BETWEEN @low AND @high
      INTO @DATA(matches).
    result = matches.
  ENDMETHOD.

  METHOD count_in_carriers.
    DATA(source) = sample( ) ##NEEDED.
    DATA(carriers) = VALUE range_of_carrier(
      ( sign = 'I' option = 'EQ' low = 'AA' )
      ( sign = 'I' option = 'EQ' low = 'LH' ) ).
    SELECT COUNT(*)
      FROM @source AS flight
      WHERE carrier IN @carriers
      INTO @DATA(matches).
    result = matches.
  ENDMETHOD.

  METHOD count_like_carrier.
    DATA(source) = sample( ) ##NEEDED.
    SELECT COUNT(*)
      FROM @source AS flight
      WHERE carrier LIKE @pattern
      INTO @DATA(matches).
    result = matches.
  ENDMETHOD.

  METHOD distinct_carriers.
    DATA(source) = sample( ) ##NEEDED.
    SELECT DISTINCT carrier
      FROM @source AS flight
      INTO TABLE @DATA(carriers).
    result = lines( carriers ).
  ENDMETHOD.

  METHOD top_connid_by_seats.
    DATA(source) = sample( ) ##NEEDED.
    " 동점 시 결정적 결과를 위해 connid를 2차 정렬 키로 둔다.
    SELECT connid
      FROM @source AS flight
      ORDER BY seats DESCENDING, connid ASCENDING
      INTO TABLE @DATA(connids)
      UP TO 1 ROWS.
    result = COND #( WHEN connids IS NOT INITIAL THEN connids[ 1 ]-connid ).
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
