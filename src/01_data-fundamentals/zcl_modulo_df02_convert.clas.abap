CLASS zcl_modulo_df02_convert DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
    INTERFACES if_oo_adt_classrun.

    "! 숫자 텍스트 필드(타입 n). 유효값은 숫자 문자뿐이고 초기값은 모두 '0'.
    TYPES digit_string TYPE n LENGTH 10.

    "! CONV로 변환한다. CONV는 변환 규칙을 그대로 따르며, 정수 타깃은
    "! 상업적 반올림(0.5 이상 올림)을 적용한다 — 손실을 막지 않는다.
    "! @parameter value  | 변환할 십진수
    "! @parameter result | i로 반올림된 값
    METHODS to_int_rounded
      IMPORTING value         TYPE decfloat34
      RETURNING VALUE(result) TYPE i.

    "! EXACT로 무손실 변환한다. 값 손실(반올림)이 발생하면 대입하지 않고
    "! CX_SY_CONVERSION_ERROR(여기서는 ...ROUNDING)를 던진다.
    "! @parameter value     | 변환할 십진수
    "! @parameter result    | 손실 없이 변환된 i
    "! @raising cx_sy_conversion_error | 무손실 변환 불가 시
    METHODS to_int_lossless
      IMPORTING value         TYPE decfloat34
      RETURNING VALUE(result) TYPE i
      RAISING   cx_sy_conversion_error.

    "! 수치를 문자열로 변환한다. string 템플릿으로 선행 공백 없이 포맷한다
    "! (CONV string은 정수에 선행 공백을 붙이는 함정이 있다).
    "! @parameter value  | 정수
    "! @parameter result | 문자열 표현
    METHODS to_text
      IMPORTING value         TYPE i
      RETURNING VALUE(result) TYPE string.

    "! 숫자 문자열(타입 n 호환)을 정수로 변환한다(CONV i).
    "! @parameter digits | 숫자로만 이루어진 문자열
    "! @parameter result | 정수값
    METHODS digits_to_int
      IMPORTING digits        TYPE digit_string
      RETURNING VALUE(result) TYPE i.

    "! 무손실 계산(EXACT). a/b가 십진으로 정확히 표현되면 통과,
    "! 무한소수면 반올림 예외를 던진다(EXACT는 식 계산에도 적용된다).
    "! @parameter dividend | 피제수
    "! @parameter divisor  | 제수
    "! @parameter result   | 정확한 몫
    "! @raising cx_sy_conversion_error | 정확히 표현 불가 시
    METHODS exact_ratio
      IMPORTING dividend      TYPE i
                divisor       TYPE i
      RETURNING VALUE(result) TYPE decfloat34
      RAISING   cx_sy_conversion_error.
ENDCLASS.


CLASS zcl_modulo_df02_convert IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== DF02 변환 CONV/EXACT ===` ).
    out->write( |to_int_rounded( 2.6 ) = { to_int_rounded( CONV #( '2.6' ) ) }| ).
    out->write( |to_text( 42 )         = { to_text( 42 ) }| ).
    out->write( |digits_to_int         = { digits_to_int( '0000000042' ) }| ).
    TRY.
        out->write( |to_int_lossless( 4 ) = { to_int_lossless( CONV #( '4' ) ) }| ).
        out->write( |exact_ratio( 1, 4 )  = { exact_ratio( dividend = 1 divisor = 4 ) }| ).
        exact_ratio( dividend = 1 divisor = 3 ).
      CATCH cx_sy_conversion_error.
        out->write( `exact_ratio( 1, 3 ) -> 무손실 불가 예외(정상)` ).
    ENDTRY.
  ENDMETHOD.

  METHOD to_int_rounded.
    result = CONV i( value ).
  ENDMETHOD.

  METHOD to_int_lossless.
    result = EXACT i( value ).
  ENDMETHOD.

  METHOD to_text.
    " CONV string( i )는 선행 공백을 붙인다. string 템플릿은 패딩 없이
    " 숫자를 그대로 포맷하므로 "42" 같은 깔끔한 결과를 준다.
    result = |{ value }|.
  ENDMETHOD.

  METHOD digits_to_int.
    result = CONV i( digits ).
  ENDMETHOD.

  METHOD exact_ratio.
    " EXACT 안에서 산술식을 계산해야 무손실 검사가 작동한다. 밖에서 미리
    " decfloat34로 나누면 반올림이 먼저 일어나 검사를 통과해버린다.
    result = EXACT decfloat34( dividend / divisor ).
  ENDMETHOD.
ENDCLASS.
