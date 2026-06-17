CLASS ltcl_tabtypes DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_it01_tabtypes.
    METHODS setup.
    METHODS standard_keeps_duplicate FOR TESTING.
    METHODS sorted_orders_by_name    FOR TESTING.
    METHODS hashed_finds_by_key      FOR TESTING.
    METHODS hashed_miss_is_blank     FOR TESTING.
    METHODS unique_key_rejects_dup   FOR TESTING.
    METHODS secondary_key_counts     FOR TESTING.
ENDCLASS.


CLASS ltcl_tabtypes IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD standard_keeps_duplicate.
    cl_abap_unit_assert=>assert_equals( act = cut->standard_allows_dups( ) exp = 7 ).
  ENDMETHOD.

  METHOD sorted_orders_by_name.
    cl_abap_unit_assert=>assert_equals(
      act = cut->sorted_keeps_order( ) exp = `Ahn,Choi,Kim,Lee,Park,Yoon` ).
  ENDMETHOD.

  METHOD hashed_finds_by_key.
    cl_abap_unit_assert=>assert_equals( act = cut->hashed_lookup( 3 ) exp = `Park` ).
  ENDMETHOD.

  METHOD hashed_miss_is_blank.
    cl_abap_unit_assert=>assert_initial( cut->hashed_lookup( 99 ) ).
  ENDMETHOD.

  METHOD unique_key_rejects_dup.
    cl_abap_unit_assert=>assert_equals( act = cut->unique_rejects_dup( ) exp = 4 ).
  ENDMETHOD.

  METHOD secondary_key_counts.
    cl_abap_unit_assert=>assert_equals( act = cut->via_secondary_key( `Seoul` ) exp = 2 ).
  ENDMETHOD.
ENDCLASS.
