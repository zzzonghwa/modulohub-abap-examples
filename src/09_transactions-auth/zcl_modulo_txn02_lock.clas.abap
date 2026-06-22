CLASS zcl_modulo_txn02_lock DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
    "!
    "! SAP 잠금(ENQUEUE/DEQUEUE)·COMMIT WORK·_SCOPE — 개념(09-2). 노트의 락 메커니즘
    "! (F 섹션 W26~W32, ATF A1~A7)을 자체완결 인메모리 lock table(locals_imp)로 시연한다.
    "! 실 시스템은 lock object(SE11, ENQU, E 접두사) 활성화로 ENQUEUE_<name>/DEQUEUE_<name>
    "! 함수모듈이 자동 생성된다. 전통형 FM 호출:
    "!   CALL FUNCTION 'ENQUEUE_EZMODULO_FLIGHT'
    "!     EXPORTING  mode_zmodulo_flight = 'E'   " 잠금 모드(E=배타)
    "!                carrid = 'LH' connid = '0400'
    "!                _scope = '2'                " 2=update task에 위임(기본)
    "!     EXCEPTIONS foreign_lock = 1 system_failure = 2 OTHERS = 3.
    "!   IF sy-subrc <> 0. " 충돌(sy-msgv1=소유자) 처리. ENDIF.
    "!   COMMIT WORK.                            " _scope=2면 update 완료 시 자동 해제
    "!   CALL FUNCTION 'DEQUEUE_EZMODULO_FLIGHT' EXPORTING carrid = 'LH' connid = '0400'.
    "! 모던 OO API(7.54+): cl_abap_lock_object_factory=>get_instance( )->enqueue( ) — 예외
    "! cx_abap_foreign_lock vs cx_abap_lock_failure로 구분(여기선 lcx_*로 대응 시연).
    "! 잠금은 중앙 enqueue 서버 메모리에 보관(DB 아님). 실 FM은 lock object 활성화에 의존한다.
    INTERFACES if_oo_adt_classrun.

    "! W30·A5 충돌 구분: 한 키를 잠근 뒤 다른 소유자가 같은 키를 배타 잠그면 foreign_lock.
    "! 예외에 소유자명(user_name)이 담긴다 — sy-msgv1(전통형) / foreign_lock->user_name(OO).
    "! @parameter result | 거부된 두 번째 잠금의 소유자명(`USER_A`)
    METHODS foreign_lock_owner
      RETURNING VALUE(result) TYPE string.

    "! W32 shared(S): 여러 사용자가 같은 키에 S 잠금을 동시에 보유할 수 있다.
    "! @parameter result | 두 번째 S 잠금이 성공하면 abap_true
    METHODS shared_locks_coexist
      RETURNING VALUE(result) TYPE abap_bool.

    "! W32 exclusive(E): 동일 사용자는 같은 키에 E 잠금을 누적(cumulative)할 수 있다.
    "! @parameter result | 두 번 enqueue 후 누적 깊이(2)
    METHODS exclusive_cumulates
      RETURNING VALUE(result) TYPE i.

    "! W32 exclusive non-cumulative(X): 동일 사용자라도 같은 키를 두 번 잠글 수 없다.
    "! @parameter result | 두 번째 X enqueue가 lock_failure로 거부되면 abap_true
    METHODS non_cumulative_rejected
      RETURNING VALUE(result) TYPE abap_bool.

    "! W29·G5 논리적 잠금: DB에 존재하지 않는 키도 잠글 수 있다(신규 생성 중복 방지).
    "! @parameter result | 미존재 키 잠금 후 보유 잠금 수(1)
    METHODS logical_lock_nonexistent
      RETURNING VALUE(result) TYPE i.

    "! DEQUEUE 후에는 같은 키를 다른 사용자가 다시 잠글 수 있다(즉시 해제).
    "! @parameter result | 해제 후 재획득에 성공하면 abap_true
    METHODS reacquire_after_dequeue
      RETURNING VALUE(result) TYPE abap_bool.

    "! 누적 E 잠금은 dequeue를 누적 횟수만큼 호출해야 완전히 풀린다.
    "! @parameter result | 2회 enqueue 후 1회 dequeue 했을 때 남은 깊이(1)
    METHODS dequeue_decrements
      RETURNING VALUE(result) TYPE i.

    "! W31 COMMIT WORK(_scope=2 의미): commit 시 보유 잠금이 모두 해제된다.
    "! @parameter result | commit 후 보유 잠금 수(0)
    METHODS released_on_commit
      RETURNING VALUE(result) TYPE i.

    "! W31 ROLLBACK WORK는 _scope=2 잠금만 제거한다. _scope=1 잠금은 남는다.
    "! @parameter result | rollback 후 남은 보유 잠금 수(1 — scope_dialog)
    METHODS rollback_removes_scope2_only
      RETURNING VALUE(result) TYPE i.

    "! W31 _scope=3(both): dialog·update 양쪽 처리. ROLLBACK은 _scope=2만 제거하므로
    "! scope_both 잠금은 rollback 후에도 남는다(scope_dialog와 동일하게 잔존).
    "! @parameter result | rollback 후 남은 scope_both 잠금 수(1)
    METHODS rollback_keeps_scope3
      RETURNING VALUE(result) TYPE i.

    "! A4·A7 시스템 장애: enqueue 서버 오류는 lock_failure(소유자 정보 없음) — SHORTDUMP 대응.
    "! foreign_lock과 달리 user_name이 비어 사용자 통보가 불가하다.
    "! @parameter result | system_failure가 lcx_lock_failure로 구분되면 abap_true
    METHODS system_failure_distinct
      RETURNING VALUE(result) TYPE abap_bool.

  PRIVATE SECTION.
    "! 데모용 enqueue 서버 lock table 인스턴스를 새로 만든다.
    METHODS new_lock_table
      RETURNING VALUE(result) TYPE REF TO lcl_lock_table.
