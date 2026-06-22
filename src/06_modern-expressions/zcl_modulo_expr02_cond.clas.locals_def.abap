"! COND/SWITCH의 ELSE THROW 데모용 도메인 예외(체크 예외).
"! 글로벌 메서드 시그니처(RAISING)에서 참조하므로 정의를 CCDEF(locals_def)에 둔다 —
"! CCIMP(locals_imp)의 로컬 클래스는 글로벌 클래스 *정의부*에서 보이지 않는다(활성화 오류).
CLASS lcx_bad_input DEFINITION INHERITING FROM cx_static_check CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS constructor
      IMPORTING reason TYPE string OPTIONAL.
    METHODS get_reason
      RETURNING VALUE(result) TYPE string.

  PRIVATE SECTION.
    DATA reason TYPE string.
ENDCLASS.
