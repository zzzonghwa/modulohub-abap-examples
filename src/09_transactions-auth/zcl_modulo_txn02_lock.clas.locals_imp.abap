"! 인메모리 lock table — SAP 중앙 enqueue 서버의 잠금 테이블 비유.
"! 실 시스템은 lock object(SE11 ENQU, E 접두사) 활성화로 생긴 ENQUEUE_/DEQUEUE_ FM이
"! 중앙 enqueue 서버 메모리에 잠금을 보관한다(DB 아님). 여기선 같은 의미 — 잠금 모드(S/E/X)·
"! 누적·논리적 잠금·_scope별 해제·예외 구분 — 를 로컬 테이블로 자체완결 시연한다.

"! foreign_lock: 다른 사용자가 이미 같은 키를 잠금. user_name에 소유자가 담긴다.
CLASS lcx_foreign_lock DEFINITION INHERITING FROM cx_static_check CREATE PUBLIC.
  PUBLIC SECTION.
    DATA user_name TYPE string READ-ONLY.
    METHODS constructor
      IMPORTING user_name TYPE string.
ENDCLASS.

CLASS lcx_foreign_lock IMPLEMENTATION.
  METHOD constructor.
    super->constructor( ).
    me->user_name = user_name.
  ENDMETHOD.
ENDCLASS.


"! lock_failure: enqueue 서버 장애(system_failure). 소유자 정보가 없다 — SHORTDUMP 대응.
CLASS lcx_lock_failure DEFINITION INHERITING FROM cx_static_check CREATE PUBLIC.
ENDCLASS.

CLASS lcx_lock_failure IMPLEMENTATION.
ENDCLASS.


"! SAP 락 모드·_scope 상수 모음.
INTERFACE lif_lock.
  CONSTANTS:
    "! shared — 여러 사용자가 동시에 S 잠금 가능.
    shared              TYPE c LENGTH 1 VALUE 'S',
    "! exclusive — 다른 사용자 차단, 동일 사용자는 누적(cumulative) 가능.
    exclusive           TYPE c LENGTH 1 VALUE 'E',
    "! exclusive non-cumulative — 동일 사용자라도 두 번 잠글 수 없다.
    exclusive_non_cumul TYPE c LENGTH 1 VALUE 'X'.
  CONSTANTS:
    "! _scope=1 — COMMIT WORK 시 dialog 측에서 즉시 해제. update task로 전달 안 됨.
    scope_dialog        TYPE i VALUE 1,
    "! _scope=2 — update work process 완료 시 해제. ROLLBACK WORK도 이 락만 제거.
    scope_update        TYPE i VALUE 2,
    "! _scope=3 — dialog·update 양쪽 모두에서 처리.
    scope_both          TYPE i VALUE 3.
ENDINTERFACE.


