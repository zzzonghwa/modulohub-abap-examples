"! 할인 전략 계약 — 모든 전략이 공유하는 좁은 인터페이스(인터페이스 분리 원칙).
INTERFACE lif_discount.
  METHODS apply IMPORTING amount        TYPE i
                RETURNING VALUE(result) TYPE i.
ENDINTERFACE.


"! 무할인 전략 — 금액을 그대로 돌려준다(기본/Null Object).
CLASS lcl_none DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES lif_discount.
ENDCLASS.

CLASS lcl_none IMPLEMENTATION.
  METHOD lif_discount~apply.
    result = amount.
  ENDMETHOD.
ENDCLASS.


"! 정률 할인 전략 — 생성자로 퍼센트를 받아 그만큼 깎는다.
CLASS lcl_percent DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES lif_discount.
    METHODS constructor IMPORTING percent TYPE i.
  PRIVATE SECTION.
    DATA rate TYPE i.
ENDCLASS.

CLASS lcl_percent IMPLEMENTATION.
  METHOD constructor.
    rate = percent.
  ENDMETHOD.

  METHOD lif_discount~apply.
    " 정수 나눗셈은 반올림한다 — 데모 금액은 100의 배수라 정확. 실무는 통화 반올림 규칙을 따른다.
    result = amount - amount * rate / 100.
  ENDMETHOD.
ENDCLASS.


"! 가격 계산기 — 할인 전략을 생성자 주입(DI)으로 받는다.
"! 전략을 바꾸면 동작이 바뀌고(개방-폐쇄), 테스트는 더블을 주입해 격리 검증한다.
CLASS lcl_pricing DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS constructor IMPORTING strategy TYPE REF TO lif_discount.
    METHODS net_total
      IMPORTING amounts       TYPE zcl_modulo_expr05_di=>int_list
      RETURNING VALUE(result) TYPE i.
  PRIVATE SECTION.
    DATA strategy TYPE REF TO lif_discount.
ENDCLASS.

CLASS lcl_pricing IMPLEMENTATION.
  METHOD constructor.
    me->strategy = strategy.
  ENDMETHOD.

  METHOD net_total.
    result = REDUCE i( INIT sum = 0
                       FOR amount IN amounts
                       NEXT sum = sum + strategy->apply( amount ) ).
  ENDMETHOD.
ENDCLASS.
