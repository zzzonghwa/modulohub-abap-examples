CLASS ltcl_atc DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_tst03_atc.
    METHODS setup.
    METHODS labels_known    FOR TESTING.
    METHODS label_unknown   FOR TESTING.
    METHODS numeric_true    FOR TESTING.
    METHODS numeric_false   FOR TESTING.
ENDCLASS.


CLASS ltcl_atc IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD labels_known.
    cl_abap_unit_assert=>assert_equals( act = cut->severity_label( 1 ) exp = `ERROR` ).
    cl_abap_unit_assert=>assert_equals( act = cut->severity_label( 2 ) exp = `WARNING` ).
    cl_abap_unit_assert=>assert_equals( act = cut->severity_label( 3 ) exp = `INFO` ).
  ENDMETHOD.

  METHOD label_unknown.
    cl_abap_unit_assert=>assert_equals( act = cut->severity_label( 9 ) exp = `UNKNOWN` ).
  ENDMETHOD.

  METHOD numeric_true.
    cl_abap_unit_assert=>assert_true( act = cut->is_numeric( `42` ) ).
  ENDMETHOD.

  METHOD numeric_false.
    cl_abap_unit_assert=>assert_false( act = cut->is_numeric( `abc` ) ).
  ENDMETHOD.
ENDCLASS.
