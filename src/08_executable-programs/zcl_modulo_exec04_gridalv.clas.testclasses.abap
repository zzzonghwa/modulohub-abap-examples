CLASS ltcl_gridalv DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_exec04_gridalv.
    METHODS setup.
    METHODS editable_grid    FOR TESTING.
    METHODS readonly_salv    FOR TESTING.
ENDCLASS.


CLASS ltcl_gridalv IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD editable_grid.
    cl_abap_unit_assert=>assert_equals(
      act = cut->recommend_alv( abap_true ) exp = `CL_GUI_ALV_GRID` ).
  ENDMETHOD.

  METHOD readonly_salv.
    cl_abap_unit_assert=>assert_equals(
      act = cut->recommend_alv( abap_false ) exp = `CL_SALV_TABLE` ).
  ENDMETHOD.
ENDCLASS.
