CLASS zcl_modulo_sql07_api DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
    "!
    "! released API 소비(읽기 전용)와 "확장 계약" 읽는 법.
    "! - API State C1(Released): SAP이 안정성을 보장하는 공개 계약. 업그레이드에도 시그니처 유지.
    "! - 확인법: ADT에서 객체 열고 Properties -> 'API State', 또는 'Released Objects' 뷰로 탐색.
    "! - 왜 released만: Clean Core·클라우드 준비 — non-released 소비는 업그레이드에 깨질 수 있다.
    "! - 예: CL_ABAP_CONTEXT_INFO(C1)는 SY/SYST 전역 구조 대신 시스템·사용자 정보를 노출한다.
    "! 출력(날짜·시간)은 실행 시점·시스템마다 달라 manual-report로 분류한다 — 각자 환경에서 확인.
    INTERFACES if_oo_adt_classrun.

    "! released API로 시스템 날짜를 읽는다.
    "! @parameter result | 시스템 날짜
    METHODS system_date
      RETURNING VALUE(result) TYPE d.

    "! released API로 시스템 시간을 읽는다.
    "! @parameter result | 시스템 시간
    METHODS system_time
      RETURNING VALUE(result) TYPE t.
ENDCLASS.


CLASS zcl_modulo_sql07_api IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== SQL07 released API 소비 (API State C1) ===` ).
    out->write( |system_date = { system_date( ) DATE = ISO }| ).
    out->write( |system_time = { system_time( ) TIME = ISO }| ).
    out->write( `값은 시스템·시점마다 다르다 — released 계약(C1)은 "메서드가 존재하고 동작함"을 보장한다.` ).
  ENDMETHOD.

  METHOD system_date.
    " SY-DATUM 대신 released API로 읽는다(클라우드 준비·Clean Core).
    result = cl_abap_context_info=>get_system_date( ).
  ENDMETHOD.

  METHOD system_time.
    result = cl_abap_context_info=>get_system_time( ).
  ENDMETHOD.
ENDCLASS.
