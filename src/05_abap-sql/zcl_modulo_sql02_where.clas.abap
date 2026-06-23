"! <p>ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.</p>
"! <p>SELECT·WHERE — 결과 집합 읽기의 폭. 다양한 구문 형태를 자체완결 내부 테이블로 시연한다.</p>
"! <ul>
"! <li>배치: 전통형 SELECT col FROM 과 모던형 SELECT FROM ... FIELDS col(7.40+ strict) 둘 다.</li>
"! <li>필터: 비교·BETWEEN·IN @range·LIKE·호스트식 @( ).</li>
"! <li>단일 행/존재: SELECT SINGLE, 존재확인 SELECT SINGLE @abap_true.</li>
"! <li>결과 메타: sy-dbcnt. 정렬·페이징: ORDER BY·UP TO·OFFSET. SELECT 리스트의 CASE.</li>
"! </ul>
CLASS zcl_modulo_sql02_where DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
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

    "! WHERE 비교: 좌석 수가 하한 이상인 행 수(전통형 SELECT col FROM).
    METHODS count_min_seats
      IMPORTING min_seats     TYPE i
      RETURNING VALUE(result) TYPE i.

    "! 모던 배치: SELECT FROM ... FIELDS col ...(7.40+ strict). 전통형과 결과 동일.
    "! 한 항공사의 항공편 수를 모던 FIELDS형으로 읽는다.
    "! @parameter carrier | 항공사 코드
    "! @parameter result  | 해당 항공사의 항공편 수
    METHODS count_by_carrier_fields
      IMPORTING carrier       TYPE carrier_code
      RETURNING VALUE(result) TYPE i.

    "! WHERE ... BETWEEN: 좌석 수가 구간 안인 행 수.
    METHODS count_between
      IMPORTING low           TYPE i
                high          TYPE i
      RETURNING VALUE(result) TYPE i.

    "! WHERE ... IN @ranges: SELECT-OPTIONS식 레인지로 다중 값 필터(AA·LH).
    METHODS count_in_carriers
      RETURNING VALUE(result) TYPE i.

    "! WHERE ... LIKE: 패턴 매칭(%·_).
    METHODS count_like_carrier
      IMPORTING pattern       TYPE string
      RETURNING VALUE(result) TYPE i.

    "! 호스트식 @( ): SQL 안에서 ABAP 식을 직접 평가(추가 변수 선언 없이).
    "! @parameter base   | 기준값(내부에서 *2 한 임계치와 비교)
    "! @parameter result | 좌석이 base*2 초과인 행 수
    METHODS count_above_double
      IMPORTING base          TYPE i
      RETURNING VALUE(result) TYPE i.

    "! SELECT DISTINCT: 서로 다른 carrier 수.
    METHODS distinct_carriers
      RETURNING VALUE(result) TYPE i.

    "! SELECT 리스트의 CASE 식: 좌석 규모를 라벨로 분류.
    "! @parameter connid | 연결편 번호
    "! @parameter result | 'BIG'(>=300) 또는 'SMALL', 없으면 공백
    METHODS size_label
      IMPORTING connid        TYPE flight-connid
      RETURNING VALUE(result) TYPE string.

    "! 존재 확인 패턴: SELECT SINGLE @abap_true — 데이터를 안 읽고 행 존재만 확인.
    "! @parameter carrier | 항공사 코드
    "! @parameter result  | 한 편이라도 있으면 abap_true
    METHODS carrier_exists
      IMPORTING carrier       TYPE carrier_code
      RETURNING VALUE(result) TYPE abap_bool.

    "! sy-dbcnt: SELECT 후 전달된 행 수를 시스템 필드로 읽는다(lines와 동일하나 출처가 다름).
    "! @parameter result | 전체 행 수(sy-dbcnt)
    METHODS rows_read
      RETURNING VALUE(result) TYPE i.

    "! ORDER BY DESCENDING + UP TO 1 ROWS: 좌석 최다 1편의 connid(동점은 connid 2차 키).
    METHODS top_connid_by_seats
      RETURNING VALUE(result) TYPE flight-connid.

    "! 페이징: 내부 테이블 소스는 OFFSET 미지원 — 정렬 후 ABAP에서 1페이지(앞 2행)를 건너뛴다.
    "! @parameter result | 2페이지(3~4번째 행)에 담긴 행 수
    METHODS second_page
      RETURNING VALUE(result) TYPE i.

  PRIVATE SECTION.
    "! 데모용 항공편 6건 샘플 데이터.
    METHODS sample
      RETURNING VALUE(result) TYPE flights.
