CLASS zcl_modulo_expr05_di DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
    "!
    "! 전략 패턴 + 의존성 주입(DI) 기초. 할인 정책을 인터페이스(lif_discount)로 분리하고,
    "! 가격 계산기(lcl_pricing)는 정책을 생성자 주입으로 받는다.
    "! - 인터페이스 분리: 좁은 계약(apply) 하나만 의존 -> 구현 교체가 쉽다.
    "! - DI: 의존(전략)을 밖에서 주입 -> 테스트가 더블을 끼워 격리 검증할 수 있다(LTCL 참고).
    "! 로컬 타입은 locals_imp(lif_discount·lcl_none·lcl_percent·lcl_pricing)에 있다.
    INTERFACES if_oo_adt_classrun.

    "! 금액 리스트 — 로컬 가격 계산기가 공유하는 입력 타입.
    TYPES int_list TYPE STANDARD TABLE OF i WITH EMPTY KEY.

    "! 무할인 전략을 주입한 합계.
    "! @parameter result | 샘플 금액 합계(할인 없음)
    METHODS net_no_discount
      RETURNING VALUE(result) TYPE i.

    "! 정률 할인 전략을 주입한 합계.
    "! @parameter percent | 할인율(%)
    "! @parameter result  | 각 금액에 할인 적용 후 합계
    METHODS net_percent
      IMPORTING percent       TYPE i
      RETURNING VALUE(result) TYPE i.

  PRIVATE SECTION.
    "! 데모용 금액 3건(합 600).
    METHODS sample
      RETURNING VALUE(result) TYPE int_list.
ENDCLASS.


CLASS zcl_modulo_expr05_di IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== EXPR05 디자인 패턴·DI 기초 ===` ).
    out->write( |net_no_discount   = { net_no_discount( ) }| ).
    out->write( |net_percent(10)   = { net_percent( 10 ) }| ).
    out->write( `전략만 바꿔 동작이 달라진다 — 계산기 코드는 그대로(개방-폐쇄).` ).
  ENDMETHOD.

  METHOD net_no_discount.
    " 무할인 전략을 주입한다.
    DATA(pricing) = NEW lcl_pricing( NEW lcl_none( ) ).
    result = pricing->net_total( sample( ) ).
  ENDMETHOD.

  METHOD net_percent.
    " 정률 할인 전략을 주입한다 — 계산기는 동일, 전략만 교체.
    DATA(pricing) = NEW lcl_pricing( NEW lcl_percent( percent ) ).
    result = pricing->net_total( sample( ) ).
  ENDMETHOD.

  METHOD sample.
    result = VALUE #( ( 100 ) ( 200 ) ( 300 ) ).
  ENDMETHOD.
ENDCLASS.
