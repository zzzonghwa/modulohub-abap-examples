"! 도메인 예외 — 잘못된 인자/사전조건 위반. cx_static_check 계열:
"! 호출부가 반드시 처리(CATCH)하거나 전파(RAISING)해야 한다(컴파일러 강제).
"! 대비: cx_dynamic_check(선언 없이 전파 가능)·cx_no_check(프로그래밍 오류, 잡지 않음).
"! READ-ONLY 속성 attempted에 위반 시점 입력값을 담아 진단 정보를 예외 객체에 내장한다.
"! 글로벌 메서드 시그니처(RAISING)에서 참조하므로 정의를 CCDEF(locals_def)에 둔다 —
"! CCIMP(locals_imp)의 로컬 클래스는 글로벌 클래스 *정의부*에서 보이지 않는다(활성화 오류).
CLASS lcx_invalid_arg DEFINITION INHERITING FROM cx_static_check CREATE PUBLIC.
  PUBLIC SECTION.
    "! @parameter attempted | 위반을 유발한 입력값(진단용)
    METHODS constructor
      IMPORTING attempted TYPE i OPTIONAL.
    DATA attempted TYPE i READ-ONLY.
ENDCLASS.
