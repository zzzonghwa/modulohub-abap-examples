CLASS ltcl_luw DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_txn01_luw.
    METHODS setup.
    METHODS commit_persists   FOR TESTING.
    METHODS rollback_discards FOR TESTING.
    METHODS boundary_keeps    FOR TESTING.
ENDCLASS.


CLASS ltcl_luw IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD commit_persists.
    cl_abap_unit_assert=>assert_equals( act = cut->commit_count( ) exp = 3 ).
  ENDMETHOD.

  METHOD rollback_discards.
    cl_abap_unit_assert=>assert_equals( act = cut->rollback_count( ) exp = 0 ).
  ENDMETHOD.

  METHOD boundary_keeps.
    cl_abap_unit_assert=>assert_equals( act = cut->bundle_boundary( ) exp = 2 ).
  ENDMETHOD.
ENDCLASS.
