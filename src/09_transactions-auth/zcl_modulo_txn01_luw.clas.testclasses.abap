CLASS ltcl_luw DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_txn01_luw.
    METHODS setup.
    METHODS commit_persists      FOR TESTING.
    METHODS rollback_discards    FOR TESTING.
    METHODS boundary_keeps       FOR TESTING.
    METHODS orphan_not_executed  FOR TESTING.
    METHODS on_commit_first      FOR TESTING.
    METHODS on_commit_level      FOR TESTING.
    METHODS priority_order       FOR TESTING.
    METHODS async_subrc_zero     FOR TESTING.
    METHODS sync_subrc_failure   FOR TESTING.
    METHODS rollback_recommit    FOR TESTING.
    METHODS db_luw_one_to_n      FOR TESTING.
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

  METHOD orphan_not_executed.
    cl_abap_unit_assert=>assert_equals( act = cut->orphan_not_executed( ) exp = 0 ).
  ENDMETHOD.

  METHOD on_commit_first.
    " ON COMMIT 절차(A)가 update FM(U)보다 먼저 실행된다.
    cl_abap_unit_assert=>assert_equals( act = cut->on_commit_runs_first( ) exp = `A|U` ).
  ENDMETHOD.

  METHOD on_commit_level.
    " LEVEL 20·10·10 등록 -> 10,10,20 순(동일 LEVEL은 등록 순서) = B,C,A.
    cl_abap_unit_assert=>assert_equals( act = cut->on_commit_level_order( ) exp = `B|C|A` ).
  ENDMETHOD.

  METHOD priority_order.
    " VB1 등록 순서대로 먼저, 그 뒤 VB2.
    cl_abap_unit_assert=>assert_equals( act = cut->priority_vb1_before_vb2( ) exp = `H1|H2|L` ).
  ENDMETHOD.

  METHOD async_subrc_zero.
    " 비동기 COMMIT WORK는 update 실패와 무관하게 항상 0.
    cl_abap_unit_assert=>assert_equals( act = cut->async_commit_subrc( ) exp = 0 ).
  ENDMETHOD.

  METHOD sync_subrc_failure.
    " AND WAIT(동기)는 update 실패를 4로 반영.
    cl_abap_unit_assert=>assert_equals( act = cut->sync_commit_failure_subrc( ) exp = 4 ).
  ENDMETHOD.

  METHOD rollback_recommit.
    cl_abap_unit_assert=>assert_equals( act = cut->rollback_then_recommit( ) exp = 1 ).
  ENDMETHOD.

  METHOD db_luw_one_to_n.
    " dialog step 3 + 번들 commit 1 = 4.
    cl_abap_unit_assert=>assert_equals( act = cut->database_luw_count( 3 ) exp = 4 ).
  ENDMETHOD.
ENDCLASS.
