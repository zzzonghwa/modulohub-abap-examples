CLASS zcl_modulo_tst01_except DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
    "!
    "! 예외 처리 전략·CX 분류·Design by Contract.
    "! - CX 분류: cx_static_check(호출부가 반드시 처리/전파) · cx_dynamic_check(선언 없이 전파)
    "!   · cx_no_check(프로그래밍 오류, 보통 잡지 않음). 도메인 예외는 cx_static_check 권장.
    "! - 전략: 호출부에서 (1)전파(RAISING) (2)도메인 예외로 변환 (3)기본값으로 흡수 중 택1.
    "!   이 클래스는 (3) 흡수 전략을 보인다 — 내부에서 잡아 안전한 기본값을 돌려준다.
    "! - DbC: 사전조건 검사는 locals_imp의 lcl_calculator(divide·withdraw)에 있다.
    INTERFACES if_oo_adt_classrun.

    "! divide를 호출하되 0 나눗셈 예외는 흡수해 0을 돌려준다(흡수 전략).
    "! @parameter dividend | 피제수
    "! @parameter divisor  | 제수
    "! @parameter result   | 몫, divisor=0이면 0
    METHODS divide_or_zero
      IMPORTING dividend      TYPE i
                divisor       TYPE i
      RETURNING VALUE(result) TYPE i.

    "! withdraw를 호출하되 사전조건 위반은 흡수해 -1을 돌려준다.
    "! @parameter balance | 잔액
    "! @parameter amount  | 출금액
    "! @parameter result  | 출금 후 잔액, 위반(음수·초과)이면 -1
    METHODS withdraw_or_reject
      IMPORTING balance       TYPE i
                amount        TYPE i
      RETURNING VALUE(result) TYPE i.
ENDCLASS.


CLASS zcl_modulo_tst01_except IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== TST01 예외 처리·CX 분류·DbC ===` ).
    out->write( |divide_or_zero(10,2)      = { divide_or_zero( dividend = 10 divisor = 2 ) }| ).
    out->write( |divide_or_zero(10,0) 흡수  = { divide_or_zero( dividend = 10 divisor = 0 ) }| ).
    out->write( |withdraw_or_reject(100,30) = { withdraw_or_reject( balance = 100 amount = 30 ) }| ).
    out->write( |withdraw_or_reject(100,150)= { withdraw_or_reject( balance = 100 amount = 150 ) }| ).
  ENDMETHOD.

  METHOD divide_or_zero.
    TRY.
        result = NEW lcl_calculator( )->divide( dividend = dividend divisor = divisor ).
      CATCH lcx_invalid_arg.
        " 흡수: 도메인 예외를 안전한 기본값으로 바꾼다.
        result = 0.
    ENDTRY.
  ENDMETHOD.

  METHOD withdraw_or_reject.
    TRY.
        result = NEW lcl_calculator( )->withdraw( balance = balance amount = amount ).
      CATCH lcx_invalid_arg.
        result = -1.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
