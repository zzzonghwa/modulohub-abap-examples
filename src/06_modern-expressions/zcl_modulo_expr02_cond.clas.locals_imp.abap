"! COND/SWITCH의 ELSE THROW 데모용 도메인 예외.
"! cx_dynamic_check 계열 — 선언 없이 전파되므로 글로벌 public 메서드 시그니처에 RAISING이 불필요하다.
"! (정적 검사 cx_static_check로 "컴파일러 강제 처리"를 보이려면 정의를 CCDEF(locals_def)에 둬야 한다 —
"!  CCIMP의 로컬 클래스는 글로벌 클래스 정의부에서 안 보이기 때문. 여기선 자체완결을 위해 동적 검사.)
CLASS lcx_bad_input DEFINITION INHERITING FROM cx_dynamic_check CREATE PUBLIC.
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
