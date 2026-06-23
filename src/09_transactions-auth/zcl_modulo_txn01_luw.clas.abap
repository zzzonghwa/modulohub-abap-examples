"! <p>ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.</p>
"! <p>SAP LUW(논리적 작업 단위)·번들링 개념.</p>
"! <ul>
"! <li>원칙: DB 변경은 COMMIT WORK까지 보류되며 한 LUW로 묶여 전부-또는-전무로 확정된다.
"! ROLLBACK WORK는 보류 변경을 취소한다.</li>
"! <li>번들링: 변경을 update FM(CALL FUNCTION ... IN UPDATE TASK)·PERFORM ON COMMIT subroutine으로
"! 모았다가 COMMIT WORK 한 번에 실행한다(왕복·정합성). 실행 순서·우선순위·동기/비동기를
"! 인메모리 Unit of Work(locals_imp)로 자체완결 시연한다.</li>
"! <li>실 DB 변경문·update FM 활성화·ENQUEUE/DEQUEUE, 권한은 별도 예제에서 다룬다.</li>
"! </ul>
CLASS zcl_modulo_txn01_luw DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    "! 등록 후 COMMIT WORK -> 보류 변경이 모두 실행(확정)된다.
    "! @parameter result | 실행된 변경 수(3)
    METHODS commit_count
      RETURNING VALUE(result) TYPE i.

    "! 등록 후 ROLLBACK WORK -> 아무것도 실행되지 않는다(보류 폐기).
    "! @parameter result | 실행된 변경 수(0)
    METHODS rollback_count
      RETURNING VALUE(result) TYPE i.

    "! 번들 경계: commit된 변경은 남고, 다음 LUW의 보류분만 rollback이 버린다.
    "! @parameter result | 실행된 변경 수(2)
    METHODS bundle_boundary
      RETURNING VALUE(result) TYPE i.

    "! COMMIT WORK 없이 종료하면 등록된 update FM은 실행되지 않는다.
    "! @parameter result | 실행된 변경 수(0)
    METHODS orphan_not_executed
      RETURNING VALUE(result) TYPE i.

    "! 번들 실행 순서: PERFORM ON COMMIT 절차가 update FM보다 먼저 실행된다.
    "! ON 'A' 등록 -> update FM 'U' 등록 -> commit. 실행 로그는 'A','U' 순.
    "! @parameter result | 실행 로그를 '|'로 이은 문자열('A|U')
    METHODS on_commit_runs_first
      RETURNING VALUE(result) TYPE string.

    "! PERFORM ON COMMIT LEVEL: 절차는 LEVEL 오름차순으로 실행된다(동일 LEVEL=등록 순서).
    "! LEVEL 20·10·10 순으로 등록해도 실행은 10,10,20 -> 'B|C|A'.
    "! @parameter result | LEVEL 순 실행 로그('B|C|A')
    METHODS on_commit_level_order
      RETURNING VALUE(result) TYPE string.

    "! update FM 우선순위: VB1(high)이 등록 순서대로 먼저, 그 뒤 VB2(low)가 실행된다.
    "! low 'L', high 'H1', high 'H2' 등록 -> 실행은 'H1|H2|L'.
    "! @parameter result | 우선순위 순 실행 로그('H1|H2|L')
    METHODS priority_vb1_before_vb2
      RETURNING VALUE(result) TYPE string.

    "! COMMIT WORK(비동기, AND WAIT 없음)는 update 결과와 무관하게 항상 sy-subrc=0.
    "! update 실패를 표시해도 비동기 commit은 0을 반환한다.
    "! @parameter result | 반환 코드(0)
    METHODS async_commit_subrc
      RETURNING VALUE(result) TYPE i.

    "! COMMIT WORK AND WAIT(동기)는 update 실패를 sy-subrc=4로 반영한다.
    "! @parameter result | 반환 코드(4 — 동기 update 실패)
    METHODS sync_commit_failure_subrc
      RETURNING VALUE(result) TYPE i.

    "! ROLLBACK 후 재시작: rollback으로 닫힌 SAP LUW의 보류는 사라지고,
    "! 새 LUW에 다시 등록·commit하면 그 변경만 실행된다(경계 이동).
    "! @parameter result | 최종 실행된 변경 수(1)
    METHODS rollback_then_recommit
      RETURNING VALUE(result) TYPE i.

    "! SAP LUW : database LUW = 1 : N 수치 예시.
    "! dialog step 3회 = 빈 DB LUW 3 + COMMIT WORK 번들 실행 DB LUW 1 = 총 4.
    "! @parameter dialog_steps | dialog step 수
    "! @parameter result       | 총 database LUW 수(dialog_steps + 1)
    METHODS database_luw_count
      IMPORTING dialog_steps  TYPE i
      RETURNING VALUE(result) TYPE i.
ENDCLASS.


