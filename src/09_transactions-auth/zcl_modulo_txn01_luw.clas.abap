CLASS zcl_modulo_txn01_luw DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
    "!
    "! SAP LUW(논리적 작업 단위)·번들링 — 개념.
    "! - 원칙: DB 변경은 COMMIT WORK까지 보류되며 한 LUW로 묶여 전부-또는-전무로 확정된다.
    "!   ROLLBACK WORK는 보류 변경을 취소한다.
    "! - 번들링: 변경을 update FM·PERFORM ON COMMIT로 모았다가 한 번에 반영한다(왕복·정합성).
    "! 이 예제는 그 의미를 Unit of Work(locals_imp)로 인메모리 시연한다 —
    "! 실제 DB 변경문·update FM·ENQUEUE/DEQUEUE는 09.2(DB 필요)에서 다룬다.
    INTERFACES if_oo_adt_classrun.

    "! 등록 후 commit -> 보류 변경이 모두 확정된다.
    "! @parameter result | 확정된 변경 수(3)
    METHODS commit_count
      RETURNING VALUE(result) TYPE i.

    "! 등록 후 rollback -> 아무것도 확정되지 않는다.
    "! @parameter result | 확정된 변경 수(0)
    METHODS rollback_count
      RETURNING VALUE(result) TYPE i.

    "! 번들 경계: commit된 변경은 남고, 이후 rollback은 그 뒤 보류분만 버린다.
    "! @parameter result | 확정된 변경 수(2)
    METHODS bundle_boundary
      RETURNING VALUE(result) TYPE i.
ENDCLASS.


CLASS zcl_modulo_txn01_luw IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== TXN01 SAP LUW·번들링 (개념) ===` ).
    out->write( |commit_count    = { commit_count( ) }| ).
    out->write( |rollback_count  = { rollback_count( ) }| ).
    out->write( |bundle_boundary = { bundle_boundary( ) }| ).
    out->write( `보류 변경은 commit에서 한 LUW로 확정, rollback에서 폐기된다.` ).
  ENDMETHOD.

  METHOD commit_count.
    DATA(uow) = NEW lcl_unit_of_work( ).
    uow->register( 1 ).
    uow->register( 2 ).
    uow->register( 3 ).
    uow->commit( ).
    result = uow->committed_count( ).
  ENDMETHOD.

  METHOD rollback_count.
    DATA(uow) = NEW lcl_unit_of_work( ).
    uow->register( 1 ).
    uow->register( 2 ).
    uow->register( 3 ).
    uow->rollback( ).
    result = uow->committed_count( ).
  ENDMETHOD.

  METHOD bundle_boundary.
    DATA(uow) = NEW lcl_unit_of_work( ).
    uow->register( 1 ).
    uow->register( 2 ).
    uow->commit( ).
    " 다음 LUW의 보류 변경을 롤백 -> 앞서 확정된 2건은 영향 없음.
    uow->register( 3 ).
    uow->rollback( ).
    result = uow->committed_count( ).
  ENDMETHOD.
ENDCLASS.