ENDCLASS.


CLASS zcl_modulo_txn02_lock IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== TXN02 ENQUEUE/DEQUEUE·COMMIT WORK·_SCOPE (개념) ===` ).
    out->write( |foreign_lock_owner          = { foreign_lock_owner( ) } (충돌 소유자명)| ).
    out->write( |shared_locks_coexist        = { shared_locks_coexist( ) } (S 공존)| ).
    out->write( |exclusive_cumulates         = { exclusive_cumulates( ) } (E 누적)| ).
    out->write( |non_cumulative_rejected     = { non_cumulative_rejected( ) } (X 누적 불가)| ).
    out->write( |logical_lock_nonexistent    = { logical_lock_nonexistent( ) } (논리적 잠금)| ).
    out->write( |reacquire_after_dequeue     = { reacquire_after_dequeue( ) }| ).
    out->write( |dequeue_decrements          = { dequeue_decrements( ) } (누적 1 감소)| ).
    out->write( |released_on_commit          = { released_on_commit( ) } (_scope=2 commit)| ).
    out->write( |rollback_removes_scope2_only= { rollback_removes_scope2_only( ) } (rollback _scope=2)| ).
    out->write( |rollback_keeps_scope3       = { rollback_keeps_scope3( ) } (_scope=3 잔존)| ).
    out->write( |system_failure_distinct     = { system_failure_distinct( ) } (장애 구분)| ).
    out->write( `잠금은 enqueue 서버 메모리에 보관되고 _scope에 따라 COMMIT/ROLLBACK WORK 또는 DEQUEUE로 해제된다.` ).
  ENDMETHOD.

  METHOD foreign_lock_owner.
    DATA(lock_table) = new_lock_table( ).
    TRY.
        lock_table->enqueue( argument = `LH|0400` holder = `USER_A` ).
        " 다른 소유자가 같은 키를 배타 잠금 시도 -> foreign_lock(소유자명 동봉).
        lock_table->enqueue( argument = `LH|0400` holder = `USER_B` ).
      CATCH lcx_foreign_lock INTO DATA(foreign_lock).
        result = foreign_lock->user_name.
      CATCH lcx_lock_failure ##NO_HANDLER.
    ENDTRY.
  ENDMETHOD.

  METHOD shared_locks_coexist.
    DATA(lock_table) = new_lock_table( ).
    TRY.
        lock_table->enqueue( argument = `LH|0400` holder = `USER_A` mode = lif_lock=>shared ).
        " 다른 사용자도 S 잠금 가능 -> 예외 없이 성공.
        lock_table->enqueue( argument = `LH|0400` holder = `USER_B` mode = lif_lock=>shared ).
        result = abap_true.
      CATCH lcx_foreign_lock lcx_lock_failure.
        result = abap_false.
    ENDTRY.
  ENDMETHOD.

  METHOD exclusive_cumulates.
    DATA(lock_table) = new_lock_table( ).
    TRY.
        " 동일 사용자가 E 잠금을 두 번 -> 누적되어 깊이 2.
        lock_table->enqueue( argument = `LH|0400` holder = `USER_A` ).
        lock_table->enqueue( argument = `LH|0400` holder = `USER_A` ).
      CATCH lcx_foreign_lock lcx_lock_failure ##NO_HANDLER.
    ENDTRY.
    result = lock_table->depth( `LH|0400` ).
  ENDMETHOD.

  METHOD non_cumulative_rejected.
    DATA(lock_table) = new_lock_table( ).
    TRY.
        lock_table->enqueue( argument = `LH|0400` holder = `USER_A` mode = lif_lock=>exclusive_non_cumul ).
        " X 모드는 동일 사용자도 재획득 불가 -> lock_failure.
        lock_table->enqueue( argument = `LH|0400` holder = `USER_A` mode = lif_lock=>exclusive_non_cumul ).
        result = abap_false.
      CATCH lcx_lock_failure.
        result = abap_true.
      CATCH lcx_foreign_lock.
        result = abap_false.
    ENDTRY.
  ENDMETHOD.

  METHOD logical_lock_nonexistent.
    DATA(lock_table) = new_lock_table( ).
    TRY.
        " 아직 DB에 없는 키도 잠근다 — SAP 락은 논리적이다(중복 생성 방지 패턴).
        lock_table->enqueue( argument = `NEW|9999` holder = `USER_A` ).
      CATCH lcx_foreign_lock lcx_lock_failure ##NO_HANDLER.
    ENDTRY.
    result = lock_table->held_count( `USER_A` ).
  ENDMETHOD.

  METHOD reacquire_after_dequeue.
    DATA(lock_table) = new_lock_table( ).
    TRY.
        lock_table->enqueue( argument = `LH|0400` holder = `USER_A` ).
        lock_table->dequeue( argument = `LH|0400` holder = `USER_A` ).
        " 해제 후 다른 사용자가 같은 키를 잠글 수 있다.
        lock_table->enqueue( argument = `LH|0400` holder = `USER_B` ).
        result = abap_true.
      CATCH lcx_foreign_lock lcx_lock_failure.
        result = abap_false.
    ENDTRY.
  ENDMETHOD.

  METHOD dequeue_decrements.
    DATA(lock_table) = new_lock_table( ).
    TRY.
        lock_table->enqueue( argument = `LH|0400` holder = `USER_A` ).
        lock_table->enqueue( argument = `LH|0400` holder = `USER_A` ).
      CATCH lcx_foreign_lock lcx_lock_failure ##NO_HANDLER.
    ENDTRY.
    " 누적 깊이 2 -> dequeue 1회 -> 깊이 1(완전 해제 아님).
    lock_table->dequeue( argument = `LH|0400` holder = `USER_A` ).
    result = lock_table->depth( `LH|0400` ).
  ENDMETHOD.

  METHOD released_on_commit.
    DATA(lock_table) = new_lock_table( ).
    TRY.
        lock_table->enqueue( argument = `LH|0400` holder = `USER_A` ).
        lock_table->enqueue( argument = `AA|0017` holder = `USER_A` ).
      CATCH lcx_foreign_lock lcx_lock_failure ##NO_HANDLER.
    ENDTRY.
    " COMMIT WORK: _scope=2 잠금은 update 완료 시 해제된다.
    lock_table->commit_work( `USER_A` ).
    result = lock_table->held_count( `USER_A` ).
  ENDMETHOD.

  METHOD rollback_removes_scope2_only.
    DATA(lock_table) = new_lock_table( ).
    TRY.
        " scope_dialog(1)는 ROLLBACK이 건드리지 않고, scope_update(2)만 제거된다.
        lock_table->enqueue( argument = `LH|0400` holder = `USER_A` scope = lif_lock=>scope_dialog ).
        lock_table->enqueue( argument = `AA|0017` holder = `USER_A` scope = lif_lock=>scope_update ).
      CATCH lcx_foreign_lock lcx_lock_failure ##NO_HANDLER.
    ENDTRY.
    lock_table->rollback_work( `USER_A` ).
    result = lock_table->held_count( `USER_A` ).
  ENDMETHOD.

  METHOD rollback_keeps_scope3.
    DATA(lock_table) = new_lock_table( ).
    TRY.
        " scope_both(3)·scope_update(2) 등록 후 rollback -> scope_update만 제거.
        lock_table->enqueue( argument = `LH|0400` holder = `USER_A` scope = lif_lock=>scope_both ).
        lock_table->enqueue( argument = `AA|0017` holder = `USER_A` scope = lif_lock=>scope_update ).
      CATCH lcx_foreign_lock lcx_lock_failure ##NO_HANDLER.
    ENDTRY.
    lock_table->rollback_work( `USER_A` ).
    result = lock_table->held_count( `USER_A` ).
  ENDMETHOD.

  METHOD system_failure_distinct.
    DATA(lock_table) = new_lock_table( ).
    " 동일 사용자의 X(non-cumulative) 재획득은 system_failure 계열(lock_failure)로 구분된다 —
    " foreign_lock(소유자 있음)과 달리 lock_failure는 소유자 정보가 없다.
    TRY.
        lock_table->enqueue( argument = `LH|0400` holder = `USER_A` mode = lif_lock=>exclusive_non_cumul ).
        lock_table->enqueue( argument = `LH|0400` holder = `USER_A` mode = lif_lock=>exclusive_non_cumul ).
        result = abap_false.
      CATCH lcx_lock_failure.
        result = abap_true.
      CATCH lcx_foreign_lock.
        result = abap_false.
    ENDTRY.
  ENDMETHOD.

  METHOD new_lock_table.
    result = NEW lcl_lock_table( ).
  ENDMETHOD.
ENDCLASS.
