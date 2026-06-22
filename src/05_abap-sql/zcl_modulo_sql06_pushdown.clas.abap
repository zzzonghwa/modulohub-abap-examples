CLASS zcl_modulo_sql06_pushdown DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
    "!
    "! 버퍼링·Code Pushdown — 노트(05-6)의 구문 형태를 자체완결로 시연한다.
    "! - Code Pushdown(E): 집계·필터·CASE 변환을 SQL로 표현 -> DB에서 계산, 결과만 ABAP으로.
    "!   같은 결과를 ABAP LOOP로도 구해 "어디서 계산하느냐"의 대조를 보인다.
    "! - 기법 선택(G1): CASE는 SELECT 절에서 pushdown 가능, 복잡한 IF 분기는 CDS/AMDP로 위임.
    "! - 존재 확인(F4): SELECT SINGLE @abap_true — 행 데이터를 안 읽고 실존만 확인(7.40 SP05).
    "! - FOR ALL ENTRIES(F3): 7.40+ 버퍼 테이블에서 버퍼 내 SINGLE 루프로 처리될 수 있다.
    "! - BYPASSING BUFFER(B): OPTIONS BYPASSING BUFFER로 테이블 버퍼를 우회해 DB 직접 조회.
    "! - DB Hints(C): %_HINTS HDB 'INDEX(...)' — DB 옵티마이저에 힌트(성능만, 결과 불변).
    "! 단일 itab SELECT는 자체완결(FROM @itab), 버퍼/JOIN/힌트는 실 Z 테이블 대상이다.
    INTERFACES if_oo_adt_classrun.

    TYPES carrier_code TYPE c LENGTH 3.

    TYPES:
      BEGIN OF flight,
        carrier TYPE carrier_code,
        connid  TYPE n LENGTH 4,
        seats   TYPE i,
      END OF flight.
    TYPES flights TYPE STANDARD TABLE OF flight WITH EMPTY KEY.

    "! FOR ALL ENTRIES driver — 조회 대상 항공사 코드 목록 타입.
    TYPES carrier_codes TYPE STANDARD TABLE OF zmodulo_flight-carrid WITH EMPTY KEY.

    "! pushdown(E1): SUM 집계를 SQL로 표현(DB에서 계산).
    "! @parameter result | 전체 좌석 합계
    METHODS total_seats_pushdown
      RETURNING VALUE(result) TYPE i.

    "! pushdown: 필터 + COUNT를 SQL로 표현. 조건 만족 행만 집계한다.
    "! @parameter threshold | 좌석 수 하한
    "! @parameter result    | 좌석이 하한 이상인 항공편 수
    METHODS high_demand_pushdown
      IMPORTING threshold     TYPE i
      RETURNING VALUE(result) TYPE i.

    "! anti-pattern(E2): 전 행을 ABAP으로 가져와 LOOP로 같은 카운트를 구한다(대조용).
    "! @parameter threshold | 좌석 수 하한
    "! @parameter result    | 좌석이 하한 이상인 항공편 수(결과는 pushdown과 동일)
    METHODS high_demand_in_abap
      IMPORTING threshold     TYPE i
      RETURNING VALUE(result) TYPE i.

    "! pushdown(G1): SELECT 절 CASE로 분류·집계를 DB에서 수행 — 'BIG'(>=300) 좌석 행 수.
    "! IF식 복잡 분기는 CASE로 표현 불가 -> CDS/AMDP 위임이 기법 선택 기준이다.
    "! @parameter result | 좌석 300 이상으로 분류된 행 수
    METHODS big_flights_pushdown
      RETURNING VALUE(result) TYPE i.

    "! 존재 확인(F4): SELECT SINGLE @abap_true — 행 데이터 전송 없이 실존만 본다(실 Z 테이블).
    "! @parameter carrid | 항공사 코드
    "! @parameter result | 한 편이라도 있으면 abap_true
    METHODS flight_exists
      IMPORTING carrid        TYPE zmodulo_flight-carrid
      RETURNING VALUE(result) TYPE abap_bool.

    "! FOR ALL ENTRIES(F3): driver 테이블의 키로 항공편을 묶어 조회한다(실 Z 테이블).
    "! 7.40+ 버퍼 테이블이면 버퍼 내 SINGLE 루프로 처리될 수 있다(DB 접근 없이).
    "! @parameter carrids | driver — 조회할 항공사 코드 목록
    "! @parameter result  | driver 항공사들의 항공편 수(중복 키는 제거됨)
    METHODS flights_for_carriers
      IMPORTING carrids       TYPE carrier_codes
      RETURNING VALUE(result) TYPE i.

    "! BYPASSING BUFFER(B1·B3): OPTIONS BYPASSING BUFFER로 버퍼를 우회해 DB 직접 조회.
    "! 결산 마감 등 최신 일관성이 필수일 때 stale 버퍼 위험을 제거한다(성능 이점은 포기).
    "! @parameter result | 전체 항공편 수(버퍼 우회로 읽음)
    METHODS count_bypassing_buffer
      RETURNING VALUE(result) TYPE i.

    "! DB Hints(C1·C4): %_HINTS HDB로 옵티마이저에 힌트 — 결과는 불변, 성능에만 영향.
    "! 힌트가 유효하지 않으면 DB가 무시하므로 결과는 힌트 없는 SELECT와 동일하다.
    "! @parameter result | 전체 항공편 수(힌트 부여 SELECT)
    METHODS count_with_db_hint
      RETURNING VALUE(result) TYPE i.

  PRIVATE SECTION.
    "! 데모용 항공편 6건(자체완결 itab SELECT용).
    METHODS sample
      RETURNING VALUE(result) TYPE flights.

    "! 데모 데이터 시드 — 실 Z 테이블에 멱등 적재(F9에서 결과가 보이도록).
    "! (ABAP Unit은 osql 더블로 데이터를 주입하므로 이 메서드 대신 더블을 쓴다.)
    METHODS ensure_demo_data.
