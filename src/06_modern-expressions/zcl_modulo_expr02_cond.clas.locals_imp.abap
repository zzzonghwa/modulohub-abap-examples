CLASS lcx_bad_input IMPLEMENTATION.
  METHOD constructor.
    super->constructor( ).
    me->reason = reason.
  ENDMETHOD.

  METHOD get_reason.
    result = reason.
  ENDMETHOD.
ENDCLASS.
