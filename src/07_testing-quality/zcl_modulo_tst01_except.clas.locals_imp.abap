"! 도메인 예외 — 잘못된 인자/사전조건 위반. cx_static_check 계열:
"! 호출부가 반드시 처리(CATCH)하거나 전파(RAISING)해야 한다(컴파일러 강제).
"! 대비: cx_dynamic_check(선언 없이 전파 가능)·cx_no_check(프로그래밍 오류, 잡지 않음).
CLASS lcx_invalid_arg DEFINITION INHERITING FROM cx_static_check CREATE PUBLIC.
ENDCLASS.

CLASS lcx_invalid_arg IMPLEMENTATION.
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
    "! 사전조건: 0 <= amount <= balance.
    METHODS withdraw
      IMPORTING balance       TYPE i
                amount        TYPE i
      RETURNING VALUE(result) TYPE i
      RAISING   lcx_invalid_arg.
ENDCLASS.

CLASS lcl_calculator IMPLEMENTATION.
  METHOD divide.
    IF divisor = 0.
      RAISE EXCEPTION TYPE lcx_invalid_arg.
    ENDIF.
    " 정수 나눗셈은 DIV(절단). 연산자 / 는 정수 대상에 반올림하므로 의도와 다를 수 있다.
    result = dividend DIV divisor.
  ENDMETHOD.

  METHOD withdraw.
    IF amount < 0 OR amount > balance.
      RAISE EXCEPTION TYPE lcx_invalid_arg.
    ENDIF.
    result = balance - amount.
  ENDMETHOD.
ENDCLASS.
