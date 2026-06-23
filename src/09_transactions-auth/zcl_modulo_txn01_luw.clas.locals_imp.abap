"! 작업 단위(Unit of Work) — SAP LUW·번들링의 인메모리 비유.
"! 변경을 곧장 반영하지 않고 보류(pending)에 모았다가 COMMIT WORK에서 한 번에 실행,
"! ROLLBACK WORK이면 폐기한다. 실 DB LUW의 "COMMIT WORK까지 보류, ROLLBACK WORK로 취소"와 동형.
"!
"! 번들링 기법의 핵심 의미를 좁게 본뜬다:
"! - update function module: 우선순위(VB1=high, VB2=low)로 등록, COMMIT WORK 시 실행.
"!   VB1은 등록 순서대로 단일 묶음에서 먼저, VB2는 그 뒤에 실행된다.
"! - PERFORM ON COMMIT subroutine: update FM보다 먼저, LEVEL 오름차순(동일 LEVEL=등록 순서).
"! - COMMIT WORK 없이 종료(=discard): 등록 절차는 실행되지 않는다.
CLASS lcl_unit_of_work DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    "! update FM 우선순위. high=VB1(중요 변경), low=VB2(부수 작업: 로그·통계).
    TYPES priority TYPE c LENGTH 4.
    CONSTANTS high TYPE priority VALUE 'HIGH'.
    CONSTANTS low  TYPE priority VALUE 'LOW'.

    "! update function module을 등록한다(CALL FUNCTION ... IN UPDATE TASK 유사).
    "! 아직 실행 아님 — COMMIT WORK까지 보류 상태로만 존재한다(빈 DB LUW).
    "! @parameter label    | 실행 시 기록될 식별자
    "! @parameter priority | high(VB1) 또는 low(VB2). 미지정 시 high
    METHODS register_update_fm
      IMPORTING label    TYPE string
                priority TYPE priority DEFAULT lcl_unit_of_work=>high.

    "! PERFORM ... ON COMMIT 유사 — COMMIT WORK 시 update FM보다 먼저 실행될 절차를 등록.
    "! @parameter label | 실행 시 기록될 식별자
    "! @parameter level | 실행 순서 키(오름차순). 미지정 시 0. 동일 level은 등록 순서
    METHODS register_on_commit
      IMPORTING label TYPE string
                level TYPE i DEFAULT 0.

    "! COMMIT WORK — 번들을 실행한다. 순서: ON COMMIT 절차(LEVEL 오름차순) ->
    "! update FM(VB1 등록순 -> VB2 등록순). 실행 후 보류는 비고 SAP LUW가 닫힌다.
    "! @parameter wait   | abap_true면 AND WAIT(동기). 결과를 sy-subrc류로 확인
    "! @parameter result | AND WAIT 없으면 항상 0. AND WAIT면 update 성공 0·실패 4
    METHODS commit_work
      IMPORTING wait          TYPE abap_bool DEFAULT abap_false
      RETURNING VALUE(result) TYPE i.

    "! ROLLBACK WORK — 현재 SAP LUW의 보류 등록(update FM·ON COMMIT)을 모두 취소한다.
    "! 이미 commit된 실행 기록(executed)은 영향받지 않는다.
    METHODS rollback_work.

    "! COMMIT WORK 없이 프로그램이 끝나는 경로 — 보류 등록은 실행되지 않고 버려진다.
    METHODS discard_without_commit.

    "! 다음 commit이 실패하도록 표시(AND WAIT에서 sy-subrc=4 시연용).
    METHODS fail_next_update.

    "! 지금까지 실행된(번들 실행으로 반영된) 절차 라벨을 등록·실행 순서대로 돌려준다.
    METHODS executed_log
      RETURNING VALUE(result) TYPE string_table.

    "! 실행된 절차 수(= 확정 반영된 변경 수).
    METHODS executed_count
      RETURNING VALUE(result) TYPE i.
  PRIVATE SECTION.
    TYPES:
      BEGIN OF registration,
        label    TYPE string,
        priority TYPE priority,
        level    TYPE i,
        sequence TYPE i,
      END OF registration.
    TYPES registrations TYPE STANDARD TABLE OF registration WITH EMPTY KEY.

    DATA update_fms TYPE registrations.
    DATA on_commits TYPE registrations.
    DATA executed   TYPE string_table.
    DATA next_seq   TYPE i.
    DATA next_fails TYPE abap_bool.

    "! 보류 등록을 비운다(commit/rollback/discard 공통의 SAP LUW 닫기).
    METHODS clear_pending.
ENDCLASS.

CLASS lcl_unit_of_work IMPLEMENTATION.
  METHOD register_update_fm.
    next_seq += 1.
    APPEND VALUE #( label = label priority = priority sequence = next_seq ) TO update_fms.
  ENDMETHOD.

  METHOD register_on_commit.
    next_seq += 1.
    APPEND VALUE #( label = label level = level sequence = next_seq ) TO on_commits.
  ENDMETHOD.

  METHOD commit_work.
    " 1) PERFORM ON COMMIT 절차: LEVEL 오름차순, 동일 LEVEL은 등록 순서(sequence).
    DATA(ordered_on_commit) = on_commits.
    SORT ordered_on_commit BY level ASCENDING sequence ASCENDING.
    LOOP AT ordered_on_commit INTO DATA(subroutine).
      APPEND subroutine-label TO executed.
    ENDLOOP.

    " 2) update FM: VB1(high) 먼저 등록 순서대로, 그 다음 VB2(low) 등록 순서대로.
    "    'HIGH' < 'LOW'(알파벳)이므로 priority ASCENDING이 VB1을 앞에 둔다.
    DATA(ordered_update_fms) = update_fms.
    SORT ordered_update_fms BY priority ASCENDING sequence ASCENDING.
    LOOP AT ordered_update_fms INTO DATA(update_fm).
      APPEND update_fm-label TO executed.
    ENDLOOP.

    " AND WAIT(동기)면 update 결과를 sy-subrc류로 반환(실패=4), 아니면 항상 0.
    result = COND #( WHEN wait = abap_true AND next_fails = abap_true THEN 4 ELSE 0 ).
    next_fails = abap_false.
    clear_pending( ).
  ENDMETHOD.

  METHOD rollback_work.
    " 보류 등록만 취소 — 이미 실행된 기록(executed)은 그대로 남는다.
    clear_pending( ).
  ENDMETHOD.

  METHOD discard_without_commit.
    " COMMIT WORK 없는 종료 — 등록 절차는 실행되지 않는다.
    clear_pending( ).
  ENDMETHOD.

  METHOD fail_next_update.
    next_fails = abap_true.
  ENDMETHOD.

  METHOD executed_log.
    result = executed.
  ENDMETHOD.

  METHOD executed_count.
    result = lines( executed ).
  ENDMETHOD.

  METHOD clear_pending.
    CLEAR update_fms.
    CLEAR on_commits.
    next_fails = abap_false.
  ENDMETHOD.
ENDCLASS.
