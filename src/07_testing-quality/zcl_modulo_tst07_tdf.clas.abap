"! <p>ADT에서 F9(Run As -> ABAP Application)로 데모 출력을, Ctrl+Shift+F10으로 테스트를 본다.</p>
"! <p>표준 테스트 더블 프레임워크 — CL_ABAP_TESTDOUBLE. 더블을 손으로 작성하는 대신, 전역
"! 인터페이스(ZIF_MODULO_TST07_STOCK)로부터 더블을 자동 생성한다.
"! 테스트 인클루드가 실물 패턴을 모은다:</p>
"! <ul>
"! <li>create: 전역 인터페이스명으로 더블 인스턴스를 만든다(클래스 손코딩 없음).</li>
"! <li>스텁(returning·ignore_all_parameters): 호출에 고정/무차별 반환값을 심는다.</li>
"! <li>입력별 스텁: SKU별로 다른 가용 수량을 돌려주도록 같은 더블을 구성한다.</li>
"! <li>목(and_expect·is_called_times·is_never_called + verify_expectations): 호출 횟수·인자를 자동 검증.</li>
"! </ul>
"! <p>이 글로벌 클래스는 더블을 주입한 도메인 객체(lcl_order_service)의 얇은 파사드다. main 데모는
"! 더블이 아니라 실제 인메모리 재고(lcl_in_memory_stock)를 조립한다 — 더블은 테스트에서만 쓴다.</p>
CLASS zcl_modulo_tst07_tdf DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    "! 주어진 SKU를 수량만큼 주문한다. 가용 재고가 충분하면 예약하고 그 수량을, 부족하면 0을 돌려준다.
    "! 매 호출마다 인메모리 재고를 새로 조립하므로 호출 간 상태는 누적되지 않는다(데모 단순화).
    "! @parameter sku    | 자재 코드
    "! @parameter qty    | 주문 수량
    "! @parameter result | 예약된 수량(부족 시 0)
    METHODS place
      IMPORTING sku           TYPE string
                qty           TYPE i
      RETURNING VALUE(result) TYPE i.
ENDCLASS.


CLASS zcl_modulo_tst07_tdf IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== TST07 표준 테스트 더블 프레임워크 (CL_ABAP_TESTDOUBLE) ===` ).
    out->write( |place('SKU-1', 3) = { place( sku = `SKU-1` qty = 3 ) } (재고 5, 예약됨)| ).
    out->write( |place('SKU-1', 7) = { place( sku = `SKU-1` qty = 7 ) } (재고 5<7 부족, 0)| ).
    out->write( |place('SKU-9', 1) = { place( sku = `SKU-9` qty = 1 ) } (미등록 SKU, 0)| ).
    out->write( `테스트 더블(스텁·입력별·목)은 LTCL_ORDER_SERVICE에서 — Ctrl+Shift+F10.` ).
  ENDMETHOD.

  METHOD place.
    " main 데모: 더블이 아니라 실제 인메모리 재고를 주입한다(더블은 테스트 전용).
    result = NEW lcl_order_service( NEW lcl_in_memory_stock( ) )->place( sku = sku qty = qty ).
  ENDMETHOD.
ENDCLASS.
