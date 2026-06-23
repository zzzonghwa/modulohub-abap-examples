"! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
"!
"! XML·JSON·직렬화·RFC/BAPI 소비 — 외부 의존 없이 표준 도구로 직렬화의 폭을 시연한다(노트 10-02).
"! 검증은 라운드트립(직렬화->역직렬화 후 원본과 동일)으로 한다 — 포맷 차이에 둔감하다.
"!
"! 소절 대응(노트 본문 주장):
"! - A. CALL TRANSFORMATION 방향(claim 1~3): id 항등 변환으로 ABAP<->asXML, sXML JSON writer로
"!   ABAP->asJSON, SOURCE/RESULT의 XML 키워드 유무가 직렬화/역직렬화를 가른다.
"! - B. 역직렬화 규칙(claim 4~5): 비존재 컴포넌트는 이전 값 유지, OPTIONS clear='ALL'은 초기화로 통일.
"! - C. OPTIONS 심화(claim 6): xml_header='NO' 등으로 변환 동작 제어.
"! - D. 예외 계층(claim 8): CX_TRANSFORMATION_ERROR 단일 핸들러로 XSLT·ST 포괄.
"! - E. sXML 라이브러리(claim 11~12): CL_SXML_STRING_WRITER/READER 스트리밍, JSON·XML 포맷 전환.
"! - F. iXML 라이브러리(claim 10·33): CL_IXML_CORE DOM 빌더로 XML 생성.
"! - G. JSON 3선택지(claim 14~15): XCO_CP_JSON(Clean Core 1순위) vs sXML writer vs /ui2/cl_json(레거시).
"! - H. RFC/BAPI 소비(claim 17·23~26): CALL FUNCTION DESTINATION·BAPIRET2 type CA 'EA' 판정은
"!   시스템·연결 의존이라 여기선 BAPIRET2 에러 판정 로직만 자체완결로 시연한다.
CLASS zcl_modulo_ext02_serial DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    TYPES tags TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    "! BAPI 반환 메시지 한 건(BAPIRET2 축약형) — RFC/BAPI 오류 판정 데모용.
    TYPES:
      BEGIN OF bapi_message,
        type    TYPE c LENGTH 1,
        id      TYPE c LENGTH 20,
        number  TYPE n LENGTH 3,
        message TYPE string,
      END OF bapi_message.
    TYPES bapi_messages TYPE STANDARD TABLE OF bapi_message WITH EMPTY KEY.

    "! asXML 직렬화 후 역직렬화한 결과가 원본과 같은지(라운드트립).
    "! CALL TRANSFORMATION id — 커널 항등 변환. SOURCE/RESULT의 XML 키워드가 방향을 가른다.
    "! @parameter result | 보존되면 abap_true
    METHODS xml_roundtrip_ok
      RETURNING VALUE(result) TYPE abap_bool.

    "! sXML JSON writer로 ABAP->asJSON. CL_SXML_STRING_WRITER(type=co_xt_json) 경유 라운드트립.
    "! @parameter result | 보존되면 abap_true
    METHODS json_roundtrip_ok
      RETURNING VALUE(result) TYPE abap_bool.

    "! XCO_CP_JSON 라운드트립(Clean Core 1순위). from_abap->to_string / from_string->write_to.
    "! @parameter result | 보존되면 abap_true
    METHODS xco_json_roundtrip_ok
      RETURNING VALUE(result) TYPE abap_bool.

    "! /ui2/cl_json 라운드트립(레거시 참조용. released 아님 — 신규 코드 비권장).
    "! @parameter result | 보존되면 abap_true
    METHODS legacy_json_roundtrip_ok
      RETURNING VALUE(result) TYPE abap_bool.

    "! 샘플을 asJSON 문자열로 직렬화(sXML JSON writer). 키는 ABAP 컴포넌트명 UPPERCASE.
    "! @parameter result | asJSON 문자열
    METHODS to_json
      RETURNING VALUE(result) TYPE string.

    "! 샘플을 asXML 문자열로 직렬화. <asx:abap ...>로 시작하는 SAP 전용 XML.
    "! @parameter result | asXML 문자열
    METHODS to_xml
      RETURNING VALUE(result) TYPE string.

    "! XCO_CP_JSON으로 직렬화한 JSON 문자열(체인 API). 키는 UPPERCASE.
    "! @parameter result | JSON 문자열
    METHODS to_xco_json
      RETURNING VALUE(result) TYPE string.

    "! OPTIONS 심화(claim 6): xml_header='NO'로 XML 선언(<?xml ...?>) 출력을 끈다.
    "! @parameter result | XML 헤더가 없으면 abap_true
    METHODS xml_without_header_ok
      RETURNING VALUE(result) TYPE abap_bool.

    "! 역직렬화 규칙(claim 5): JSON에 없는 컴포넌트는 이전 값 유지. clear='ALL'이면 초기화.
    "! 빈 JSON {}을 채워진 구조에 역직렬화한 뒤, default 동작 시 name 보존 여부를 본다.
    "! @parameter result | 미전송 필드가 보존되면 abap_true
    METHODS missing_field_keeps_value
      RETURNING VALUE(result) TYPE abap_bool.

    "! 역직렬화 규칙(claim 5): OPTIONS clear='ALL'은 미전송 필드를 초기화한다.
    "! @parameter result | clear='ALL'로 name이 초기화되면 abap_true
    METHODS clear_all_resets_value
      RETURNING VALUE(result) TYPE abap_bool.

    "! 예외 계층(claim 8): 잘못된 XML을 id로 역직렬화하면 CX_TRANSFORMATION_ERROR가 잡힌다.
    "! CX_TRANSFORMATION_ERROR 단일 핸들러로 XSLT·ST 양쪽을 포괄함을 보인다.
    "! @parameter result | 변환 예외가 잡히면 abap_true
    METHODS invalid_xml_raises
      RETURNING VALUE(result) TYPE abap_bool.

    "! iXML(DOM) 빌더(claim 10·33): CL_IXML_CORE로 XML 트리를 만들고 루트 태그명을 읽는다.
    "! @parameter result | 생성한 루트 요소 이름('item')
    METHODS ixml_root_name
      RETURNING VALUE(result) TYPE string.

    "! sXML 포맷 전환(claim 11): 같은 데이터를 XML writer로도 직렬화 — type 상수만 바꾼다.
    "! @parameter result | asXML 결과가 비어있지 않으면 abap_true
    METHODS sxml_xml_writer_ok
      RETURNING VALUE(result) TYPE abap_bool.

    "! BAPI 오류 판정(claim 24): return 테이블에 type CA 'EA'(Error/Abort)가 있으면 실패로 본다.
    "! CALL FUNCTION 자체는 시스템 의존이라 BAPIRET2 판정 로직만 자체완결로 시연한다.
    "! @parameter messages | BAPI 반환 메시지 테이블
    "! @parameter result   | E·A 메시지가 하나라도 있으면 abap_true
    METHODS bapi_has_error
      IMPORTING messages      TYPE bapi_messages
      RETURNING VALUE(result) TYPE abap_bool.

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
    out->write( `=== EXT02 XML·JSON·직렬화·RFC/BAPI 소비 ===` ).
    out->write( |xml_roundtrip_ok          = { xml_roundtrip_ok( ) } (id asXML)| ).
    out->write( |json_roundtrip_ok         = { json_roundtrip_ok( ) } (sXML JSON writer)| ).
    out->write( |xco_json_roundtrip_ok     = { xco_json_roundtrip_ok( ) } (XCO_CP_JSON)| ).
    out->write( |legacy_json_roundtrip_ok  = { legacy_json_roundtrip_ok( ) } (/ui2/cl_json 레거시)| ).
    out->write( |to_json                   = { to_json( ) }| ).
    out->write( |to_xco_json               = { to_xco_json( ) }| ).
    out->write( |xml_without_header_ok     = { xml_without_header_ok( ) } (OPTIONS xml_header)| ).
    out->write( |missing_field_keeps_value = { missing_field_keeps_value( ) } (clear=NONE)| ).
    out->write( |clear_all_resets_value    = { clear_all_resets_value( ) } (OPTIONS clear=ALL)| ).
    out->write( |invalid_xml_raises        = { invalid_xml_raises( ) } (CX_TRANSFORMATION_ERROR)| ).
    out->write( |ixml_root_name            = { ixml_root_name( ) } (iXML DOM)| ).
    out->write( |sxml_xml_writer_ok        = { sxml_xml_writer_ok( ) } (sXML 포맷 전환)| ).
    DATA(messages) = VALUE bapi_messages(
      ( type = 'S' message = `posted` )
      ( type = 'E' message = `locked` ) ).
    out->write( |bapi_has_error            = { bapi_has_error( messages ) } (BAPIRET2 CA 'EA')| ).
  ENDMETHOD.

  METHOD xml_roundtrip_ok.
    DATA serialized TYPE xstring.
    DATA restored TYPE item.
    DATA(original) = sample( ).
    " 항등 변환 id로 ABAP 데이터 <-> asXML. RESULT XML = 직렬화, SOURCE XML = 역직렬화.
    CALL TRANSFORMATION id SOURCE data = original RESULT XML serialized.
    CALL TRANSFORMATION id SOURCE XML serialized RESULT data = restored.
    result = xsdbool( restored = original ).
  ENDMETHOD.

  METHOD json_roundtrip_ok.
    DATA restored TYPE item.
    DATA(original) = sample( ).
    " sXML JSON writer: type=co_xt_json으로 asJSON 생성(claim 11·34).
    DATA(writer) = cl_sxml_string_writer=>create( type = if_sxml=>co_xt_json ).
    CALL TRANSFORMATION id SOURCE data = original RESULT XML writer.
    " JSON reader로 역직렬화 — sXML reader를 SOURCE XML에 직접 넘긴다.
    DATA(reader) = cl_sxml_string_reader=>create( writer->get_output( ) ).
    CALL TRANSFORMATION id SOURCE XML reader RESULT data = restored.
    result = xsdbool( restored = original ).
  ENDMETHOD.

  METHOD xco_json_roundtrip_ok.
    DATA restored TYPE item.
    DATA(original) = sample( ).
    " XCO_CP_JSON 체인(claim 15): from_abap->to_string / from_string->write_to.
    DATA(json) = xco_cp_json=>data->from_abap( original )->to_string( ).
    xco_cp_json=>data->from_string( json )->write_to( REF #( restored ) ).
    result = xsdbool( restored = original ).
  ENDMETHOD.

  METHOD legacy_json_roundtrip_ok.
    DATA restored TYPE item.
    DATA(original) = sample( ).
    " /ui2/cl_json은 released 아님 — 레거시 코드 읽기 참조용(claim 14). 신규 코드 비권장.
    DATA(json) = /ui2/cl_json=>serialize( data = original ).
    /ui2/cl_json=>deserialize( EXPORTING json = json CHANGING data = restored ).
    result = xsdbool( restored = original ).
  ENDMETHOD.

  METHOD to_json.
    " sXML JSON writer 결과를 string으로 변환(claim 34). 키는 컴포넌트명 UPPERCASE.
    DATA(original) = sample( ).
    DATA(writer) = cl_sxml_string_writer=>create( type = if_sxml=>co_xt_json ).
    CALL TRANSFORMATION id SOURCE data = original RESULT XML writer.
    result = cl_abap_conv_codepage=>create_in( )->convert( writer->get_output( ) ).
  ENDMETHOD.

  METHOD to_xml.
    DATA serialized TYPE xstring.
    DATA(original) = sample( ).
    CALL TRANSFORMATION id SOURCE data = original RESULT XML serialized.
    result = cl_abap_conv_codepage=>create_in( )->convert( serialized ).
  ENDMETHOD.

  METHOD to_xco_json.
    result = xco_cp_json=>data->from_abap( sample( ) )->to_string( ).
  ENDMETHOD.

  METHOD xml_without_header_ok.
    DATA serialized TYPE xstring.
    DATA(original) = sample( ).
    " OPTIONS xml_header='NO'(claim 6): <?xml version="1.0"?> 선언을 출력하지 않는다.
    CALL TRANSFORMATION id SOURCE data = original
                           RESULT XML serialized
                           OPTIONS xml_header = 'no'.
    DATA(text) = cl_abap_conv_codepage=>create_in( )->convert( serialized ).
    result = xsdbool( text NS `<?xml` ).
  ENDMETHOD.

  METHOD missing_field_keeps_value.
    " 미전송 필드 보존(claim 5): JSON에 id만 있으면 name은 이전 값을 유지한다(clear=NONE 기본).
    DATA(restored) = VALUE item( name = `kept` ).
    DATA(reader) = cl_sxml_string_reader=>create(
      cl_abap_conv_codepage=>create_out( )->convert( `{"ID":9}` ) ).
    CALL TRANSFORMATION id SOURCE XML reader RESULT data = restored.
    " id는 새로 9, name은 비전송이라 'kept' 유지.
    result = xsdbool( restored-id = 9 AND restored-name = `kept` ).
  ENDMETHOD.

  METHOD clear_all_resets_value.
    " OPTIONS clear='ALL'(claim 5): 비전송 필드를 초기화로 통일 -> name이 공백이 된다.
    DATA(restored) = VALUE item( name = `kept` ).
    DATA(reader) = cl_sxml_string_reader=>create(
      cl_abap_conv_codepage=>create_out( )->convert( `{"ID":9}` ) ).
    CALL TRANSFORMATION id SOURCE XML reader
                           RESULT data = restored
                           OPTIONS clear = 'all'.
    result = xsdbool( restored-id = 9 AND restored-name IS INITIAL ).
  ENDMETHOD.

  METHOD invalid_xml_raises.
    " 예외 계층(claim 8): 깨진 XML을 역직렬화하면 CX_TRANSFORMATION_ERROR 단일 핸들러로 잡힌다.
    DATA restored TYPE item.
    TRY.
        DATA(reader) = cl_sxml_string_reader=>create(
          cl_abap_conv_codepage=>create_out( )->convert( `<not><closed>` ) ).
        CALL TRANSFORMATION id SOURCE XML reader RESULT data = restored.
        result = abap_false.
      CATCH cx_transformation_error.
        result = abap_true.
    ENDTRY.
  ENDMETHOD.

  METHOD ixml_root_name.
    " iXML(DOM) 빌더(claim 10·33): core->document->element 트리를 메모리에 만든다.
    DATA(core) = cl_ixml=>create( ).
    DATA(document) = core->create_document( ).
    DATA(root) = document->create_element( name = `item` ).
    document->append_child( root ).
    " 임의 노드 직접 접근 — DOM의 강점. 여기선 루트 태그명을 다시 읽는다.
    result = document->get_root_element( )->get_name( ).
  ENDMETHOD.

  METHOD sxml_xml_writer_ok.
    " sXML 포맷 전환(claim 11~12): 같은 코드에서 type만 co_xt_xml10으로 두면 XML이 나온다.
    DATA(original) = sample( ).
    DATA(writer) = cl_sxml_string_writer=>create( type = if_sxml=>co_xt_xml10 ).
    CALL TRANSFORMATION id SOURCE data = original RESULT XML writer.
    " IS INITIAL은 데이터 오브젝트에만 — 메서드 결과는 변수로 받아 검사한다.
    DATA(output) = writer->get_output( ).
    result = xsdbool( output IS NOT INITIAL ).
  ENDMETHOD.

  METHOD bapi_has_error.
    " BAPIRET2 판정(claim 24): type이 'E'(Error)·'A'(Abort) 중 하나면 실패. CA = contains any.
    result = xsdbool( line_exists( messages[ table_line-type = 'E' ] )
                   OR line_exists( messages[ table_line-type = 'A' ] ) ).
  ENDMETHOD.

  METHOD sample.
    result = VALUE item( id = 1 name = `widget` tags = VALUE #( ( `a` ) ( `b` ) ) ).
  ENDMETHOD.
ENDCLASS.
