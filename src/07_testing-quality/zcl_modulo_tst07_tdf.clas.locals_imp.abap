"! 인메모리 재고 — zif_modulo_tst07_stock의 실제 구현(테이블 기반).
"! main 데모 전용. "경계만 더블한다": 빠르고 결정적인 의존은 더블이 아니라 실물을 쓴다.
"! 테스트는 이 실물 대신 CL_ABAP_TESTDOUBLE 더블을 주입한다.
CLASS lcl_in_memory_stock DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES zif_modulo_tst07_stock.
    METHODS constructor.
  PRIVATE SECTION.
    TYPES: BEGIN OF ty_row,
             sku TYPE string,
             qty TYPE i,
           END OF ty_row.
    DATA stock TYPE SORTED TABLE OF ty_row WITH UNIQUE KEY sku.
ENDCLASS.

CLASS lcl_in_memory_stock IMPLEMENTATION.
  METHOD constructor.
    stock = VALUE #( ( sku = `SKU-1` qty = 5 ) ).
  ENDMETHOD.

  METHOD zif_modulo_tst07_stock~available.
    DATA(row) = REF #( stock[ sku = sku ] OPTIONAL ).
    qty = COND #( WHEN row IS BOUND THEN row->qty ELSE 0 ).
  ENDMETHOD.

  METHOD zif_modulo_tst07_stock~reserve.
    DATA(row) = REF #( stock[ sku = sku ] OPTIONAL ).
    IF row IS BOUND.
      row->qty = row->qty - qty.
    ENDIF.
  ENDMETHOD.
ENDCLASS.


"! 주문 서비스(CUT) — 재고 게이트웨이 의존을 생성자 주입으로 받는다.
"! 가용 재고를 확인하고(쿼리) 충분하면 예약한다(커맨드). 테스트는 게이트웨이를 더블로 교체해
"! "충분하면 예약·부족하면 무동작" 분기와 reserve 호출(상호작용)을 격리 검증한다.
CLASS lcl_order_service DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS constructor IMPORTING stock TYPE REF TO zif_modulo_tst07_stock.
    "! 가용 재고가 qty 이상이면 reserve를 호출하고 qty를, 부족하면 0을 돌려준다.
    "! @parameter sku    | 자재 코드
    "! @parameter qty    | 주문 수량
    "! @parameter result | 예약된 수량(부족 시 0)
    METHODS place
      IMPORTING sku           TYPE string
                qty           TYPE i
      RETURNING VALUE(result) TYPE i.
  PRIVATE SECTION.
    DATA stock TYPE REF TO zif_modulo_tst07_stock.
ENDCLASS.

CLASS lcl_order_service IMPLEMENTATION.
  METHOD constructor.
    me->stock = stock.
  ENDMETHOD.

  METHOD place.
    IF stock->available( sku ) < qty.
      RETURN.
    ENDIF.
    stock->reserve( sku = sku qty = qty ).
    result = qty.
  ENDMETHOD.
ENDCLASS.
