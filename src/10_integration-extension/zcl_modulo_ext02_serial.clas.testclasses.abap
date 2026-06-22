CLASS ltcl_serial DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_ext02_serial.
    METHODS setup.
    METHODS xml_preserves        FOR TESTING.
    METHODS json_preserves       FOR TESTING.
    METHODS xco_json_preserves   FOR TESTING.
    METHODS legacy_json_preserves FOR TESTING.
    METHODS json_has_value       FOR TESTING.
    METHODS xco_json_upper_key   FOR TESTING.
    METHODS xml_is_asxml         FOR TESTING.
    METHODS xml_header_suppressed FOR TESTING.
    METHODS missing_field_kept   FOR TESTING.
    METHODS clear_all_resets     FOR TESTING.
    METHODS invalid_xml_caught   FOR TESTING.
    METHODS ixml_root            FOR TESTING.
    METHODS sxml_xml_nonempty    FOR TESTING.
    METHODS bapi_error_detected  FOR TESTING.
    METHODS bapi_all_success     FOR TESTING.
ENDCLASS.


CLASS ltcl_serial IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD xml_preserves.
    cl_abap_unit_assert=>assert_true( act = cut->xml_roundtrip_ok( ) ).
  ENDMETHOD.

  METHOD json_preserves.
    cl_abap_unit_assert=>assert_true( act = cut->json_roundtrip_ok( ) ).
  ENDMETHOD.

  METHOD xco_json_preserves.
    cl_abap_unit_assert=>assert_true( act = cut->xco_json_roundtrip_ok( ) ).
  ENDMETHOD.

  METHOD legacy_json_preserves.
    cl_abap_unit_assert=>assert_true( act = cut->legacy_json_roundtrip_ok( ) ).
  ENDMETHOD.

  METHOD json_has_value.
    " 필드명 대소문자는 구현마다 달라도, 값 'widget'은 JSON에 들어 있어야 한다.
    cl_abap_unit_assert=>assert_true( act = xsdbool( cut->to_json( ) CS `widget` ) ).
  ENDMETHOD.

  METHOD xco_json_upper_key.
    " asJSON 규칙: 키는 ABAP 컴포넌트명 UPPERCASE -> "NAME" 키가 존재한다.
    cl_abap_unit_assert=>assert_true( act = xsdbool( cut->to_xco_json( ) CS `"NAME"` ) ).
  ENDMETHOD.

  METHOD xml_is_asxml.
    " asXML은 SAP 전용 네임스페이스 asx:abap로 시작한다.
    cl_abap_unit_assert=>assert_true( act = xsdbool( cut->to_xml( ) CS `asx:abap` ) ).
  ENDMETHOD.

  METHOD xml_header_suppressed.
    cl_abap_unit_assert=>assert_true( act = cut->xml_without_header_ok( ) ).
  ENDMETHOD.

  METHOD missing_field_kept.
    " clear=NONE 기본: JSON에 없는 name은 이전 값 'kept'를 유지한다.
    cl_abap_unit_assert=>assert_true( act = cut->missing_field_keeps_value( ) ).
  ENDMETHOD.

  METHOD clear_all_resets.
    " OPTIONS clear='ALL': 미전송 name이 초기화(공백)된다.
    cl_abap_unit_assert=>assert_true( act = cut->clear_all_resets_value( ) ).
  ENDMETHOD.

  METHOD invalid_xml_caught.
    " 깨진 XML 역직렬화는 CX_TRANSFORMATION_ERROR 단일 핸들러로 잡힌다.
    cl_abap_unit_assert=>assert_true( act = cut->invalid_xml_raises( ) ).
  ENDMETHOD.

  METHOD ixml_root.
    cl_abap_unit_assert=>assert_equals( act = cut->ixml_root_name( )
                                        exp = `item` ).
  ENDMETHOD.

  METHOD sxml_xml_nonempty.
    cl_abap_unit_assert=>assert_true( act = cut->sxml_xml_writer_ok( ) ).
  ENDMETHOD.

  METHOD bapi_error_detected.
    " type 'E'(Error) 한 건이 있으면 실패로 판정한다.
    DATA(messages) = VALUE zcl_modulo_ext02_serial=>bapi_messages(
      ( type = 'S' message = `ok` )
      ( type = 'E' message = `error` ) ).
    cl_abap_unit_assert=>assert_true( act = cut->bapi_has_error( messages ) ).
  ENDMETHOD.

  METHOD bapi_all_success.
    " S·I·W만 있으면 에러 아님(CA 'EA' 미스).
    DATA(messages) = VALUE zcl_modulo_ext02_serial=>bapi_messages(
      ( type = 'S' message = `ok` )
      ( type = 'W' message = `warn` ) ).
    cl_abap_unit_assert=>assert_false( act = cut->bapi_has_error( messages ) ).
  ENDMETHOD.
ENDCLASS.
