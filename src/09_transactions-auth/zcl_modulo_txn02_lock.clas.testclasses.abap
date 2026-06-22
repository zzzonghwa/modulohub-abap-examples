CLASS ltcl_lock DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_txn02_lock.
    METHODS setup.
    METHODS conflict_on_same_key FOR TESTING.
    METHODS free_after_dequeue   FOR TESTING.
    METHODS commit_releases_all  FOR TESTING.
ENDCLASS.


CLASS ltcl_lock IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD conflict_on_same_key.
    cl_abap_unit_assert=>assert_true( act = cut->foreign_lock_raised( ) ).
  ENDMETHOD.

  METHOD free_after_dequeue.
    cl_abap_unit_assert=>assert_true( act = cut->reacquire_after_dequeue( ) ).
  ENDMETHOD.

  METHOD commit_releases_all.
    cl_abap_unit_assert=>assert_equals( act = cut->released_on_commit( ) exp = 0 ).
  ENDMETHOD.
ENDCLASS.
