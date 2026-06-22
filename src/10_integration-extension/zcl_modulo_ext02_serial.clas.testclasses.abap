CLASS ltcl_serial DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_ext02_serial.
    METHODS setup.
    METHODS xml_preserves   FOR TESTING.
    METHODS json_preserves  FOR TESTING.
    METHODS json_has_value  FOR TESTING.
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

  METHOD json_has_value.
    " 필드명 대소문자는 구현마다 달라도, 값 'widget'은 JSON에 들어 있어야 한다.
    cl_abap_unit_assert=>assert_true( act = xsdbool( cut->to_json( ) CS `widget` ) ).
  ENDMETHOD.
ENDCLASS.
