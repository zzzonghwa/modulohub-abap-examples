"! <p>ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.</p>
CLASS zcl_modulo_df03_ddic DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    "! DDIC 데이터 요소를 TYPE으로 소비한다. 도메인 ZMODULO_DEBIT_CREDIT가
    "! 기술 속성(CHAR 1 + 고정값 H/S)을, 동명 데이터 요소가 의미(레이블)를
    "! 담는다. 프로그램은 도메인을 직접 참조하지 못하고 데이터 요소를 거친다.
    TYPES indicator TYPE zmodulo_debit_credit.

    "! 도메인 고정값. ABAP 런타임은 고정값 외 대입을 막지 않으므로,
    "! 소비 코드는 상수로 의미를 드러낸다(매직 리터럴 회피).
    CONSTANTS debit  TYPE indicator VALUE 'S'.
    CONSTANTS credit TYPE indicator VALUE 'H'.

    "! 차변(debit) 여부.
    "! @parameter sign   | 차대 구분(H=Credit, S=Debit)
    "! @parameter result | 차변이면 abap_true
    METHODS is_debit
      IMPORTING sign          TYPE indicator
      RETURNING VALUE(result) TYPE abap_bool.

    "! 대변(credit) 여부.
    "! @parameter sign   | 차대 구분
    "! @parameter result | 대변이면 abap_true
    METHODS is_credit
      IMPORTING sign          TYPE indicator
      RETURNING VALUE(result) TYPE abap_bool.

    "! 도메인 고정값(H/S) 중 하나인지 검증한다. 고정값은 ABAP 런타임이
    "! 강제하지 않으므로 소비 코드가 직접 가드해야 한다는 점을 보인다.
    "! @parameter sign   | 검사할 값
    "! @parameter result | H 또는 S이면 abap_true
    METHODS is_valid
      IMPORTING sign          TYPE indicator
      RETURNING VALUE(result) TYPE abap_bool.

    "! 사람이 읽는 레이블로 변환한다.
    "! @parameter sign  | 차대 구분
    "! @parameter label | "Debit"/"Credit"
    "! @raising cx_parameter_invalid_range | 고정값이 아닐 때
    METHODS label_of
      IMPORTING sign         TYPE indicator
      RETURNING VALUE(label) TYPE string
      RAISING   cx_parameter_invalid_range.

    "! 반대 차대 구분을 돌려준다(H<->S).
    "! @parameter sign   | 차대 구분
    "! @parameter result | 반대 값
    "! @raising cx_parameter_invalid_range | 고정값이 아닐 때
    METHODS opposite_of
      IMPORTING sign          TYPE indicator
      RETURNING VALUE(result) TYPE indicator
      RAISING   cx_parameter_invalid_range.
ENDCLASS.


CLASS zcl_modulo_df03_ddic IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== DF03 DDIC 도메인/데이터요소 ===` ).
    out->write( |is_debit( 'S' )  = { is_debit( debit ) }| ).
    out->write( |is_credit( 'H' ) = { is_credit( credit ) }| ).
    out->write( |is_valid( 'Z' )  = { is_valid( 'Z' ) }| ).
    TRY.
        out->write( |label_of( 'S' )    = { label_of( debit ) }| ).
        out->write( |opposite_of( 'S' ) = { opposite_of( debit ) }| ).
        label_of( 'Z' ).
      CATCH cx_parameter_invalid_range.
        out->write( `label_of( 'Z' ) -> 고정값 아님 가드 예외(정상)` ).
    ENDTRY.
  ENDMETHOD.

  METHOD is_debit.
    result = xsdbool( sign = debit ).
  ENDMETHOD.

  METHOD is_credit.
    result = xsdbool( sign = credit ).
  ENDMETHOD.

  METHOD is_valid.
    result = xsdbool( sign = debit OR sign = credit ).
  ENDMETHOD.

  METHOD label_of.
    CASE sign.
      WHEN debit.
        label = `Debit`.
      WHEN credit.
        label = `Credit`.
      WHEN OTHERS.
        RAISE EXCEPTION TYPE cx_parameter_invalid_range.
    ENDCASE.
  ENDMETHOD.

  METHOD opposite_of.
    CASE sign.
      WHEN debit.
        result = credit.
      WHEN credit.
        result = debit.
      WHEN OTHERS.
        RAISE EXCEPTION TYPE cx_parameter_invalid_range.
    ENDCASE.
  ENDMETHOD.
ENDCLASS.
