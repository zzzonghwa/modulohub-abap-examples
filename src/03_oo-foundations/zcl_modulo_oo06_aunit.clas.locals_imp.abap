"! 빈 스택에서 꺼낼 때 던지는 도메인 예외. CX_DYNAMIC_CHECK 상속 —
"! 호출자에 처리 강제가 없고(동적 검사) TRY/CATCH로 안정적으로 잡힌다.
"! (표준 no-check 예외 cx_sy_itab_line_not_found는 CATCH에서 누락될 수 있어 도메인 예외 사용)
CLASS lcx_empty_stack DEFINITION INHERITING FROM cx_dynamic_check.
ENDCLASS.

CLASS lcx_empty_stack IMPLEMENTATION.
ENDCLASS.


"! 테스트 대상(CUT) — 정수 스택(LIFO). LTCL_STACK이 이 클래스를 검증한다.
CLASS lcl_stack DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES item_list TYPE STANDARD TABLE OF i WITH EMPTY KEY.

    "! 값을 맨 위에 쌓는다.
    METHODS push
      IMPORTING value TYPE i.

    "! 맨 위 값을 꺼내 제거한다. 빈 스택이면 lcx_empty_stack.
    METHODS pop
      RETURNING VALUE(result) TYPE i
      RAISING   lcx_empty_stack.

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
    " 빈 스택은 꺼낼 값이 없다 — 도메인 예외를 명시적으로 던진다.
    IF items IS INITIAL.
      RAISE EXCEPTION TYPE lcx_empty_stack.
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
