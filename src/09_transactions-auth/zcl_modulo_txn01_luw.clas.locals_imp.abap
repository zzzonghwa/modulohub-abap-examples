"! 작업 단위(Unit of Work) — SAP LUW의 인메모리 비유.
"! 변경을 곧장 반영하지 않고 보류(pending)에 모았다가 commit에서 한 번에 반영,
"! rollback이면 폐기한다. 실 DB LUW의 "COMMIT WORK까지 보류, ROLLBACK WORK로 취소"와 동형.
CLASS lcl_unit_of_work DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    "! 변경을 보류 목록에 등록한다(아직 확정 아님).
    METHODS register IMPORTING value TYPE i.
    "! COMMIT WORK 유사 — 보류 변경을 확정 저장소에 반영하고 보류를 비운다.
    METHODS commit.
    "! ROLLBACK WORK 유사 — 보류 변경을 폐기한다(확정 저장소는 그대로).
    METHODS rollback.
    "! 확정된(commit된) 변경 수.
    METHODS committed_count RETURNING VALUE(result) TYPE i.
  PRIVATE SECTION.
    DATA pending TYPE STANDARD TABLE OF i WITH EMPTY KEY.
    DATA store   TYPE STANDARD TABLE OF i WITH EMPTY KEY.
ENDCLASS.

CLASS lcl_unit_of_work IMPLEMENTATION.
  METHOD register.
    APPEND value TO pending.
  ENDMETHOD.

  METHOD commit.
    APPEND LINES OF pending TO store.
    CLEAR pending.
  ENDMETHOD.

  METHOD rollback.
    CLEAR pending.
  ENDMETHOD.

  METHOD committed_count.
    result = lines( store ).
  ENDMETHOD.
ENDCLASS.
