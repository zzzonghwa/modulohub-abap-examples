CLASS ltcl_cds DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_sql04_cds.
    METHODS setup.
    METHODS consume_counts_rows  FOR TESTING.
    METHODS load_factor_full     FOR TESTING.
    METHODS load_factor_partial  FOR TESTING.
    METHODS load_factor_miss     FOR TESTING.
    METHODS name_via_association  FOR TESTING.
    METHODS name_miss_blank       FOR TESTING.
ENDCLASS.


CLASS ltcl_cds IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD consume_counts_rows.
    cl_abap_unit_assert=>assert_equals( act = cut->consume_count( ) exp = 5 ).
  ENDMETHOD.

  METHOD load_factor_full.
    cl_abap_unit_assert=>assert_equals(
      act = cut->load_factor_percent( carrier = 'LH' connid = '0400' ) exp = 100 ).
  ENDMETHOD.

  METHOD load_factor_partial.
    cl_abap_unit_assert=>assert_equals(
      act = cut->load_factor_percent( carrier = 'AA' connid = '0017' ) exp = 90 ).
  ENDMETHOD.

  METHOD load_factor_miss.
    cl_abap_unit_assert=>assert_equals(
      act = cut->load_factor_percent( carrier = 'ZZ' connid = '9999' ) exp = 0 ).
  ENDMETHOD.

  METHOD name_via_association.
    cl_abap_unit_assert=>assert_equals( act = cut->carrier_name( 'AA' ) exp = 'Alpha Air' ).
  ENDMETHOD.

  METHOD name_miss_blank.
    cl_abap_unit_assert=>assert_equals( act = cut->carrier_name( 'XX' ) exp = space ).
  ENDMETHOD.
ENDCLASS.
