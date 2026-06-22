CLASS ltcl_xco DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_ext01_xco.
    METHODS setup.
    METHODS upper_case  FOR TESTING.
    METHODS lower_case  FOR TESTING.
    METHODS uuid_filled FOR TESTING.
ENDCLASS.


CLASS ltcl_xco IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD upper_case.
    cl_abap_unit_assert=>assert_equals( act = cut->to_upper( `abap` ) exp = `ABAP` ).
  ENDMETHOD.

  METHOD lower_case.
    cl_abap_unit_assert=>assert_equals( act = cut->to_lower( `ABAP` ) exp = `abap` ).
  ENDMETHOD.

  METHOD uuid_filled.
    " UUID 값은 비결정적이므로 "비지 않음"만 검증한다.
    cl_abap_unit_assert=>assert_not_initial( act = cut->new_uuid( ) ).
  ENDMETHOD.
ENDCLASS.
