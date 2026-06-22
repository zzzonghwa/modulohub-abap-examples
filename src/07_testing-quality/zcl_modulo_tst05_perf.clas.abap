CLASS zcl_modulo_tst05_perf DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
    "!
    "! 성능 — 측정 도구와 알고리즘 복잡도. 두 매칭은 결과가 같고 비용만 다르다.
    "! - match_nested: 주문마다 고객을 선형 탐색(O(n*m)).
    "! - match_hashed: 고객을 HASHED 테이블에 담아 O(1) 룩업(O(n)).
    "! 측정 도구: ST05(SQL Trace, DB 호출)·SAT(Runtime Analysis, ABAP 핫스팟)·SQLM(운영 SQL 모니터).
    "! ATC 성능 룰: LOOP 내 SELECT·중첩 LOOP·표준 테이블 선형 검색 등을 정적으로 잡는다.
    "! 정답은 "측정 후 최적화" — SAT로 match_nested vs match_hashed의 시간차를 직접 확인한다.
    INTERFACES if_oo_adt_classrun.

    "! 중첩 LOOP(O(n*m))으로 고객이 있는 주문 수를 센다.
    "! @parameter result | 고객 마스터가 있는 주문 수
    METHODS match_nested
      RETURNING VALUE(result) TYPE i.

    "! HASHED 룩업(O(n))으로 같은 결과를 구한다 — 측정 시 차이를 본다.
    "! @parameter result | 고객 마스터가 있는 주문 수
    METHODS match_hashed
      RETURNING VALUE(result) TYPE i.

  PRIVATE SECTION.
    "! 내부 구현 타입 — 공개 시그니처(둘 다 i 반환)에 노출하지 않는다.
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
    METHODS sample_orders
      RETURNING VALUE(result) TYPE orders.
ENDCLASS.


CLASS zcl_modulo_tst05_perf IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== TST05 성능 측정도구 (ST05·SAT·SQLM) ===` ).
    out->write( |match_nested = { match_nested( ) }| ).
    out->write( |match_hashed = { match_hashed( ) }| ).
    out->write( `결과는 같다. SAT(Runtime Analysis)로 두 방식의 시간차를 측정해 본다.` ).
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

  METHOD sample_orders.
    result = VALUE #( ( id = 1 customer_id = 100 )
                      ( id = 2 customer_id = 100 )
                      ( id = 3 customer_id = 200 )
                      ( id = 4 customer_id = 999 ) ).
  ENDMETHOD.
ENDCLASS.
