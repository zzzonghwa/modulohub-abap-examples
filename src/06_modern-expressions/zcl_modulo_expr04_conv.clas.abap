CLASS zcl_modulo_expr04_conv DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
    "!
    "! CONV: 명시 변환(타입 추론이 안 되는 자리에서 변환을 분명히 한다).
    "! CAST: 참조의 하위형 다운캐스트(틀리면 CX_SY_MOVE_CAST_ERROR).
    "! REF:  데이터 참조 생성(REF #( ... )), ->* 로 역참조.
    "! EXACT: 무손실 변환만 허용 — 손실이면 예외(CONV는 조용히 반올림/절단).
    INTERFACES if_oo_adt_classrun.

    "! CONV: 문자열을 정수로 명시 변환.
    "! @parameter text   | 숫자 문자열
    "! @parameter result | 정수 값
    METHODS to_integer
      IMPORTING text          TYPE string
      RETURNING VALUE(result) TYPE i.

    "! CAST: 기반 참조가 가리키는 하위형(lcl_dog)으로 다운캐스트해 고유 메서드 호출.
    "! @parameter result | lcl_dog 고유 메서드 fetch의 결과
    METHODS cast_dog_fetch
      RETURNING VALUE(result) TYPE string.

    "! REF: 변수의 데이터 참조를 만들어 ->* 로 원본을 직접 바꾼다.
    "! @parameter result | 참조를 통해 10 -> +5 한 값(15)
    METHODS bump_via_ref
      RETURNING VALUE(result) TYPE i.

    "! EXACT: 무손실이면 변환, 손실이면 CX_SY_CONVERSION_ERROR 계열 예외 -> -1.
    "! @parameter value  | 변환할 십진수
    "! @parameter result | 정수(무손실)일 때 그 값, 손실이면 -1
    METHODS exact_int
      IMPORTING value         TYPE decfloat34
      RETURNING VALUE(result) TYPE i.
ENDCLASS.


CLASS zcl_modulo_expr04_conv IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== EXPR04 CONV·CAST·REF·EXACT ===` ).
    out->write( |to_integer('42')   = { to_integer( `42` ) }| ).
    out->write( |cast_dog_fetch     = { cast_dog_fetch( ) }| ).
    out->write( |bump_via_ref       = { bump_via_ref( ) }| ).
    out->write( |exact_int(4)       = { exact_int( '4' ) }| ).
    out->write( |exact_int(4.5) 손실 = { exact_int( '4.5' ) }| ).
  ENDMETHOD.

  METHOD to_integer.
    " 문자열 -> 정수. CONV로 변환 타입을 명시한다.
    result = CONV i( text ).
  ENDMETHOD.

  METHOD cast_dog_fetch.
    " 업캐스트: lcl_dog 객체를 기반 참조(lcl_animal)에 담는다(넓히기, 항상 안전).
    DATA(animal) = CAST lcl_animal( NEW lcl_dog( ) ).
    " 다운캐스트: CAST로 하위형 참조를 얻어 lcl_dog 고유 메서드를 호출한다(좁히기).
    result = CAST lcl_dog( animal )->fetch( ).
  ENDMETHOD.

  METHOD bump_via_ref.
    DATA value TYPE i VALUE 10.
    DATA(ref) = REF #( value ).
    " ->* 는 참조가 가리키는 원본 데이터. 참조로 바꾸면 원본이 바뀐다.
    ref->* = ref->* + 5.
    result = value.
  ENDMETHOD.

  METHOD exact_int.
    TRY.
        " EXACT는 무손실만 허용 — 4.5처럼 정수로 못 줄이면 예외.
        result = EXACT i( value ).
      CATCH cx_sy_conversion_error.
        result = -1.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