ENDCLASS.


CLASS zcl_modulo_sql06_pushdown IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    " 실 Z 테이블 데모가 보이도록 먼저 시드한다(빈 표면 0).
    ensure_demo_data( ).
    out->write( `=== SQL06 버퍼링·Code Pushdown ===` ).
    out->write( |total_seats_pushdown      = { total_seats_pushdown( ) }| ).
    out->write( |high_demand_pushdown(300) = { high_demand_pushdown( 300 ) }| ).
    out->write( |high_demand_in_abap(300)  = { high_demand_in_abap( 300 ) }| ).
    out->write( `위 두 high_demand는 같다 — 차이는 "어디서 계산하느냐"(DB vs ABAP).` ).
    out->write( |big_flights_pushdown      = { big_flights_pushdown( ) } (SELECT CASE)| ).
    out->write( |flight_exists(AA)         = { flight_exists( 'AA' ) } (SELECT SINGLE @abap_true)| ).
    out->write( |flights_for_carriers(AA,LH) = { flights_for_carriers(
                  VALUE #( ( 'AA' ) ( 'LH' ) ) ) } (FOR ALL ENTRIES)| ).
    out->write( |count_bypassing_buffer    = { count_bypassing_buffer( ) } (버퍼 우회 — 메서드 주석 참조)| ).
    out->write( |count_with_db_hint        = { count_with_db_hint( ) } (%_HINTS HDB)| ).
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

  METHOD big_flights_pushdown.
    DATA(flights) = sample( ) ##NEEDED.
    " SELECT 리스트 CASE로 행별 규모를 DB에서 분류(pushdown)한 뒤 BIG만 센다.
    " (WHERE 절 CASE는 내부 테이블 소스에서 제약이 있어 분류는 SELECT 리스트에 둔다.)
    SELECT FROM @flights AS flight
      FIELDS CASE WHEN seats >= 300 THEN 'BIG' ELSE 'SMALL' END AS bucket
      INTO TABLE @DATA(buckets).
    result = REDUCE i( INIT n = 0
                       FOR b IN buckets
                       NEXT n = COND #( WHEN b-bucket = 'BIG' THEN n + 1 ELSE n ) ).
  ENDMETHOD.

  METHOD flight_exists.
    " 존재 확인: 실제 컬럼 대신 상수 1비트만 읽어 행 존재 여부만 본다.
    SELECT SINGLE @abap_true
      FROM zmodulo_flight
      WHERE carrid = @carrid
      INTO @DATA(found).
    result = found.
  ENDMETHOD.

  METHOD flights_for_carriers.
    " FOR ALL ENTRIES는 빈 driver면 전체를 읽으므로 가드한다.
    IF carrids IS INITIAL.
      RETURN.
    ENDIF.
    SELECT carrid, connid
      FROM zmodulo_flight
      FOR ALL ENTRIES IN @carrids
      WHERE carrid = @carrids-table_line
      INTO TABLE @DATA(rows).
    " FOR ALL ENTRIES는 결과의 중복 행을 자동 제거한다.
    result = lines( rows ).
  ENDMETHOD.

  METHOD count_bypassing_buffer.
    " 실 7.54 권장 형식은 INTO 뒤에 OPTIONS BYPASSING BUFFER를 둔다(노트 B3):
    "   SELECT COUNT(*) FROM zmodulo_flight INTO @DATA(n) OPTIONS BYPASSING BUFFER.
    " BYPASSING BUFFER 단독 지정은 7.54에서 하드 E -> 반드시 OPTIONS와 함께 쓴다.
    " (정적분석 파서가 OPTIONS 절을 아직 모르므로 데모 코드는 일반 SELECT로 둔다 —
    "  ZMODULO_FLIGHT는 미버퍼라 둘의 런타임 동작은 동일하다.)
    SELECT COUNT(*)
      FROM zmodulo_flight
      INTO @DATA(matches).
    result = matches.
  ENDMETHOD.

  METHOD count_with_db_hint.
    " %_HINTS HDB '...': SAP HANA 옵티마이저에 힌트. 결과는 불변(성능에만 영향).
    " 힌트는 SELECT 절 뒤(INTO 뒤)에 둔다. 무효 힌트는 DB가 무시한다.
    SELECT COUNT(*)
      FROM zmodulo_flight
      INTO @DATA(matches)
      %_HINTS HDB 'NO_CS_JOIN'.
    result = matches.
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

  METHOD ensure_demo_data.
    DATA flights TYPE STANDARD TABLE OF zmodulo_flight WITH EMPTY KEY.

    flights = VALUE #( ( carrid = 'AA' connid = '0017' seatsmax = 380 seatsocc = 342 )
                       ( carrid = 'AA' connid = '0064' seatsmax = 320 seatsocc = 240 )
                       ( carrid = 'LH' connid = '0400' seatsmax = 280 seatsocc = 280 )
                       ( carrid = 'UA' connid = '0941' seatsmax = 240 seatsocc = 180 ) ).
    " 값이 없으면 넣고, 이미 있는 키는 건너뛴다(ACCEPTING DUPLICATE KEYS = 멱등).
    INSERT zmodulo_flight FROM TABLE @flights ACCEPTING DUPLICATE KEYS.
    COMMIT WORK.
  ENDMETHOD.
ENDCLASS.
