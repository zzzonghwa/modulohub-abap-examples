CLASS zcl_modulo_txn03_auth DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
    "!
    "! 인증 체크(AUTHORITY-CHECK)·권한 객체 소비.
    "! - AUTHORITY-CHECK는 현재 사용자가 권한 객체(여기선 표준 S_TCODE)의 필드 값에 대해
    "!   인가를 가졌는지 검사한다. sy-subrc = 0 허가, 4 권한 없음, 그 외(8/12) 설정 오류.
    "! - 결과는 사용자·역할에 따라 다르다(시스템 의존) — 출력은 실행 사용자 기준으로 본다.
    "! - 규율: 데이터/실행 진입점마다 적절한 권한 객체로 체크한다(누락은 보안 결함).
    INTERFACES if_oo_adt_classrun.

    "! 현재 사용자가 해당 트랜잭션을 실행할 권한이 있는지 검사한다.
    "! @parameter tcode  | 트랜잭션 코드(예: 'SE80')
    "! @parameter result | 권한이 있으면 abap_true
    METHODS can_start_tcode
      IMPORTING tcode         TYPE sy-tcode
      RETURNING VALUE(result) TYPE abap_bool.
ENDCLASS.


CLASS zcl_modulo_txn03_auth IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== TXN03 인증 체크 (AUTHORITY-CHECK) ===` ).
    out->write( |can_start_tcode('SE80') = { can_start_tcode( 'SE80' ) }| ).
    out->write( |can_start_tcode('SU01') = { can_start_tcode( 'SU01' ) }| ).
    out->write( `결과는 실행 사용자의 권한(역할)에 따라 달라진다.` ).
  ENDMETHOD.

  METHOD can_start_tcode.
    AUTHORITY-CHECK OBJECT 'S_TCODE'
      ID 'TCD' FIELD tcode.
    result = xsdbool( sy-subrc = 0 ).
  ENDMETHOD.
ENDCLASS.
