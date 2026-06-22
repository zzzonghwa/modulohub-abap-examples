"! 도메인 예외 — 잘못된 인자. cx_dynamic_check 계열: 선언 없이 전파(글로벌 public RAISING 불필요).
"! 정적 검사(cx_static_check, 컴파일러 강제)로 보이려면 정의를 CCDEF(locals_def)에 둬야 하나,
"! CCIMP 로컬 클래스는 글로벌 정의부에서 안 보여 자체완결을 위해 동적 검사로 둔다.
"! 대비: cx_no_check(프로그래밍 오류, 잡지 않음). READ-ONLY attempted에 위반 입력값을 담는다.
CLASS lcx_invalid_arg DEFINITION INHERITING FROM cx_dynamic_check CREATE PUBLIC.
  PUBLIC SECTION.
    "! @parameter attempted | 위반을 유발한 입력값(진단용)
    METHODS constructor
      IMPORTING attempted TYPE i OPTIONAL.
    DATA attempted TYPE i READ-ONLY.
ENDCLASS.

CLASS lcx_invalid_arg IMPLEMENTATION.
  METHOD constructor.
    super->constructor( ).
    me->attempted = attempted.
  ENDMETHOD.
ENDCLASS.


"! 잔액 초과 출금 — invalid_arg와 구분되는 별도 도메인 예외.
"! 예외 타입 자체로 "어떤 계약을 위반했는가"를 호출부가 즉시 식별한다.
"! READ-ONLY 속성 shortfall에 부족액을 담는다.
CLASS lcx_overdrawn DEFINITION INHERITING FROM lcx_invalid_arg CREATE PUBLIC.
  PUBLIC SECTION.
    "! @parameter shortfall | 잔액 대비 부족액(진단용)
    METHODS constructor
      IMPORTING shortfall TYPE i OPTIONAL.
    DATA shortfall TYPE i READ-ONLY.
ENDCLASS.

CLASS lcx_overdrawn IMPLEMENTATION.
  METHOD constructor.
    super->constructor( ).
    me->shortfall = shortfall.
  ENDMETHOD.
ENDCLASS.


"! DBC 사전조건 위반 — "절대 발생해선 안 되는" 호출자 버그.
"! ATF는 DBC 위반에 cx_no_check(모든 시그니처에 묵시 선언, 선언 강제 없음)를 권장하지만,
"! 전제조건으로 차단 가능한 위반은 cx_dynamic_check도 적합하다(주장 19: "사실상 ASSERT에 가깝다").
"! 런타임 미처리 시 short dump로 "발생 자체가 버그"임을 알린다.
CLASS lcx_precondition DEFINITION INHERITING FROM cx_dynamic_check CREATE PUBLIC.
  PUBLIC SECTION.
    "! @parameter condition_text | 위반한 사전조건 설명 텍스트
    METHODS constructor
      IMPORTING condition_text TYPE string OPTIONAL.
    DATA condition_text TYPE string READ-ONLY.
ENDCLASS.

CLASS lcx_precondition IMPLEMENTATION.
  METHOD constructor.
    super->constructor( ).
    me->condition_text = condition_text.
  ENDMETHOD.
ENDCLASS.


"! 계산기 — 사전조건(Design by Contract)을 검사하고 위반 시 도메인 예외를 던진다.
"! 계약: 호출자는 사전조건을 지킬 책임이 있고, 메서드는 지켜지면 올바른 결과를 보장한다.
CLASS lcl_calculator DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    "! 사전조건: divisor <> 0.
    METHODS divide
      IMPORTING dividend      TYPE i
                divisor       TYPE i
      RETURNING VALUE(result) TYPE i
      RAISING   lcx_invalid_arg.
    "! 사전조건: 0 <= amount. amount > balance면 lcx_overdrawn(하위 타입).
    METHODS withdraw
      IMPORTING balance       TYPE i
                amount        TYPE i
      RETURNING VALUE(result) TYPE i
      RAISING   lcx_invalid_arg.
ENDCLASS.

