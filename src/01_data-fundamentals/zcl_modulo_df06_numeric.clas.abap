CLASS zcl_modulo_df06_numeric DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! 정수 나눗셈의 몫(DIV). 소수부를 버린다.
    METHODS quotient
      IMPORTING dividend      TYPE i
                divisor       TYPE i
      RETURNING VALUE(result) TYPE i.

    "! 정수 나눗셈의 나머지(MOD).
    METHODS remainder
      IMPORTING dividend      TYPE i
                divisor       TYPE i
      RETURNING VALUE(result) TYPE i.

    "! 0으로 나누기를 가드한 안전 나눗셈. divisor=0이면 예외를 던진다.
    "! @parameter dividend | 피제수
    "! @parameter divisor  | 제수(0 금지)
    "! @parameter result   | 정수 몫
    "! @raising cx_sy_zerodivide | divisor가 0일 때
    METHODS safe_quotient
      IMPORTING dividend      TYPE i
                divisor       TYPE i
      RETURNING VALUE(result) TYPE i
      RAISING   cx_sy_zerodivide.

    "! 거듭제곱. 내장 함수 ipow는 결과 타입이 i(연산자 ** 는 f).
    METHODS power
      IMPORTING base          TYPE i
                exponent      TYPE i
      RETURNING VALUE(result) TYPE i.

    "! 정확한 비율. i끼리 / 하면 계산 타입이 i라 반올림되므로 decfloat34로
    "! 계산해 소수를 보존한다(계산 타입 함정 회피).
    METHODS ratio
      IMPORTING dividend      TYPE i
                divisor       TYPE i
      RETURNING VALUE(result) TYPE decfloat34.

    "! 절댓값(abs).
    METHODS absolute
      IMPORTING value         TYPE i
      RETURNING VALUE(result) TYPE i.

    "! 부호(sign): 음수 -1, 0, 양수 +1.
    METHODS sign_of
      IMPORTING value         TYPE i
      RETURNING VALUE(result) TYPE i.

    "! 소수부(frac): 3.25 -> 0.25.
    METHODS fraction
      IMPORTING value         TYPE decfloat34
      RETURNING VALUE(result) TYPE decfloat34.

    "! 정수부 절삭(trunc): 3.9 -> 3, -3.9 -> -3.
    METHODS truncate
      IMPORTING value         TYPE decfloat34
      RETURNING VALUE(result) TYPE i.
ENDCLASS.


CLASS zcl_modulo_df06_numeric IMPLEMENTATION.
  METHOD quotient.
    result = dividend DIV divisor.
  ENDMETHOD.

  METHOD remainder.
    result = dividend MOD divisor.
  ENDMETHOD.

  METHOD safe_quotient.
    IF divisor = 0.
      RAISE EXCEPTION TYPE cx_sy_zerodivide.
    ENDIF.
    result = dividend DIV divisor.
  ENDMETHOD.

  METHOD power.
    result = ipow( base = base exp = exponent ).
  ENDMETHOD.

  METHOD ratio.
    DATA(precise_dividend) = CONV decfloat34( dividend ).
    result = precise_dividend / divisor.
  ENDMETHOD.

  METHOD absolute.
    result = abs( value ).
  ENDMETHOD.

  METHOD sign_of.
    result = sign( value ).
  ENDMETHOD.

  METHOD fraction.
    result = frac( value ).
  ENDMETHOD.

  METHOD truncate.
    result = trunc( value ).
  ENDMETHOD.
ENDCLASS.
