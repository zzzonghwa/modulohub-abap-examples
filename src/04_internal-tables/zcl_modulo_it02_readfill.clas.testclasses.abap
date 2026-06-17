CLASS ltcl_readfill DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_it02_readfill.
    METHODS setup.
    METHODS appends_to_end       FOR TESTING.
    METHODS inserts_at_position  FOR TESTING.
    METHODS reads_by_index       FOR TESTING.
    METHODS reads_by_key         FOR TESTING.
    METHODS key_miss_is_zero     FOR TESTING.
    METHODS expression_by_key    FOR TESTING.
    METHODS line_exists_true     FOR TESTING.
    METHODS line_exists_false    FOR TESTING.
    METHODS index_of_line        FOR TESTING.
    METHODS missing_line_raises  FOR TESTING.
ENDCLASS.


CLASS ltcl_readfill IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD appends_to_end.
    cl_abap_unit_assert=>assert_equals( act = cut->append_then_count( ) exp = 3 ).
  ENDMETHOD.

  METHOD inserts_at_position.
    cl_abap_unit_assert=>assert_equals( act = cut->insert_at_index( ) exp = `Inserted` ).
  ENDMETHOD.

  METHOD reads_by_index.
    cl_abap_unit_assert=>assert_equals( act = cut->read_by_index( 2 ) exp = `Notebook` ).
  ENDMETHOD.

  METHOD reads_by_key.
    cl_abap_unit_assert=>assert_equals( act = cut->read_by_key( `Eraser` ) exp = 3 ).
  ENDMETHOD.

  METHOD key_miss_is_zero.
    cl_abap_unit_assert=>assert_equals( act = cut->read_by_key( `Ghost` ) exp = 0 ).
  ENDMETHOD.

  METHOD expression_by_key.
    cl_abap_unit_assert=>assert_equals( act = cut->expr_by_key( 4 ) exp = `Marker` ).
  ENDMETHOD.

  METHOD line_exists_true.
    cl_abap_unit_assert=>assert_true( cut->exists( 5 ) ).
  ENDMETHOD.

  METHOD line_exists_false.
    cl_abap_unit_assert=>assert_false( cut->exists( 99 ) ).
  ENDMETHOD.

  METHOD index_of_line.
    cl_abap_unit_assert=>assert_equals( act = cut->index_of( 5 ) exp = 5 ).
  ENDMETHOD.

  METHOD missing_line_raises.
    cl_abap_unit_assert=>assert_true( cut->missing_raises( ) ).
  ENDMETHOD.
ENDCLASS.
