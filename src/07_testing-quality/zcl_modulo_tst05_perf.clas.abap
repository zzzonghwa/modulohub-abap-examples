"! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
"!
"! 성능 — 측정 도구와 알고리즘 복잡도(노트 07-5). 측정 도구는 대화형 tcode이므로
"! 이 클래스는 그 도구들이 *진단하는* 패턴을 실행 가능한 형태로 자체완결 시연한다.
"! 모든 짝(나쁨 vs 좋음)은 결과가 같고 비용만 다르다 — "측정 후 최적화" 원칙.
"! 측정 도구: ST05(SQL Trace, DB 호출)·SAT(Runtime Analysis, ABAP 핫스팟)·SQLM(운영 SQL 모니터).
"! ATC 성능 룰: LOOP 내 SELECT·중첩 LOOP·표준 테이블 선형 검색·SELECT *를 정적으로 잡는다.
"! - 알고리즘 복잡도: match_nested(O(n*m)) vs match_hashed/match_sorted(O(n)).
"! - 보조 키: secondary_key_count(since 7.02). 필드 심볼: assign_count vs into_count.
"! - 존재 확인: exists_no_fields(TRANSPORTING NO FIELDS) vs exists_select(SELECT @abap_true).
"! - 블록 처리: block_merge vs row_by_row. 메모리: clear_then_size vs free_then_size.
"! - code pushdown: sum_pushdown(SELECT SUM) vs sum_in_abap(REDUCE). WHERE: and_count vs or_count.
CLASS zcl_modulo_tst05_perf DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    "! 항공사 코드(c3) — 존재 확인 메서드 파라미터의 정확한 타입(c1로 잡히면 'AA'가 절단됨).
    TYPES carrier_code TYPE c LENGTH 3.

    "! 중첩 LOOP(O(n*m))으로 고객이 있는 주문 수를 센다 — Code Inspector "Nested Sequential Access".
    "! @parameter result | 고객 마스터가 있는 주문 수
    METHODS match_nested
      RETURNING VALUE(result) TYPE i.

    "! HASHED 룩업(O(1) 키 접근, 전체 O(n))으로 같은 결과 — 측정 시 격차를 본다.
    "! @parameter result | 고객 마스터가 있는 주문 수
    METHODS match_hashed
      RETURNING VALUE(result) TYPE i.

    "! SORTED 테이블 이진 탐색(O(log m), 전체 O(n*log m))으로 같은 결과 — geometric -> 준선형.
    "! @parameter result | 고객 마스터가 있는 주문 수
    METHODS match_sorted
      RETURNING VALUE(result) TYPE i.

    "! 보조 정렬 키(since 7.02): 같은 테이블을 이름으로 접근. READ ... WITH KEY ... COMPONENTS.
    "! @parameter name   | 찾을 고객 이름
    "! @parameter result | 해당 이름 고객의 주문 수(없으면 0)
    METHODS secondary_key_count
      IMPORTING name          TYPE string
      RETURNING VALUE(result) TYPE i.

    "! LOOP ... ASSIGNING FIELD-SYMBOL: 작업영역 복사 없이 순회(SAP 권고, 읽기 전용도).
    "! @parameter result | 좌석 합계(필드 심볼 경로)
    METHODS assign_total_seats
      RETURNING VALUE(result) TYPE i.

    "! LOOP ... INTO work area: 행마다 작업영역으로 복사(전통형) — 같은 합계, 복사 비용 발생.
    "! @parameter result | 좌석 합계(작업영역 복사 경로)
    METHODS into_total_seats
      RETURNING VALUE(result) TYPE i.

    "! 존재 확인 1: READ TABLE ... TRANSPORTING NO FIELDS — sy-subrc만 보고 데이터 전송 0.
    "! @parameter carrier | 항공사 코드
    "! @parameter result  | 한 편이라도 있으면 abap_true
    METHODS exists_no_fields
      IMPORTING carrier       TYPE carrier_code
      RETURNING VALUE(result) TYPE abap_bool.

    "! 존재 확인 2: SELECT @abap_true ... UP TO 1 ROWS(since 7.50) — 행 데이터 전송 0.
    "! @parameter carrier | 항공사 코드
    "! @parameter result  | 한 편이라도 있으면 abap_true
    METHODS exists_select
      IMPORTING carrier       TYPE carrier_code
      RETURNING VALUE(result) TYPE abap_bool.

    "! 블록 단위 병합: INSERT LINES OF(한 번에) — row by row APPEND보다 빠르다.
    "! @parameter result | 병합 후 전체 행 수
    METHODS block_merge
      RETURNING VALUE(result) TYPE i.

    "! 건별 병합: APPEND 반복(전통형) — 같은 결과, 호출 횟수가 행 수만큼.
    "! @parameter result | 병합 후 전체 행 수
    METHODS row_by_row
      RETURNING VALUE(result) TYPE i.

    "! CLEAR: 내용만 비우고 메모리는 유지 — 곧 다시 채울 때 빠르다(재할당 없음).
    "! @parameter result | CLEAR 후 행 수(0)
    METHODS clear_then_size
      RETURNING VALUE(result) TYPE i.

    "! FREE: 내용·메모리 모두 해제 — 결과 행 수는 CLEAR와 같으나 의미가 다르다.
    "! @parameter result | FREE 후 행 수(0)
    METHODS free_then_size
      RETURNING VALUE(result) TYPE i.

    "! code pushdown: SELECT SUM(...) — DB(여기선 @itab)에서 집계해 1행만 전송.
    "! @parameter result | 좌석 총합
    METHODS sum_pushdown
      RETURNING VALUE(result) TYPE i.

    "! ABAP 집계: 전 행을 읽어 REDUCE로 합산 — 같은 총합, 전송량은 전 행.
    "! @parameter result | 좌석 총합
    METHODS sum_in_abap
      RETURNING VALUE(result) TYPE i.

    "! WHERE = AND(인덱스/이진탐색 유효): 조건을 등호·AND로 조합한 행 수.
    "! @parameter result | carrier = 'AA' AND seats >= 300 인 행 수
    METHODS and_count
      RETURNING VALUE(result) TYPE i.

    "! WHERE OR(탐색 효율 낮음): 같은 결과를 OR로 표현 — 대조용.
    "! @parameter result | carrier = 'AA' AND (seats = 380 OR seats = 320) 인 행 수
    METHODS or_count
      RETURNING VALUE(result) TYPE i.

  PRIVATE SECTION.
    "! 내부 구현 타입 — 공개 시그니처(모두 i/abap_bool 반환)에 노출하지 않는다.
    TYPES:
      BEGIN OF order,
        id          TYPE i,
        customer_id TYPE i,
      END OF order.
    TYPES orders TYPE STANDARD TABLE OF order WITH EMPTY KEY.
    TYPES:
      BEGIN OF customer,
        id   TYPE i,
        name TYPE c LENGTH 20,
      END OF customer.
    "! 항공편 행 — 좌석 합계·존재·집계·WHERE 데모의 공통 타입.
    TYPES:
      BEGIN OF flight,
        carrier TYPE c LENGTH 3,
        connid  TYPE n LENGTH 4,
        seats   TYPE i,
      END OF flight.
    TYPES flights TYPE STANDARD TABLE OF flight WITH EMPTY KEY.

    METHODS sample_orders
      RETURNING VALUE(result) TYPE orders.
    METHODS sample_flights
      RETURNING VALUE(result) TYPE flights.
