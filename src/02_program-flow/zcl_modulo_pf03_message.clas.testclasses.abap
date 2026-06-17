CLASS ltcl_message DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_pf03_message.
    METHODS setup.
    METHODS captures_message_id   FOR TESTING.
    METHODS captures_message_text FOR TESTING.
    METHODS captures_error_type   FOR TESTING.
    METHODS renders_type_text     FOR TESTING.
    METHODS unknown_type_text     FOR TESTING.
    METHODS blocking_types        FOR TESTING.
    METHODS non_blocking_types    FOR TESTING.
ENDCLASS.


CLASS ltcl_message IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD captures_message_id.
    DATA(result) = cut->capture_info( first = `hello` second = `world` ).
    cl_abap_unit_assert=>assert_equals( act = result-id     exp = '00' ).
    cl_abap_unit_assert=>assert_equals( act = result-number exp = '398' ).
    cl_abap_unit_assert=>assert_equals( act = result-type   exp = 'S' ).
  ENDMETHOD.

  METHOD captures_message_text.
    DATA(result) = cut->capture_info( first = `hello` second = `world` ).
    cl_abap_unit_assert=>assert_true( xsdbool( result-text CS `hello` ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( result-text CS `world` ) ).
  ENDMETHOD.

  METHOD captures_error_type.
    " GIVEN 유형 'E' / WHEN 캡처 / THEN type=E (INTO라 흐름 차단 없음)
    DATA(result) = cut->capture_typed( message_type = 'E' detail = `boom` ).
    cl_abap_unit_assert=>assert_equals( act = result-type exp = 'E' ).
    cl_abap_unit_assert=>assert_true( xsdbool( result-text CS `boom` ) ).
  ENDMETHOD.

  METHOD renders_type_text.
    cl_abap_unit_assert=>assert_equals( act = cut->type_text( 'E' ) exp = `Error` ).
    cl_abap_unit_assert=>assert_equals( act = cut->type_text( 'S' ) exp = `Success` ).
  ENDMETHOD.

  METHOD unknown_type_text.
    cl_abap_unit_assert=>assert_equals( act = cut->type_text( 'Z' ) exp = `Unknown` ).
  ENDMETHOD.

  METHOD blocking_types.
    cl_abap_unit_assert=>assert_true( cut->is_blocking_type( 'E' ) ).
    cl_abap_unit_assert=>assert_true( cut->is_blocking_type( 'A' ) ).
  ENDMETHOD.

  METHOD non_blocking_types.
    cl_abap_unit_assert=>assert_false( cut->is_blocking_type( 'S' ) ).
    cl_abap_unit_assert=>assert_false( cut->is_blocking_type( 'W' ) ).
  ENDMETHOD.
ENDCLASS.
