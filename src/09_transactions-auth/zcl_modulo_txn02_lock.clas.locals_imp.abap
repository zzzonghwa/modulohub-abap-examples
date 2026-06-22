"! 인메모리 lock table — SAP enqueue 서버의 잠금 테이블 비유.
"! 실 시스템은 lock object(SE11 ENQU) 활성화로 생긴 ENQUEUE_/DEQUEUE_ FM이 중앙 enqueue
"! 서버 메모리에 잠금을 보관한다. 여기선 같은 의미(획득·충돌·해제)를 로컬 테이블로 시연한다.
CLASS lcl_lock_table DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    "! 잠금 획득(이미 잠겨 있으면 조용히 무시 — 실 FM은 EXCEPTIONS foreign_lock).
    METHODS enqueue
      IMPORTING arg    TYPE string
                holder TYPE string.
    "! 잠금 시도. 성공 abap_true, 충돌(foreign_lock) abap_false.
    METHODS try_enqueue
      IMPORTING arg           TYPE string
                holder        TYPE string
      RETURNING VALUE(result) TYPE abap_bool.
    "! 잠금 해제(DEQUEUE).
    METHODS dequeue
      IMPORTING arg    TYPE string
                holder TYPE string.
    "! COMMIT WORK 의미(_scope=2): 해당 소유자의 보유 잠금을 모두 해제한다.
    METHODS commit_work
      IMPORTING holder TYPE string.
    "! 소유자가 현재 보유한 잠금 수.
    METHODS held_count
      IMPORTING holder        TYPE string
      RETURNING VALUE(result) TYPE i.

  PRIVATE SECTION.
    TYPES:
      BEGIN OF lock,
        argument TYPE string,
        owner    TYPE string,
      END OF lock.
    DATA locks TYPE SORTED TABLE OF lock WITH UNIQUE KEY argument.
ENDCLASS.

CLASS lcl_lock_table IMPLEMENTATION.
  METHOD enqueue.
    " 이미 잠겨 있지 않으면 잠근다(충돌은 조용히 무시 — 실 FM은 EXCEPTIONS foreign_lock).
    IF NOT line_exists( locks[ argument = arg ] ).
      INSERT VALUE #( argument = arg owner = holder ) INTO TABLE locks.
    ENDIF.
  ENDMETHOD.

  METHOD try_enqueue.
    READ TABLE locks WITH KEY argument = arg TRANSPORTING NO FIELDS.
    IF sy-subrc = 0.
      result = abap_false.   " foreign_lock: 이미 잠겨 있음
      RETURN.
    ENDIF.
    INSERT VALUE #( argument = arg owner = holder ) INTO TABLE locks.
    result = abap_true.
  ENDMETHOD.

  METHOD dequeue.
    DELETE locks WHERE argument = arg AND owner = holder.
  ENDMETHOD.

  METHOD commit_work.
    DELETE locks WHERE owner = holder.
  ENDMETHOD.

  METHOD held_count.
    LOOP AT locks TRANSPORTING NO FIELDS WHERE owner = holder.
      result = result + 1.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
