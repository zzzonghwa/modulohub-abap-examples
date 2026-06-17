CLASS ltcl_loopmod DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_it03_loopmod.
    METHODS setup.
    METHODS sums_quantity        FOR TESTING.
    METHODS raises_prices_inplace FOR TESTING.
    METHODS bumps_qty_via_ref     FOR TESTING.
    METHODS counts_active_rows    FOR TESTING.
    METHODS names_in_index_range  FOR TESTING.
    METHODS deactivates_cheap     FOR TESTING.
    METHODS deletes_inactive      FOR TESTING.
ENDCLASS.


CLASS ltcl_loopmod IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD sums_quantity.
    cl_abap_unit_assert=>assert_equals( act = cut->total_qty( ) exp = 25 ).
  ENDMETHOD.

  METHOD raises_prices_inplace.
    DATA(expected) = CONV zcl_modulo_it03_loopmod=>amount( '22.00' ).
    cl_abap_unit_assert=>assert_equals( act = cut->raise_prices( ) exp = expected ).
  ENDMETHOD.

  METHOD bumps_qty_via_ref.
    cl_abap_unit_assert=>assert_equals( act = cut->bump_qty_ref( ) exp = 31 ).
  ENDMETHOD.

  METHOD counts_active_rows.
    cl_abap_unit_assert=>assert_equals( act = cut->count_active( ) exp = 4 ).
  ENDMETHOD.

  METHOD names_in_index_range.
    cl_abap_unit_assert=>assert_equals(
      act = cut->names_from_to( ) exp = `Notebook,Eraser,Marker` ).
  ENDMETHOD.

  METHOD deactivates_cheap.
    cl_abap_unit_assert=>assert_equals( act = cut->deactivate_cheap( '2.00' ) exp = 3 ).
  ENDMETHOD.

  METHOD deletes_inactive.
    cl_abap_unit_assert=>assert_equals( act = cut->delete_inactive( ) exp = 4 ).
  ENDMETHOD.
ENDCLASS.
