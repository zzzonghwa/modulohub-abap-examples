CLASS zcl_modulo_ext01_xco DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
    "!
    "! XCO(eXtension Components) 라이브러리 소비 — 고전 FM의 released 대체(API State C1).
    "! - 문자열: TO_UPPER/STRING_UPPER_CASE FM 대신 xco_cp=>string( )->to_upper_case( ).
    "! - UUID: GUID_CREATE류 FM 대신 xco_cp=>uuid( ).
    "! XCO는 released라 업그레이드·클라우드에 안정적(Clean Core). 플루언트 API로 읽기 쉽다.
    INTERFACES if_oo_adt_classrun.

    "! XCO 문자열 API로 대문자화(고전 TO_UPPER FM 대체).
    "! @parameter text   | 입력 문자열
    "! @parameter result | 대문자 변환 결과
    METHODS to_upper
      IMPORTING text          TYPE string
      RETURNING VALUE(result) TYPE string.

    "! XCO 문자열 API로 소문자화.
    "! @parameter text   | 입력 문자열
    "! @parameter result | 소문자 변환 결과
    METHODS to_lower
      IMPORTING text          TYPE string
      RETURNING VALUE(result) TYPE string.

    "! XCO로 UUID 생성(고전 GUID_CREATE FM 대체). 값은 매번 다르다.
    "! @parameter result | 새 UUID 문자열
    METHODS new_uuid
      RETURNING VALUE(result) TYPE string.
ENDCLASS.


CLASS zcl_modulo_ext01_xco IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== EXT01 released API·XCO 소비 ===` ).
    out->write( |to_upper('abap') = { to_upper( `abap` ) }| ).
    out->write( |to_lower('ABAP') = { to_lower( `ABAP` ) }| ).
    out->write( |new_uuid        = { new_uuid( ) }| ).
  ENDMETHOD.

  METHOD to_upper.
    result = xco_cp=>string( text )->to_upper_case( )->value.
  ENDMETHOD.

  METHOD to_lower.
    result = xco_cp=>string( text )->to_lower_case( )->value.
  ENDMETHOD.

  METHOD new_uuid.
    result = xco_cp=>uuid( )->value.
  ENDMETHOD.
ENDCLASS.