CLASS zcl_modulo_txn01_luw IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== TXN01 SAP LUW·번들링 (개념) ===` ).
    out->write( |commit_count             = { commit_count( ) }| ).
    out->write( |rollback_count           = { rollback_count( ) }| ).
    out->write( |bundle_boundary          = { bundle_boundary( ) }| ).
    out->write( |orphan_not_executed      = { orphan_not_executed( ) }| ).
    out->write( |on_commit_runs_first     = { on_commit_runs_first( ) } (ON COMMIT -> update FM)| ).
    out->write( |on_commit_level_order    = { on_commit_level_order( ) } (LEVEL 오름차순)| ).
    out->write( |priority_vb1_before_vb2  = { priority_vb1_before_vb2( ) } (VB1 -> VB2)| ).
    out->write( |async_commit_subrc       = { async_commit_subrc( ) } (비동기=항상 0)| ).
    out->write( |sync_commit_failure_subrc= { sync_commit_failure_subrc( ) } (AND WAIT 실패=4)| ).
    out->write( |rollback_then_recommit   = { rollback_then_recommit( ) }| ).
    out->write( |database_luw_count(3)    = { database_luw_count( 3 ) } (1:N)| ).
    out->write( `보류 변경은 COMMIT WORK에서 한 LUW로 실행·확정, ROLLBACK WORK에서 폐기된다.` ).
  ENDMETHOD.

  METHOD commit_count.
    DATA(uow) = NEW lcl_unit_of_work( ).
    uow->register_update_fm( `1` ).
    uow->register_update_fm( `2` ).
    uow->register_update_fm( `3` ).
    uow->commit_work( ).
    result = uow->executed_count( ).
  ENDMETHOD.

  METHOD rollback_count.
    DATA(uow) = NEW lcl_unit_of_work( ).
    uow->register_update_fm( `1` ).
    uow->register_update_fm( `2` ).
    uow->register_update_fm( `3` ).
    uow->rollback_work( ).
    result = uow->executed_count( ).
  ENDMETHOD.

  METHOD bundle_boundary.
    DATA(uow) = NEW lcl_unit_of_work( ).
    uow->register_update_fm( `1` ).
    uow->register_update_fm( `2` ).
    uow->commit_work( ).
    " 다음 LUW의 보류 변경을 롤백 -> 앞서 확정된 2건은 영향 없음.
    uow->register_update_fm( `3` ).
    uow->rollback_work( ).
    result = uow->executed_count( ).
  ENDMETHOD.

  METHOD orphan_not_executed.
    DATA(uow) = NEW lcl_unit_of_work( ).
    uow->register_update_fm( `1` ).
    uow->register_update_fm( `2` ).
    " COMMIT WORK 없이 종료 -> 등록 update FM은 실행되지 않는다.
    uow->discard_without_commit( ).
    result = uow->executed_count( ).
  ENDMETHOD.

  METHOD on_commit_runs_first.
    DATA(uow) = NEW lcl_unit_of_work( ).
    uow->register_update_fm( `U` ).
    uow->register_on_commit( `A` ).
    uow->commit_work( ).
    result = concat_lines_of( table = uow->executed_log( ) sep = `|` ).
  ENDMETHOD.

  METHOD on_commit_level_order.
    DATA(uow) = NEW lcl_unit_of_work( ).
    " 등록 순서와 무관하게 LEVEL 오름차순으로 실행(동일 LEVEL은 등록 순서).
    uow->register_on_commit( label = `A` level = 20 ).
    uow->register_on_commit( label = `B` level = 10 ).
    uow->register_on_commit( label = `C` level = 10 ).
    uow->commit_work( ).
    result = concat_lines_of( table = uow->executed_log( ) sep = `|` ).
  ENDMETHOD.

  METHOD priority_vb1_before_vb2.
    DATA(uow) = NEW lcl_unit_of_work( ).
    " 등록 순서: low 먼저지만 실행은 VB1(high) 등록순 -> VB2(low) 등록순.
    uow->register_update_fm( label = `L` priority = lcl_unit_of_work=>low ).
    uow->register_update_fm( label = `H1` priority = lcl_unit_of_work=>high ).
    uow->register_update_fm( label = `H2` priority = lcl_unit_of_work=>high ).
    uow->commit_work( ).
    result = concat_lines_of( table = uow->executed_log( ) sep = `|` ).
  ENDMETHOD.

  METHOD async_commit_subrc.
    DATA(uow) = NEW lcl_unit_of_work( ).
    uow->register_update_fm( `1` ).
    " update 실패를 표시해도 비동기 COMMIT WORK는 트리거 시점에 결과를 모르므로 0.
    uow->fail_next_update( ).
    result = uow->commit_work( ).
  ENDMETHOD.

  METHOD sync_commit_failure_subrc.
    DATA(uow) = NEW lcl_unit_of_work( ).
    uow->register_update_fm( `1` ).
    uow->fail_next_update( ).
    " AND WAIT(동기): update work process 결과를 기다려 실패를 sy-subrc=4로 받는다.
    result = uow->commit_work( wait = abap_true ).
  ENDMETHOD.

  METHOD rollback_then_recommit.
    DATA(uow) = NEW lcl_unit_of_work( ).
    uow->register_update_fm( `1` ).
    uow->register_update_fm( `2` ).
    uow->rollback_work( ).
    " 새 SAP LUW: rollback으로 보류가 비었으므로 이 등록만 실행된다.
    uow->register_update_fm( `3` ).
    uow->commit_work( ).
    result = uow->executed_count( ).
  ENDMETHOD.

  METHOD database_luw_count.
    " dialog step마다 work process 교체 -> 암묵적 commit으로 "빈" DB LUW 1회씩,
    " 마지막 COMMIT WORK 번들 실행이 실제 변경을 담는 DB LUW 1회. 총 = steps + 1.
    result = dialog_steps + 1.
  ENDMETHOD.
ENDCLASS.
