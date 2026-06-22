CLASS lcx_invalid_arg IMPLEMENTATION.
  METHOD constructor.
    super->constructor( ).
    me->attempted = attempted.
  ENDMETHOD.
ENDCLASS.


"! 잔액 초과 출금 — invalid_arg와 구분되는 별도 도메인 예외.
"! 예외 타입 자체로 "어떤 계약을 위반했는가"를 호출부가 즉시 식별한다.
"! READ-ONLY 속성 shortfall에 부족액을 담는다.
CLASS lcx_overdrawn DEFINITION INHERITING FROM lcx_invalid_arg CREATE PUBLIC.
  PUBLIC SECTION.
    "! @parameter shortfall | 잔액 대비 부족액(진단용)
    METHODS constructor
      IMPORTING shortfall TYPE i OPTIONAL.
    DATA shortfall TYPE i READ-ONLY.
ENDCLASS.

CLASS lcx_overdrawn IMPLEMENTATION.
  METHOD constructor.
    super->constructor( ).
    me->shortfall = shortfall.
  ENDMETHOD.
ENDCLASS.


"! DBC 사전조건 위반 — "절대 발생해선 안 되는" 호출자 버그.
"! ATF는 DBC 위반에 cx_no_check(모든 시그니처에 묵시 선언, 선언 강제 없음)를 권장하지만,
"! 전제조건으로 차단 가능한 위반은 cx_dynamic_check도 적합하다(주장 19: "사실상 ASSERT에 가깝다").
"! 런타임 미처리 시 short dump로 "발생 자체가 버그"임을 알린다.
CLASS lcx_precondition DEFINITION INHERITING FROM cx_dynamic_check CREATE PUBLIC.
  PUBLIC SECTION.
    "! @parameter condition_text | 위반한 사전조건 설명 텍스트
    METHODS constructor
      IMPORTING condition_text TYPE string OPTIONAL.
    DATA condition_text TYPE string READ-ONLY.
ENDCLASS.

CLASS lcx_precondition IMPLEMENTATION.
  METHOD constructor.
    super->constructor( ).
    me->condition_text = condition_text.
  ENDMETHOD.
ENDCLASS.


"! 계산기 — 사전조건(Design by Contract)을 검사하고 위반 시 도메인 예외를 던진다.
"! 계약: 호출자는 사전조건을 지킬 책임이 있고, 메서드는 지켜지면 올바른 결과를 보장한다.
CLASS lcl_calculator DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    "! 사전조건: divisor <> 0.
    METHODS divide
      IMPORTING dividend      TYPE i
                divisor       TYPE i
      RETURNING VALUE(result) TYPE i
      RAISING   lcx_invalid_arg.
    "! 사전조건: 0 <= amount. amount > balance면 lcx_overdrawn(하위 타입).
    METHODS withdraw
      IMPORTING balance       TYPE i
                amount        TYPE i
      RETURNING VALUE(result) TYPE i
      RAISING   lcx_invalid_arg.
ENDCLASS.

CLASS lcl_calculator IMPLEMENTATION.
  METHOD divide.
    IF divisor = 0.
      " RAISE EXCEPTION NEW: EXPORTING 생략(7.52+). 위반 입력값을 속성에 실어 보낸다.
      RAISE EXCEPTION NEW lcx_invalid_arg( attempted = divisor ).
    ENDIF.
    " 정수 나눗셈은 DIV(절단). 연산자 / 는 정수 대상에 반올림하므로 의도와 다를 수 있다.
    result = dividend DIV divisor.
  ENDMETHOD.

  METHOD withdraw.
    IF amount < 0.
      RAISE EXCEPTION NEW lcx_invalid_arg( attempted = amount ).
    ENDIF.
    IF amount > balance.
      " 초과 출금은 구체 하위 예외로 구분 — 호출부 multi-CATCH가 먼저 잡는다.
      RAISE EXCEPTION NEW lcx_overdrawn( shortfall = amount - balance ).
    ENDIF.
    result = balance - amount.
  ENDMETHOD.
ENDCLASS.


"! DBC 유틸리티 — REQUIRE 패턴(ATF Listing 4.13). 조건이 거짓이면 사전조건 위반
"! 예외를 던진다. xsdbool()로 인라인 bool 변환을 결합한다.
CLASS lcl_dbc DEFINITION CREATE PRIVATE.
  PUBLIC SECTION.
    "! @parameter that             | 위반 시 남길 조건 설명
    "! @parameter which_is_true_if | 참이어야 하는 조건
    CLASS-METHODS require
      IMPORTING that             TYPE string
                which_is_true_if TYPE abap_bool.
ENDCLASS.

CLASS lcl_dbc IMPLEMENTATION.
  METHOD require.
    IF which_is_true_if = abap_false.
      RAISE EXCEPTION NEW lcx_precondition( condition_text = that ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.
