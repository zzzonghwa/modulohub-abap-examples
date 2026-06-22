CLASS ltcl_basics DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_sql01_basics.
    METHODS setup.
    METHODS into_table_counts_rows FOR TESTING.
    METHODS scalar_counts_rows     FOR TESTING.
    METHODS single_row_hit         FOR TESTING.
    METHODS single_row_miss_zero   FOR TESTING.
ENDCLASS.


CLASS ltcl_basics IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD into_table_counts_rows.
    cl_abap_unit_assert=>assert_equals( act = cut->read_into_table( ) exp = 4 ).
  ENDMETHOD.

  METHOD scalar_counts_rows.
    cl_abap_unit_assert=>assert_equals( act = cut->count_into_scalar( ) exp = 4 ).
  ENDMETHOD.

  METHOD single_row_hit.
    cl_abap_unit_assert=>assert_equals(
      act = cut->read_single_row( carrier = 'AA' connid = '0017' ) exp = 380 ).
  ENDMETHOD.

  METHOD single_row_miss_zero.
    cl_abap_unit_assert=>assert_equals(
      act = cut->read_single_row( carrier = 'ZZ' connid = '9999' ) exp = 0 ).
  ENDMETHOD.
ENDCLASS.
