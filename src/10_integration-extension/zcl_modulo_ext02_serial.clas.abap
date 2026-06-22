CLASS zcl_modulo_ext02_serial DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
    "!
    "! 경량 직렬화 — 외부 의존 없이 표준 도구로 XML·JSON 변환.
    "! - asXML: CALL TRANSFORMATION id(커널 항등 변환). 의존 0·이식성 최고.
    "! - JSON: /ui2/cl_json(온프렘 표준). ABAP Cloud에선 xco_cp_json.
    "! 검증은 라운드트립(직렬화->역직렬화 후 원본과 동일)으로 한다 — 포맷 차이에 둔감하다.
    "! RFC/BAPI 소비: released BAPI를 CALL FUNCTION 'BAPI_...' (DESTINATION)으로 호출한다
    "!   — 시스템·연결 의존이라 여기선 개념만 둔다.
    INTERFACES if_oo_adt_classrun.

    TYPES tags TYPE STANDARD TABLE OF string WITH EMPTY KEY.

    "! asXML 직렬화 후 역직렬화한 결과가 원본과 같은지(라운드트립).
    "! @parameter result | 보존되면 abap_true
    METHODS xml_roundtrip_ok
      RETURNING VALUE(result) TYPE abap_bool.

    "! JSON(/ui2/cl_json) 라운드트립.
    "! @parameter result | 보존되면 abap_true
    METHODS json_roundtrip_ok
      RETURNING VALUE(result) TYPE abap_bool.

    "! 샘플을 JSON 문자열로 직렬화(F9 출력·내용 확인용).
    "! @parameter result | JSON 문자열
    METHODS to_json
      RETURNING VALUE(result) TYPE string.

  PRIVATE SECTION.
    "! 직렬화 대상 — 중첩 테이블(tags)을 포함해 복합 구조 변환을 보인다.
    TYPES:
      BEGIN OF item,
        id   TYPE i,
        name TYPE string,
        tags TYPE tags,
      END OF item.

    "! 데모용 샘플 한 건.
    METHODS sample
      RETURNING VALUE(result) TYPE item.
ENDCLASS.


CLASS zcl_modulo_ext02_serial IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== EXT02 XML·JSON 직렬화 ===` ).
    out->write( |xml_roundtrip_ok  = { xml_roundtrip_ok( ) }| ).
    out->write( |json_roundtrip_ok = { json_roundtrip_ok( ) }| ).
    out->write( |to_json           = { to_json( ) }| ).
  ENDMETHOD.

  METHOD xml_roundtrip_ok.
    DATA serialized TYPE xstring.
    DATA restored TYPE item.
    DATA(original) = sample( ).
    " 항등 변환 id로 ABAP 데이터 <-> asXML.
    CALL TRANSFORMATION id SOURCE data = original RESULT XML serialized.
    CALL TRANSFORMATION id SOURCE XML serialized RESULT data = restored.
    result = xsdbool( restored = original ).
  ENDMETHOD.

  METHOD json_roundtrip_ok.
    DATA restored TYPE item.
    DATA(original) = sample( ).
    DATA(json) = /ui2/cl_json=>serialize( data = original ).
    /ui2/cl_json=>deserialize( EXPORTING json = json CHANGING data = restored ).
    result = xsdbool( restored = original ).
  ENDMETHOD.

  METHOD to_json.
    result = /ui2/cl_json=>serialize( data = sample( ) ).
  ENDMETHOD.

  METHOD sample.
    result = VALUE item( id = 1 name = `widget` tags = VALUE #( ( `a` ) ( `b` ) ) ).
  ENDMETHOD.
ENDCLASS.
