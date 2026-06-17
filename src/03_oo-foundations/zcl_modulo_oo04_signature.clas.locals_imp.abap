"! 메서드 시그니처 5종(IMPORTING/EXPORTING/CHANGING/RETURNING/RAISING)을 한 곳에서 대조.
CLASS lcl_calc DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    "! RETURNING(함수형) — 반환 파라미터는 항상 VALUE 전달. 이름은 result 권장.
    "! IMPORTING에 VALUE()를 쓰면 복사본을 받아 호출자 별칭 부작용이 없다.
    METHODS add
      IMPORTING VALUE(a)      TYPE i
                VALUE(b)      TYPE i
      RETURNING VALUE(result) TYPE i.

    "! EXPORTING — 출력 전용, 복수 가능. 처음 값을 채우는 용도.
    METHODS split
      IMPORTING total     TYPE i
                parts     TYPE i
      EXPORTING quotient  TYPE i
                remainder TYPE i.

    "! CHANGING — 이미 값이 있는 변수를 제자리에서 갱신(참조 전달이 기본).
    METHODS accumulate
      IMPORTING amount        TYPE i
      CHANGING  running_total TYPE i.

    "! RETURNING + RAISING — 0으로 나누면 클래스 기반 예외를 던진다(상세 계층은 07-1).
    METHODS divide
      IMPORTING dividend      TYPE i
                divisor       TYPE i
      RETURNING VALUE(result) TYPE decfloat34
      RAISING   cx_sy_zerodivide.

    "! OPTIONAL + DEFAULT — name은 생략 가능, greeting은 미전달 시 기본값.
    "! IS SUPPLIED 로 실제 전달 여부를 구분한다.
    METHODS greet
      IMPORTING name          TYPE string OPTIONAL
                greeting      TYPE string DEFAULT `Hello`
      RETURNING VALUE(result) TYPE string.

    "! PREFERRED PARAMETER — 모든 IMPORTING이 OPTIONAL/DEFAULT일 때만 허용.
    "! 이름 없이 단일 인자를 넘기면 text에 바인딩(가독성상 드물게 사용 권장).
    METHODS label
      IMPORTING text          TYPE string OPTIONAL
                prefix        TYPE string DEFAULT `#`
      PREFERRED PARAMETER text
      RETURNING VALUE(result) TYPE string.
ENDCLASS.


CLASS lcl_calc IMPLEMENTATION.
  METHOD add.
    result = a + b.
  ENDMETHOD.

  METHOD split.
    quotient  = total DIV parts.
    remainder = total MOD parts.
  ENDMETHOD.

  METHOD accumulate.
    running_total = running_total + amount.
  ENDMETHOD.

  METHOD divide.
    IF divisor = 0.
      RAISE EXCEPTION TYPE cx_sy_zerodivide.
    ENDIF.
    result = dividend / divisor.
  ENDMETHOD.

  METHOD greet.
    DATA(who) = COND string( WHEN name IS SUPPLIED THEN name ELSE `world` ).
    result = |{ greeting }, { who }!|.
  ENDMETHOD.

  METHOD label.
    result = |{ prefix }{ text }|.
  ENDMETHOD.
ENDCLASS.
