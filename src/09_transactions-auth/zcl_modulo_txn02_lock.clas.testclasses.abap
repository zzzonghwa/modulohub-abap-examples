CLASS ltcl_lock DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_txn02_lock.
    METHODS setup.
    METHODS foreign_lock_carries_owner FOR TESTING.
    METHODS shared_coexist            FOR TESTING.
    METHODS exclusive_cumulative      FOR TESTING.
    METHODS non_cumulative            FOR TESTING.
    METHODS logical_lock              FOR TESTING.
    METHODS reacquire                 FOR TESTING.
    METHODS dequeue_one_of_two        FOR TESTING.
    METHODS commit_releases           FOR TESTING.
    METHODS rollback_scope            FOR TESTING.
    METHODS rollback_keeps3            FOR TESTING.
    METHODS system_failure            FOR TESTING.
ENDCLASS.


CLASS ltcl_lock IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD foreign_lock_carries_owner.
    " USER_A가 먼저 잠그므로 USER_B의 충돌 예외에 소유자 USER_A가 담긴다.
    cl_abap_unit_assert=>assert_equals( act = cut->foreign_lock_owner( ) exp = `USER_A` ).
  ENDMETHOD.

  METHOD shared_coexist.
    cl_abap_unit_assert=>assert_true( act = cut->shared_locks_coexist( ) ).
  ENDMETHOD.

  METHOD exclusive_cumulative.
    " E 잠금 2회 누적 -> 깊이 2.
    cl_abap_unit_assert=>assert_equals( act = cut->exclusive_cumulates( ) exp = 2 ).
  ENDMETHOD.

  METHOD non_cumulative.
    cl_abap_unit_assert=>assert_true( act = cut->non_cumulative_rejected( ) ).
  ENDMETHOD.

  METHOD logical_lock.
    " 미존재 키 1건 잠금 -> 보유 1.
    cl_abap_unit_assert=>assert_equals( act = cut->logical_lock_nonexistent( ) exp = 1 ).
  ENDMETHOD.

  METHOD reacquire.
    cl_abap_unit_assert=>assert_true( act = cut->reacquire_after_dequeue( ) ).
  ENDMETHOD.

  METHOD dequeue_one_of_two.
    " 누적 깊이 2 -> dequeue 1회 -> 남은 깊이 1.
    cl_abap_unit_assert=>assert_equals( act = cut->dequeue_decrements( ) exp = 1 ).
  ENDMETHOD.

  METHOD commit_releases.
    cl_abap_unit_assert=>assert_equals( act = cut->released_on_commit( ) exp = 0 ).
  ENDMETHOD.

  METHOD rollback_scope.
    " scope_update(2) 1건만 제거, scope_dialog(1) 1건은 남음 -> 1.
    cl_abap_unit_assert=>assert_equals( act = cut->rollback_removes_scope2_only( ) exp = 1 ).
  ENDMETHOD.

  METHOD rollback_keeps3.
    " scope_both(3) 1건은 rollback이 건드리지 않고, scope_update(2) 1건만 제거 -> 1.
    cl_abap_unit_assert=>assert_equals( act = cut->rollback_keeps_scope3( ) exp = 1 ).
  ENDMETHOD.

  METHOD system_failure.
    cl_abap_unit_assert=>assert_true( act = cut->system_failure_distinct( ) ).
  ENDMETHOD.
ENDCLASS.