ENDCLASS.


CLASS zcl_modulo_tst05_perf IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== TST05 성능 측정도구·복잡도 (ST05·SAT·SQLM) ===` ).
    out->write( |match_nested / hashed / sorted = { match_nested( ) } / { match_hashed( ) } / { match_sorted( ) }| ).
    out->write( |secondary_key_count('Beta')   = { secondary_key_count( `Beta` ) } (보조 키 since 7.02)| ).
    out->write( |assign_total / into_total      = { assign_total_seats( ) } / { into_total_seats( ) } (FS vs WA)| ).
    out->write( |exists_no_fields / exists_select(AA) = { exists_no_fields( 'AA' ) } / { exists_select( 'AA' ) }| ).
    out->write( |block_merge / row_by_row       = { block_merge( ) } / { row_by_row( ) }| ).
    out->write( |clear_then_size / free_then_size = { clear_then_size( ) } / { free_then_size( ) }| ).
    out->write( |sum_pushdown / sum_in_abap      = { sum_pushdown( ) } / { sum_in_abap( ) } (pushdown vs ABAP)| ).
    out->write( |and_count / or_count           = { and_count( ) } / { or_count( ) } (WHERE 효율 순서)| ).
    out->write( `각 짝은 결과가 같다. SAT(Runtime Analysis)·ST05로 비용 차를 측정한다.` ).
  ENDMETHOD.

  METHOD match_nested.
    DATA(orders) = sample_orders( ).
    DATA customers TYPE STANDARD TABLE OF customer WITH EMPTY KEY.
    customers = VALUE #( ( id = 100 name = 'Alpha' )
                        ( id = 200 name = 'Beta' )
                        ( id = 300 name = 'Gamma' ) ).
    LOOP AT orders INTO DATA(order).
      " 주문마다 고객 테이블을 처음부터 선형 탐색한다(중첩 -> O(n*m)).
      LOOP AT customers TRANSPORTING NO FIELDS WHERE id = order-customer_id.
        result = result + 1.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD match_hashed.
    DATA(orders) = sample_orders( ).
    DATA customers TYPE HASHED TABLE OF customer WITH UNIQUE KEY id.
    customers = VALUE #( ( id = 100 name = 'Alpha' )
                        ( id = 200 name = 'Beta' )
                        ( id = 300 name = 'Gamma' ) ).
    LOOP AT orders INTO DATA(order).
      " 키 룩업은 해시로 O(1) — 데이터가 커질수록 격차가 벌어진다.
      IF line_exists( customers[ id = order-customer_id ] ).
        result = result + 1.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD match_sorted.
    DATA(orders) = sample_orders( ).
    DATA customers TYPE SORTED TABLE OF customer WITH UNIQUE KEY id.
    customers = VALUE #( ( id = 100 name = 'Alpha' )
                        ( id = 200 name = 'Beta' )
                        ( id = 300 name = 'Gamma' ) ).
    LOOP AT orders INTO DATA(order).
      " 정렬 테이블의 키 접근은 이진 탐색 O(log m) — geometric 진행을 막는다.
      IF line_exists( customers[ id = order-customer_id ] ).
        result = result + 1.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD secondary_key_count.
    DATA(orders) = sample_orders( ).
    " 기본 키는 id(해시), 보조 정렬 키 by_name으로 같은 테이블을 이름으로도 접근한다.
    DATA customers TYPE HASHED TABLE OF customer
      WITH UNIQUE KEY id
      WITH NON-UNIQUE SORTED KEY by_name COMPONENTS name.
    customers = VALUE #( ( id = 100 name = 'Alpha' )
                        ( id = 200 name = 'Beta' )
                        ( id = 300 name = 'Gamma' ) ).
    READ TABLE customers WITH KEY by_name COMPONENTS name = name
      ASSIGNING FIELD-SYMBOL(<found>).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    LOOP AT orders TRANSPORTING NO FIELDS WHERE customer_id = <found>-id.
      result = result + 1.
    ENDLOOP.
  ENDMETHOD.

  METHOD assign_total_seats.
    DATA(flights) = sample_flights( ).
    " 필드 심볼: 작업영역 복사 없이 포인터로 직접 접근(읽기 전용도 SAP 권고).
    LOOP AT flights ASSIGNING FIELD-SYMBOL(<flight>).
      result = result + <flight>-seats.
    ENDLOOP.
  ENDMETHOD.

  METHOD into_total_seats.
    DATA(flights) = sample_flights( ).
    " 작업영역 복사 경로(전통형) — 결과는 같고 행마다 구조 복사가 발생한다.
    LOOP AT flights INTO DATA(flight).
      result = result + flight-seats.
    ENDLOOP.
  ENDMETHOD.

  METHOD exists_no_fields.
    DATA(flights) = sample_flights( ).
    " TRANSPORTING NO FIELDS: 어떤 컬럼도 전송하지 않고 sy-subrc로 존재만 본다.
    READ TABLE flights TRANSPORTING NO FIELDS WITH KEY carrier = carrier.
    result = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.

  METHOD exists_select.
    DATA(flights) = sample_flights( ) ##NEEDED.
    " SELECT @abap_true ... UP TO 1 ROWS: 행 데이터 없이 상수 1비트만 읽는 존재 확인.
    SELECT SINGLE @abap_true
      FROM @flights AS flight
      WHERE carrier = @carrier
      INTO @DATA(found).
    result = found.
  ENDMETHOD.

  METHOD block_merge.
    DATA(left)  = sample_flights( ).
    DATA(right) = sample_flights( ).
    " 블록 단위: 한 번의 호출로 전 행을 이어 붙인다 — 건별 APPEND보다 빠르다.
    APPEND LINES OF right TO left.
    result = lines( left ).
  ENDMETHOD.

  METHOD row_by_row.
    DATA(left)  = sample_flights( ).
    DATA(right) = sample_flights( ).
    " 건별: 행마다 APPEND를 반복(전통형) — 같은 결과, 호출 횟수가 행 수만큼.
    LOOP AT right INTO DATA(flight).
      APPEND flight TO left.
    ENDLOOP.
    result = lines( left ).
  ENDMETHOD.

  METHOD clear_then_size.
    DATA(flights) = sample_flights( ).
    " CLEAR: 내용만 비우고 할당된 메모리는 유지한다(곧 재충전 시 빠름).
    CLEAR flights.
    result = lines( flights ).
  ENDMETHOD.

  METHOD free_then_size.
    DATA(flights) = sample_flights( ).
    " FREE: 내용과 메모리를 모두 해제한다(OS 재할당 비용 발생).
    FREE flights.
    result = lines( flights ).
  ENDMETHOD.

  METHOD sum_pushdown.
    DATA(flights) = sample_flights( ) ##NEEDED.
    " code pushdown: 집계를 DB(@itab) 레이어에서 수행해 1행만 전송한다.
    SELECT SUM( seats )
      FROM @flights AS flight
      INTO @DATA(total).
    result = total.
  ENDMETHOD.

  METHOD sum_in_abap.
    DATA(flights) = sample_flights( ).
    " ABAP 집계: 전 행을 읽어 REDUCE로 합산 — 같은 총합, 전 행 전송.
    result = REDUCE i( INIT sum = 0 FOR flight IN flights NEXT sum = sum + flight-seats ).
  ENDMETHOD.

  METHOD and_count.
    DATA(flights) = sample_flights( ) ##NEEDED.
    " 등호·AND 조합 — 인덱스/이진 탐색이 유효하게 적용되는 형태.
    SELECT COUNT(*)
      FROM @flights AS flight
      WHERE carrier = 'AA' AND seats >= 300
      INTO @DATA(matches).
    result = matches.
  ENDMETHOD.

  METHOD or_count.
    DATA(flights) = sample_flights( ) ##NEEDED.
    " 같은 결과를 OR로 표현(대조용) — OR/NOT은 탐색 효율이 낮다.
    SELECT COUNT(*)
      FROM @flights AS flight
      WHERE carrier = 'AA' AND ( seats = 380 OR seats = 320 )
      INTO @DATA(matches).
    result = matches.
  ENDMETHOD.

  METHOD sample_orders.
    result = VALUE #( ( id = 1 customer_id = 100 )
                      ( id = 2 customer_id = 100 )
                      ( id = 3 customer_id = 200 )
                      ( id = 4 customer_id = 999 ) ).
  ENDMETHOD.

  METHOD sample_flights.
    result = VALUE #(
      ( carrier = 'AA' connid = '0017' seats = 380 )
      ( carrier = 'AA' connid = '0064' seats = 320 )
      ( carrier = 'LH' connid = '0400' seats = 280 )
      ( carrier = 'LH' connid = '2402' seats = 180 )
      ( carrier = 'UA' connid = '0941' seats = 240 )
      ( carrier = 'UA' connid = '3517' seats = 300 ) ).
  ENDMETHOD.
ENDCLASS.