CLASS lcl_calculator IMPLEMENTATION.
  METHOD divide.
    IF divisor = 0.
      " RAISE EXCEPTION NEW: EXPORTING 생략(7.52+). 위반 입력값을 속성에 실어 보낸다.
      RAISE EXCEPTION NEW lcx_invalid_arg( attempted = divisor ).
    ENDIF.
    " 정수 나눗셈은 DIV(절단). 연산자 / 는 정수 대상에 반올림하므로 의도와 다를 수 있다.
    result = dividend DIV divisor.
  ENDMETHOD.

  METHOD withdraw.
    IF amount < 0.
      RAISE EXCEPTION NEW lcx_invalid_arg( attempted = amount ).
    ENDIF.
    IF amount > balance.
      " 초과 출금은 구체 하위 예외로 구분 — 호출부 multi-CATCH가 먼저 잡는다.
      RAISE EXCEPTION NEW lcx_overdrawn( shortfall = amount - balance ).
    ENDIF.
    result = balance - amount.
  ENDMETHOD.
ENDCLASS.


"! DBC 유틸리티 — REQUIRE 패턴(ATF Listing 4.13). 조건이 거짓이면 사전조건 위반
"! 예외를 던진다. xsdbool()로 인라인 bool 변환을 결합한다.
CLASS lcl_dbc DEFINITION CREATE PRIVATE.
  PUBLIC SECTION.
    "! @parameter that             | 위반 시 남길 조건 설명
    "! @parameter which_is_true_if | 참이어야 하는 조건
    CLASS-METHODS require
      IMPORTING that             TYPE string
                which_is_true_if TYPE abap_bool.
ENDCLASS.

CLASS lcl_dbc IMPLEMENTATION.
  METHOD require.
    IF which_is_true_if = abap_false.
      RAISE EXCEPTION NEW lcx_precondition( condition_text = that ).
    ENDIF.
  ENDMETHOD.
ENDCLASS.


"! RESUMABLE 예외 — 공급자가 RAISE RESUMABLE로 던지고, 소비자가 RESUME하면 발생 지점 다음부터 이어간다.
"! 체크 예외(cx_static_check)로 두면 RAISING RESUMABLE 선언이 강제돼 계약이 명확하다.
CLASS lcx_bad_row DEFINITION INHERITING FROM cx_static_check CREATE PUBLIC.
ENDCLASS.

CLASS lcx_bad_row IMPLEMENTATION.
ENDCLASS.


"! RESUMABLE 공급자 — 행을 처리하다 불량 행(음수)에서 재개가능 예외를 던진다.
"! 로컬 클래스(CCIMP) 메서드라 RAISING RESUMABLE(lcx_bad_row)로 로컬 예외를 시그니처에 둘 수 있다
"! (글로벌 클래스 public 시그니처는 로컬 타입 불가 — 그래서 공급자를 로컬 클래스로 둔다).
CLASS lcl_importer DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    TYPES int_rows TYPE STANDARD TABLE OF i WITH EMPTY KEY.
    "! [1,-2,3]을 처리한다. 음수(불량 행)에서 RESUMABLE 예외 발생.
    "! @parameter processed | 처리한 행 수(RESUME되면 불량 행도 보정 처리되어 포함, 총 3)
    METHODS process
      RETURNING VALUE(processed) TYPE i
      RAISING   RESUMABLE(lcx_bad_row).
ENDCLASS.

CLASS lcl_importer IMPLEMENTATION.
  METHOD process.
    DATA(rows) = VALUE int_rows( ( 1 ) ( -2 ) ( 3 ) ).
    LOOP AT rows INTO DATA(row).
      IF row < 0.
        " 불량 행 — 재개가능 예외. 소비자가 RESUME하면 이 다음 줄(processed += 1)부터 이어간다.
        RAISE RESUMABLE EXCEPTION TYPE lcx_bad_row.
      ENDIF.
      processed = processed + 1.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.


"! DbC 클래스 불변식(class invariant)을 IF_CONSTRAINT(ABAP Unit 제약 인터페이스)로 구현한다.
"! ABAP 런타임은 Eiffel과 달리 메서드 호출 후 불변식을 자동 검사하지 않으므로,
"! ABAP Unit 테스트에서 cl_abap_unit_assert=>assert_that( act = .. exp = <이 제약> )로 수동 검사한다.
"! assert_that는 is_valid(act)를 호출하고, 거짓이면 get_description을 실패 메시지로 쓴다.
CLASS lcl_non_negative_invariant DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_constraint.
ENDCLASS.

CLASS lcl_non_negative_invariant IMPLEMENTATION.
  METHOD if_constraint~is_valid.
    " 불변식: 값이 음수가 아니어야 한다(예: 계좌 잔액 >= 0).
    result = xsdbool( CONV i( data_object ) >= 0 ).
  ENDMETHOD.

  METHOD if_constraint~get_description.
    result = VALUE #( ( `class invariant: value must be non-negative` ) ).
  ENDMETHOD.
ENDCLASS.
