"! COND/SWITCH의 ELSE THROW 데모용 도메인 예외(체크 예외).
CLASS lcx_bad_input DEFINITION INHERITING FROM cx_static_check CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS constructor
      IMPORTING reason TYPE string OPTIONAL.
    METHODS get_reason
      RETURNING VALUE(result) TYPE string.

  PRIVATE SECTION.
    DATA reason TYPE string.
ENDCLASS.

CLASS lcx_bad_input IMPLEMENTATION.
  METHOD constructor.
    super->constructor( ).
    me->reason = reason.
  ENDMETHOD.

  METHOD get_reason.
    result = reason.
  ENDMETHOD.
ENDCLASS.
