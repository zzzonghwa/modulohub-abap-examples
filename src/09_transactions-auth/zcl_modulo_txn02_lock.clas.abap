CLASS zcl_modulo_txn02_lock DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
    "!
    "! SAP 잠금(ENQUEUE/DEQUEUE)·COMMIT WORK — 개념.
    "! 실 시스템은 lock object(SE11, ENQU, EZ 접두사)를 활성화하면 ENQUEUE_<name>/DEQUEUE_<name>
    "! 함수모듈이 자동 생성된다. 실제 호출 형태:
    "!   CALL FUNCTION 'ENQUEUE_EZMODULO_FLIGHT'
    "!     EXPORTING  mode_zmodulo_flight = 'E'   " 잠금 모드(E=배타)
    "!                carrid = 'LH' connid = '0400'
    "!                _scope = '2'                " 2=update task에 위임(기본)
    "!     EXCEPTIONS foreign_lock = 1 system_failure = 2 OTHERS = 3.
    "!   IF sy-subrc <> 0. " 충돌(sy-msgv1=소유자) 처리. ENDIF.
    "!   " ... SELECT/변경/update FM ...
    "!   COMMIT WORK.                            " _scope=2면 commit에서 자동 해제
    "!   CALL FUNCTION 'DEQUEUE_EZMODULO_FLIGHT' EXPORTING carrid = 'LH' connid = '0400'.
    "! 잠금은 중앙 enqueue 서버 메모리에 보관(DB 아님). 자체완결 위해 그 의미를
    "! 인메모리 lock table(locals_imp)로 시연한다 — 실 FM은 lock object 활성화에 의존.
    INTERFACES if_oo_adt_classrun.

    "! 한 키를 잠근 뒤 다른 소유자가 같은 키를 잠그면 충돌(foreign_lock)이 난다.
    "! @parameter result | 두 번째 잠금이 거부되면 abap_true
    METHODS foreign_lock_raised
      RETURNING VALUE(result) TYPE abap_bool.

    "! DEQUEUE 후에는 같은 키를 다시 잠글 수 있다.
    "! @parameter result | 해제 후 재획득에 성공하면 abap_true
    METHODS reacquire_after_dequeue
      RETURNING VALUE(result) TYPE abap_bool.

    "! COMMIT WORK(_scope=2 의미): commit 시 보유 잠금이 모두 해제된다.
    "! @parameter result | commit 후 보유 잠금 수(0)
    METHODS released_on_commit
      RETURNING VALUE(result) TYPE i.
ENDCLASS.


CLASS zcl_modulo_txn02_lock IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== TXN02 ENQUEUE/DEQUEUE·COMMIT WORK (개념) ===` ).
    out->write( |foreign_lock_raised     = { foreign_lock_raised( ) }| ).
    out->write( |reacquire_after_dequeue = { reacquire_after_dequeue( ) }| ).
    out->write( |released_on_commit      = { released_on_commit( ) }| ).
    out->write( `잠금은 enqueue 서버 메모리에 보관되고 COMMIT/ROLLBACK WORK 또는 DEQUEUE로 해제된다.` ).
  ENDMETHOD.

  METHOD foreign_lock_raised.
    DATA(lock_table) = NEW lcl_lock_table( ).
    lock_table->enqueue( arg = `LH|0400` holder = `USER_A` ).
    " 다른 소유자가 같은 키를 배타 잠금 시도 -> 거부(foreign_lock).
    result = xsdbool( lock_table->try_enqueue( arg = `LH|0400` holder = `USER_B` ) = abap_false ).
  ENDMETHOD.

  METHOD reacquire_after_dequeue.
    DATA(lock_table) = NEW lcl_lock_table( ).
    lock_table->enqueue( arg = `LH|0400` holder = `USER_A` ).
    lock_table->dequeue( arg = `LH|0400` holder = `USER_A` ).
    result = lock_table->try_enqueue( arg = `LH|0400` holder = `USER_B` ).
  ENDMETHOD.

  METHOD released_on_commit.
    DATA(lock_table) = NEW lcl_lock_table( ).
    lock_table->enqueue( arg = `LH|0400` holder = `USER_A` ).
    lock_table->enqueue( arg = `AA|0017` holder = `USER_A` ).
    " COMMIT WORK 의미: _scope=2 잠금은 commit 시 해제된다.
    lock_table->commit_work( holder = `USER_A` ).
    result = lock_table->held_count( holder = `USER_A` ).
  ENDMETHOD.
ENDCLASS.