"! 중앙 enqueue 잠금 테이블 모델.
CLASS lcl_lock_table DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    "! 잠금 획득. 성공 시 잠금 카운트 증가, 충돌 시 예외(실 FM의 EXCEPTIONS 대응).
    "! @parameter argument | 잠금 키(예: `LH|0400`)
    "! @parameter holder   | 잠금 소유 사용자
    "! @parameter mode     | 잠금 모드(lif_lock=>shared/exclusive/exclusive_non_cumul)
    "! @parameter scope    | _scope 값(기본 scope_update=2)
    "! @raising   lcx_foreign_lock | 다른 사용자가 충돌 모드로 이미 보유
    "! @raising   lcx_lock_failure | exclusive_non_cumul을 동일 사용자가 재획득
    METHODS enqueue
      IMPORTING argument TYPE string
                holder   TYPE string
                mode     TYPE c DEFAULT lif_lock=>exclusive
                scope    TYPE i DEFAULT lif_lock=>scope_update
      RAISING   lcx_foreign_lock
                lcx_lock_failure.
    "! 잠금 해제(DEQUEUE) — 어느 _scope에서도 즉시. 누적 카운트를 1 감소시킨다.
    METHODS dequeue
      IMPORTING argument TYPE string
                holder   TYPE string.
    "! COMMIT WORK: _scope에 따라 락을 해제한다(scope_dialog·scope_both 즉시, scope_update 유지 후 해제).
    METHODS commit_work
      IMPORTING holder TYPE string.
    "! ROLLBACK WORK: _scope=2(scope_update) 락만 제거한다.
    METHODS rollback_work
      IMPORTING holder TYPE string.
    "! 소유자가 현재 보유한 잠금 라인 수.
    METHODS held_count
      IMPORTING holder        TYPE string
      RETURNING VALUE(result) TYPE i.
    "! 특정 키의 누적 잠금 횟수(exclusive 누적 시연용).
    METHODS depth
      IMPORTING argument      TYPE string
      RETURNING VALUE(result) TYPE i.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF lock,
        argument TYPE string,
        owner    TYPE string,
        mode     TYPE c LENGTH 1,
        scope    TYPE i,
        count    TYPE i,
      END OF lock.
    DATA locks TYPE SORTED TABLE OF lock WITH UNIQUE KEY argument owner.
    "! 기존 잠금이 새 요청과 충돌하면 abap_true(서로 다른 소유자, 둘 중 하나가 비-shared).
    METHODS conflicts
      IMPORTING existing      TYPE lock
                holder        TYPE string
                mode          TYPE c
      RETURNING VALUE(result) TYPE abap_bool.
ENDCLASS.

CLASS lcl_lock_table IMPLEMENTATION.
  METHOD enqueue.
    " 같은 키에 다른 소유자의 충돌 잠금이 있으면 foreign_lock(소유자명 동봉).
    LOOP AT locks REFERENCE INTO DATA(other) WHERE argument = argument.
      IF conflicts( existing = other->* holder = holder mode = mode ) = abap_true.
        RAISE EXCEPTION NEW lcx_foreign_lock( user_name = other->owner ).
      ENDIF.
    ENDLOOP.
    " 동일 소유자의 기존 잠금: exclusive는 누적, exclusive_non_cumul은 재획득 불가.
    READ TABLE locks REFERENCE INTO DATA(own) WITH KEY argument = argument owner = holder.
    IF sy-subrc = 0.
      IF own->mode = lif_lock=>exclusive_non_cumul.
        RAISE EXCEPTION NEW lcx_lock_failure( ).
      ENDIF.
      own->count = own->count + 1.
      RETURN.
    ENDIF.
    INSERT VALUE #( argument = argument owner = holder mode = mode scope = scope count = 1 ) INTO TABLE locks.
  ENDMETHOD.

  METHOD conflicts.
    " 같은 소유자끼리는 충돌하지 않는다. 둘 다 shared면 공존 가능.
    result = xsdbool( existing-owner <> holder
                      AND ( existing-mode <> lif_lock=>shared OR mode <> lif_lock=>shared ) ).
  ENDMETHOD.

  METHOD dequeue.
    READ TABLE locks REFERENCE INTO DATA(own) WITH KEY argument = argument owner = holder.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.
    own->count = own->count - 1.
    IF own->count <= 0.
      DELETE locks WHERE argument = argument AND owner = holder.
    ENDIF.
  ENDMETHOD.

  METHOD commit_work.
    " scope_dialog(1)·scope_both(3): dialog 측에서 즉시 해제. scope_update(2)도 update 완료로 해제.
    DELETE locks WHERE owner = holder.
  ENDMETHOD.

  METHOD rollback_work.
    " ROLLBACK WORK는 _scope=2 락만 제거한다. scope_dialog/scope_both 락은 남는다.
    DELETE locks WHERE owner = holder AND scope = lif_lock=>scope_update.
  ENDMETHOD.

  METHOD held_count.
    result = REDUCE i( INIT total = 0
                       FOR <held> IN locks WHERE ( owner = holder )
                       NEXT total = total + 1 ).
  ENDMETHOD.

  METHOD depth.
    result = REDUCE i( INIT total = 0
                       FOR <line> IN locks WHERE ( argument = argument )
                       NEXT total = total + <line>-count ).
  ENDMETHOD.
ENDCLASS.