ENDCLASS.


CLASS zcl_modulo_sql02_where IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== SQL02 SELECT·WHERE ===` ).
    out->write( |count_min_seats(300)        = { count_min_seats( 300 ) }| ).
    out->write( |count_by_carrier_fields(AA) = { count_by_carrier_fields( 'AA' ) } (모던 FIELDS형)| ).
    out->write( |count_between(200,330)       = { count_between( low = 200 high = 330 ) }| ).
    out->write( |count_in_carriers(AA,LH)     = { count_in_carriers( ) }| ).
    out->write( |count_like_carrier('A%')     = { count_like_carrier( `A%` ) }| ).
    out->write( |count_above_double(150)      = { count_above_double( 150 ) } (호스트식 @( ))| ).
    out->write( |distinct_carriers            = { distinct_carriers( ) }| ).
    out->write( |size_label(0017)             = { size_label( '0017' ) } (CASE)| ).
    out->write( |carrier_exists(ZZ)           = { carrier_exists( 'ZZ' ) }| ).
    out->write( |rows_read(sy-dbcnt)          = { rows_read( ) }| ).
    out->write( |top_connid_by_seats          = { top_connid_by_seats( ) }| ).
    out->write( |second_page(2페이지)         = { second_page( ) }| ).
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

  METHOD count_by_carrier_fields.
    DATA(source) = sample( ) ##NEEDED.
    " 모던 배치: FROM을 먼저 쓰고 SELECT 리스트는 FIELDS 절로(7.40+ strict). 결과는 전통형과 동일.
    SELECT FROM @source AS flight
      FIELDS connid, seats
      WHERE carrier = @carrier
      ORDER BY connid
      INTO TABLE @DATA(rows).
    result = lines( rows ).
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

  METHOD count_above_double.
    DATA(source) = sample( ) ##NEEDED.
    " @( ... ): SQL 피연산자 자리에 ABAP 식을 인라인으로 넣는다(7.50+).
    SELECT COUNT(*)
      FROM @source AS flight
      WHERE seats > @( base * 2 )
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

  METHOD size_label.
    DATA(source) = sample( ) ##NEEDED.
    " SELECT 리스트의 CASE 식 — 행별로 파생 컬럼을 계산한다.
    SELECT SINGLE
      FROM @source AS flight
      FIELDS CASE WHEN seats >= 300 THEN 'BIG' ELSE 'SMALL' END AS label
      WHERE connid = @connid
      INTO @DATA(label).
    result = COND #( WHEN sy-subrc = 0 THEN label ELSE space ).
  ENDMETHOD.

  METHOD carrier_exists.
    DATA(source) = sample( ) ##NEEDED.
    " 존재 확인: 실제 컬럼 대신 상수 1비트만 읽어 행 존재 여부만 본다.
    SELECT SINGLE @abap_true
      FROM @source AS flight
      WHERE carrier = @carrier
      INTO @DATA(exists).
    result = exists.
  ENDMETHOD.

  METHOD rows_read.
    DATA(source) = sample( ) ##NEEDED.
    SELECT FROM @source AS flight
      FIELDS carrier, connid, seats
      INTO TABLE @DATA(rows) ##NEEDED.
    " sy-dbcnt = 직전 SELECT가 전달한 행 수.
    result = sy-dbcnt.
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

  METHOD second_page.
    DATA(source) = sample( ) ##NEEDED.
    " 내부 테이블 소스는 OFFSET 미지원(UP TO만 가능) — 정렬 후 ABAP에서 앞 페이지를 건너뛴다.
    SELECT connid
      FROM @source AS flight
      ORDER BY connid
      INTO TABLE @DATA(sorted).
    " 2페이지 = 페이지 크기 2로 앞 2행을 건너뛴 뒤 남은 행(최대 2).
    DATA(remaining) = lines( sorted ) - 2.
    result = COND #( WHEN remaining < 0 THEN 0
                     WHEN remaining > 2 THEN 2
                     ELSE remaining ).
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
