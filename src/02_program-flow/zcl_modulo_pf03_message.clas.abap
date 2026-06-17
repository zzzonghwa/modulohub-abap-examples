CLASS zcl_modulo_pf03_message DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
    INTERFACES if_oo_adt_classrun.

    "! 캡처된 메시지. MESSAGE ... INTO는 화면에 띄우지 않고 텍스트와
    "! sy-msg* 필드를 채운다(로깅·검증 게이트용).
    TYPES:
      BEGIN OF captured,
        text   TYPE string,
        id     TYPE sy-msgid,
        number TYPE sy-msgno,
        type   TYPE sy-msgty,
      END OF captured.

    "! T100 메시지(클래스 00, 번호 398 = &1&2&3&4)를 화면 없이 캡처한다.
    "! WITH 인자 개수는 placeholder 개수(4)와 맞춰야 ATC가 통과한다.
    "! @parameter first  | placeholder &1
    "! @parameter second | placeholder &2
    "! @parameter result | 캡처된 텍스트 + 식별자(type=S)
    METHODS capture_info
      IMPORTING first         TYPE string
                second        TYPE string
      RETURNING VALUE(result) TYPE captured.

    "! 메시지 유형(S/I/W/E ...)을 지정해 캡처한다. 동적 MESSAGE ID...TYPE...
    "! NUMBER... 형식. INTO라 흐름을 막지 않고 캡처만 한다.
    "! @parameter message_type | 메시지 유형(예: 'E')
    "! @parameter detail        | placeholder &1
    "! @parameter result        | 캡처된 메시지(type=message_type)
    METHODS capture_typed
      IMPORTING message_type  TYPE sy-msgty
                detail        TYPE string
      RETURNING VALUE(result) TYPE captured.

    "! 메시지 유형을 사람이 읽는 텍스트로. CASE ... WHEN OTHERS.
    "! @parameter message_type | 유형 문자
    "! @parameter text         | "Success"/"Error" 등
    METHODS type_text
      IMPORTING message_type TYPE sy-msgty
      RETURNING VALUE(text)  TYPE string.

    "! 흐름을 막는 유형(E/A/X)인지 판정한다.
    "! @parameter message_type | 유형 문자
    "! @parameter result       | 막는 유형이면 abap_true
    METHODS is_blocking_type
      IMPORTING message_type  TYPE sy-msgty
      RETURNING VALUE(result) TYPE abap_bool.
ENDCLASS.


CLASS zcl_modulo_pf03_message IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== PF03 메시지/로깅 ===` ).
    DATA(info) = capture_info( first = `hello` second = `world` ).
    out->write( |capture_info: id={ info-id } no={ info-number } type={ info-type }| ).
    out->write( |capture_info text = { info-text }| ).
    DATA(err) = capture_typed( message_type = 'E' detail = `boom` ).
    out->write( |capture_typed( E ): type={ err-type } text={ err-text }| ).
    out->write( |type_text( E )       = { type_text( 'E' ) }| ).
    out->write( |is_blocking_type( E )= { is_blocking_type( 'E' ) }| ).
    out->write( |is_blocking_type( S )= { is_blocking_type( 'S' ) }| ).
  ENDMETHOD.

  METHOD capture_info.
    " 398(00)은 placeholder 4개(&1&2&3&4). WITH 개수를 placeholder 수에
    " 맞춰야 ATC(Extended Program Check)가 통과한다 — 나머지는 빈 칸.
    MESSAGE s398(00) WITH first second `` `` INTO result-text.
    result-id     = sy-msgid.
    result-number = sy-msgno.
    result-type   = sy-msgty.
  ENDMETHOD.

  METHOD capture_typed.
    MESSAGE ID '00' TYPE message_type NUMBER '398'
            WITH detail `` `` `` INTO result-text.
    result-id     = sy-msgid.
    result-number = sy-msgno.
    result-type   = sy-msgty.
  ENDMETHOD.

  METHOD type_text.
    CASE message_type.
      WHEN 'S'.
        text = `Success`.
      WHEN 'I'.
        text = `Information`.
      WHEN 'W'.
        text = `Warning`.
      WHEN 'E'.
        text = `Error`.
      WHEN 'A'.
        text = `Abort`.
      WHEN 'X'.
        text = `Exit`.
      WHEN OTHERS.
        text = `Unknown`.
    ENDCASE.
  ENDMETHOD.

  METHOD is_blocking_type.
    result = xsdbool( message_type = 'E' OR message_type = 'A' OR message_type = 'X' ).
  ENDMETHOD.
ENDCLASS.
