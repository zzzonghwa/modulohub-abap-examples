"! 테스트 대상(CUT) — 정수 스택(LIFO). LTCL_STACK이 이 클래스를 검증한다.
CLASS lcl_stack DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES item_list TYPE STANDARD TABLE OF i WITH EMPTY KEY.

    "! 값을 맨 위에 쌓는다.
    METHODS push
      IMPORTING value TYPE i.

    "! 맨 위 값을 꺼내 제거한다. 빈 스택이면 cx_sy_itab_line_not_found.
    METHODS pop
      RETURNING VALUE(result) TYPE i.

    METHODS size
      RETURNING VALUE(result) TYPE i.

    METHODS is_empty
      RETURNING VALUE(result) TYPE abap_bool.
  PRIVATE SECTION.
    DATA items TYPE item_list.
ENDCLASS.


CLASS lcl_stack IMPLEMENTATION.
  METHOD push.
    APPEND value TO items.
  ENDMETHOD.

  METHOD pop.
    " 빈 스택은 꺼낼 값이 없다 — 명시적으로 예외를 던진다(테이블 식 암묵 예외 대신).
    IF items IS INITIAL.
      RAISE EXCEPTION TYPE cx_sy_itab_line_not_found.
    ENDIF.
    DATA(last) = lines( items ).
    result = items[ last ].
    DELETE items INDEX last.
  ENDMETHOD.

  METHOD size.
    result = lines( items ).
  ENDMETHOD.

  METHOD is_empty.
    result = xsdbool( items IS INITIAL ).
  ENDMETHOD.
ENDCLASS.
