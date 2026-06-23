"! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
"!
"! 예외 처리 전략·CX 분류·Design by Contract. 노트(07-1)의 구문 형태를 자체완결로 시연한다.
"! - CX 3분류: cx_static_check(미처리/미선언 시 구문 경고) · cx_dynamic_check(선언 없이 전파,
"!   런타임 전파 시에만 검사) · cx_no_check(선언 강제 없음, 프레임워크 오류·DBC 위반).
"! - 전략 3택: (1)전파(RAISING) (2)도메인 예외로 변환 (3)기본값으로 흡수.
"! - 진단: get_text·get_longtext·get_source_position·previous 체인·RTTI(표준 cx_sy_* 대상).
"! - 흐름: 다중 CATCH(구체 우선)·RETRY·CLEANUP·COND THROW·RAISE EXCEPTION NEW.
"! - DbC: 사전조건 require/계산기 사전조건은 locals_imp(lcl_dbc·lcl_calculator)에 있다.
CLASS zcl_modulo_tst01_except DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    "! (전략3 흡수) divide를 호출하되 0 나눗셈 예외는 흡수해 0을 돌려준다.
    "! @parameter dividend | 피제수
    "! @parameter divisor  | 제수
    "! @parameter result   | 몫, divisor=0이면 0
    METHODS divide_or_zero
      IMPORTING dividend      TYPE i
                divisor       TYPE i
      RETURNING VALUE(result) TYPE i.

    "! (전략1 전파) divide를 호출하되 예외를 잡지 않고 호출부로 전파한다.
    "! lcx_invalid_arg는 cx_dynamic_check라 RAISING 선언 없이 전파된다(호출부가 CATCH).
    "! @parameter dividend | 피제수
    "! @parameter divisor  | 제수
    "! @parameter result   | 몫
    METHODS divide_strict
      IMPORTING dividend      TYPE i
                divisor       TYPE i
      RETURNING VALUE(result) TYPE i.

    "! (전략3 흡수) withdraw를 호출하되 사전조건 위반은 흡수해 -1을 돌려준다.
    "! @parameter balance | 잔액
    "! @parameter amount  | 출금액
    "! @parameter result  | 출금 후 잔액, 위반(음수·초과)이면 -1
    METHODS withdraw_or_reject
      IMPORTING balance       TYPE i
                amount        TYPE i
      RETURNING VALUE(result) TYPE i.

    "! 다중 CATCH — 구체(하위) 예외를 먼저 지정해야 개별 처리 기회를 잃지 않는다.
    "! lcx_overdrawn(초과)은 -2, 그 외 lcx_invalid_arg(음수)는 -1, 정상은 잔액.
    "! @parameter balance | 잔액
    "! @parameter amount  | 출금액
    "! @parameter result  | 정상=잔액, 초과=-2, 음수=-1
    METHODS withdraw_classified
      IMPORTING balance       TYPE i
                amount        TYPE i
      RETURNING VALUE(result) TYPE i.

    "! 예외 객체 READ-ONLY 속성 — 초과 출금 시 부족액(shortfall)을 예외에서 읽는다.
    "! @parameter balance | 잔액
    "! @parameter amount  | 출금액
    "! @parameter result  | 초과면 부족액(amount-balance), 아니면 0
    METHODS shortfall_of_overdraw
      IMPORTING balance       TYPE i
                amount        TYPE i
      RETURNING VALUE(result) TYPE i.

    "! RETRY — 첫 시도는 실패하도록 두고 CATCH에서 원인을 제거 후 처음부터 재실행한다.
    "! RETRY는 TRY 블록을 처음부터 다시 도므로 상태 리셋 책임은 CATCH에 있다.
    "! @parameter amount | 출금액(첫 시도엔 잔액 초과로 실패, 보정 후 성공)
    "! @parameter result | 보정 출금 후 잔액
    METHODS withdraw_with_retry
      IMPORTING amount        TYPE i
      RETURNING VALUE(result) TYPE i.

    "! CLEANUP — 예외가 외부(호출부)에서 처리될 때만 실행된다. 로컬 CATCH면 실행 안 됨.
    "! 두 경로를 한 메서드에서 비교해, CLEANUP이 자원 해제 플래그를 세웠는지 문자열로 보인다.
    "! @parameter result | 'local=X cleanup= / propagated=X cleanup=X' 형태 관찰 결과
    METHODS cleanup_observed
      RETURNING VALUE(result) TYPE string.

    "! (전략2 변환) 표준 변환 예외 cx_sy_conversion_no_number를 흡수해 기본값으로 바꾼다.
    "! 클래식 오류(잘못된 숫자 텍스트) -> 안전한 기본값 변환 패턴.
    "! @parameter text     | 정수로 변환할 텍스트
    "! @parameter fallback | 변환 실패 시 돌려줄 기본값
    "! @parameter result   | 변환된 정수, 실패 시 fallback
    METHODS parse_or_default
      IMPORTING text          TYPE string
                fallback      TYPE i
      RETURNING VALUE(result) TYPE i.

    "! get_text — 표준 0 나눗셈 예외의 단문 메시지가 비어있지 않음을 길이로 확인한다.
    "! cx_sy_zerodivide는 cx_sy_arithmetic_error -> cx_dynamic_check 체인에 속한다.
    "! @parameter result | get_text( ) 길이(>0)
    METHODS zero_divide_text_len
      RETURNING VALUE(result) TYPE i.

    "! get_source_position — 예외 발생 위치의 소스 라인 번호(>0)를 읽는다.
    "! @parameter result | 예외가 발생한 source_line(>0)
    METHODS error_source_line
      RETURNING VALUE(result) TYPE i.

    "! RTTI — 잡은 예외 객체의 런타임 클래스명을 describe_by_object_ref로 추출한다.
    "! 테이블 행 미존재(cx_sy_itab_line_not_found)를 일으켜 그 상대 클래스명을 돌려준다.
    "! @parameter result | 예외의 상대 클래스명(대문자)
    METHODS error_type_name
      RETURNING VALUE(result) TYPE string.

    "! COND ... THROW — 피연산자 자리에서 직접 예외를 던진다(RAISE EXCEPTION TYPE와 동치).
    "! 음수면 THROW, 아니면 두 배 값을 돌려준다. 호출부가 흡수해 -1로 관찰한다.
    "! @parameter value  | 입력값
    "! @parameter result | value>=0이면 value*2, 음수면 -1(흡수)
    METHODS double_or_throw
      IMPORTING value         TYPE i
      RETURNING VALUE(result) TYPE i.

    "! DbC require — lcl_dbc=>require( that which_is_true_if )로 사전조건을 검사한다.
    "! 조건 위반(나이<0) 시 사전조건 예외를 흡수해 abap_false, 만족 시 abap_true.
    "! @parameter age    | 검사할 나이
    "! @parameter result | age>=0이면 abap_true, 위반이면 abap_false
    METHODS require_non_negative_age
      IMPORTING age           TYPE i
      RETURNING VALUE(result) TYPE abap_bool.

    "! RESUMABLE — 재개가능 예외. 공급자가 RAISE RESUMABLE EXCEPTION으로 던지면, 소비자가
    "! CATCH BEFORE UNWIND로 받아(스택 미해제) 원인을 고친 뒤 RESUME하면 *예외 발생 다음 줄*부터 이어간다.
    "! 일반 CATCH는 TRY를 빠져나가 재개 불가 — BEFORE UNWIND + RESUME만 발생 지점으로 복귀한다.
    "! @parameter result | 행 [1,-2,3] 처리 수 — 불량 행(-2)을 RESUME으로 보정해 3
    METHODS resumable_demo
      RETURNING VALUE(result) TYPE i.

ENDCLASS.


CLASS zcl_modulo_tst01_except IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== TST01 예외 처리·CX 분류·DbC ===` ).
    out->write( |divide_or_zero(10,2)          = { divide_or_zero( dividend = 10 divisor = 2 ) }| ).
    out->write( |divide_or_zero(10,0) 흡수      = { divide_or_zero( dividend = 10 divisor = 0 ) }| ).
    out->write( |withdraw_or_reject(100,30)     = { withdraw_or_reject( balance = 100 amount = 30 ) }| ).
    out->write( |withdraw_or_reject(100,150)    = { withdraw_or_reject( balance = 100 amount = 150 ) }| ).
    out->write( |withdraw_classified(100,150)   = { withdraw_classified( balance = 100 amount = 150 ) } (초과=-2)| ).
    out->write( |withdraw_classified(100,-5)    = { withdraw_classified( balance = 100 amount = -5 ) } (음수=-1)| ).
    out->write( |shortfall_of_overdraw(100,150) = { shortfall_of_overdraw( balance = 100 amount = 150 ) }| ).
    out->write( |withdraw_with_retry(150)       = { withdraw_with_retry( 150 ) } (RETRY 보정)| ).
    out->write( |cleanup_observed              = { cleanup_observed( ) }| ).
    out->write( |parse_or_default('42',-1)      = { parse_or_default( text = `42` fallback = -1 ) }| ).
    out->write( |parse_or_default('x',-1) 변환   = { parse_or_default( text = `x` fallback = -1 ) }| ).
    out->write( |zero_divide_text_len          = { zero_divide_text_len( ) } (>0)| ).
    out->write( |error_source_line             = { error_source_line( ) } (>0)| ).
    out->write( |error_type_name               = { error_type_name( ) } (RTTI)| ).
    out->write( |double_or_throw(7)             = { double_or_throw( 7 ) }| ).
    out->write( |double_or_throw(-3) THROW흡수   = { double_or_throw( -3 ) }| ).
    out->write( |require_non_negative_age(20)   = { require_non_negative_age( 20 ) }| ).
    out->write( |require_non_negative_age(-1)   = { require_non_negative_age( -1 ) }| ).
    out->write( |resumable_demo               = { resumable_demo( ) } (RESUMABLE: RESUME으로 이어감)| ).
  ENDMETHOD.

  METHOD divide_or_zero.
    TRY.
        result = NEW lcl_calculator( )->divide( dividend = dividend divisor = divisor ).
      CATCH lcx_invalid_arg.
        " 흡수: 도메인 예외를 안전한 기본값으로 바꾼다.
        result = 0.
    ENDTRY.
  ENDMETHOD.

  METHOD divide_strict.
    " 전파: 잡지 않는다. RAISING 절로 호출부에 예외 책임을 넘긴다.
    result = NEW lcl_calculator( )->divide( dividend = dividend divisor = divisor ).
  ENDMETHOD.

  METHOD withdraw_or_reject.
    TRY.
        result = NEW lcl_calculator( )->withdraw( balance = balance amount = amount ).
      CATCH lcx_invalid_arg.
        result = -1.
    ENDTRY.
  ENDMETHOD.

  METHOD withdraw_classified.
    TRY.
        result = NEW lcl_calculator( )->withdraw( balance = balance amount = amount ).
        " 구체 하위(lcx_overdrawn)를 먼저 — 상위(lcx_invalid_arg)를 먼저 두면 초과를 따로 못 잡는다.
      CATCH lcx_overdrawn.
        result = -2.
      CATCH lcx_invalid_arg.
        result = -1.
    ENDTRY.
  ENDMETHOD.

  METHOD shortfall_of_overdraw.
    TRY.
        NEW lcl_calculator( )->withdraw( balance = balance amount = amount ).
        result = 0.
        " INTO DATA(err)로 예외 객체를 캡처해 READ-ONLY 속성(shortfall)을 읽는다.
      CATCH lcx_overdrawn INTO DATA(overdraw_error).
        result = overdraw_error->shortfall.
      CATCH lcx_invalid_arg.
        result = 0.
    ENDTRY.
  ENDMETHOD.

  METHOD withdraw_with_retry.
    DATA balance TYPE i VALUE 100.
    DATA already_topped_up TYPE abap_bool.
    TRY.
        " 첫 시도: balance=100, amount=150 -> 초과 예외. CATCH에서 잔액 보충 후 RETRY.
        result = NEW lcl_calculator( )->withdraw( balance = balance amount = amount ).
      CATCH lcx_invalid_arg.
        IF already_topped_up = abap_false.
          already_topped_up = abap_true.
          " 원인 제거: 잔액을 충분히 보충한다. 제거하지 않으면 RETRY는 무한 루프가 된다.
          balance = amount.
          RETRY.
        ENDIF.
        result = -1.
    ENDTRY.
  ENDMETHOD.

  METHOD cleanup_observed.
    " 경로 A: 같은 TRY의 CATCH에서 처리 -> CLEANUP 실행 안 됨.
    DATA(local_cleanup_ran) = abap_false.
    TRY.
        RAISE EXCEPTION NEW lcx_invalid_arg( ).
      CATCH lcx_invalid_arg.
        " 로컬 처리.
      CLEANUP.
        local_cleanup_ran = abap_true.
    ENDTRY.

    " 경로 B: 안쪽 TRY는 안 잡고 바깥에서 처리 -> 안쪽 CLEANUP 실행됨.
    DATA(propagated_cleanup_ran) = abap_false.
    TRY.
        TRY.
            RAISE EXCEPTION NEW lcx_invalid_arg( ).
          CLEANUP.
            propagated_cleanup_ran = abap_true.
        ENDTRY.
      CATCH lcx_invalid_arg.
        " 바깥에서 처리.
    ENDTRY.

    result = |local={ local_cleanup_ran } propagated={ propagated_cleanup_ran }|.
  ENDMETHOD.

  METHOD parse_or_default.
    TRY.
        " 잘못된 숫자 텍스트는 런타임에 cx_sy_conversion_no_number를 일으킨다.
        result = CONV i( text ).
      CATCH cx_sy_conversion_no_number.
        " 변환: 표준 예외를 흡수해 안전한 기본값으로 바꾼다.
        result = fallback.
    ENDTRY.
  ENDMETHOD.

  METHOD zero_divide_text_len.
    " 제수를 변수로 둔다 — 리터럴 1/0은 활성화 시 상수폴딩으로 구문오류가 나 런타임 예외가 안 잡힌다.
    DATA(zero) = 0.
    TRY.
        result = 1 / zero.
      CATCH cx_sy_zerodivide INTO DATA(divide_error).
        " get_text( ): 예외의 단문 메시지(short text).
        result = strlen( divide_error->get_text( ) ).
    ENDTRY.
  ENDMETHOD.

  METHOD error_source_line.
    " 제수를 변수로 둔다(리터럴 1/0은 활성화 구문오류).
    DATA(zero) = 0.
    TRY.
        result = 1 / zero.
      CATCH cx_sy_zerodivide INTO DATA(divide_error).
        " get_source_position( ): program_name·include_name·source_line 반환.
        divide_error->get_source_position( IMPORTING source_line = result ).
    ENDTRY.
  ENDMETHOD.

  METHOD error_type_name.
    DATA numbers TYPE STANDARD TABLE OF i WITH EMPTY KEY.
    TRY.
        " 빈 테이블의 행 1을 읽으면 cx_sy_itab_line_not_found.
        DATA(missing) = numbers[ 1 ] ##NEEDED.
      CATCH cx_sy_itab_line_not_found INTO DATA(line_error).
        " RTTI: 예외 객체의 런타임 클래스명을 추출한다.
        DATA(type_info) = CAST cl_abap_classdescr(
          cl_abap_typedescr=>describe_by_object_ref( line_error ) ).
        result = type_info->get_relative_name( ).
    ENDTRY.
  ENDMETHOD.

  METHOD double_or_throw.
    TRY.
        " COND의 피연산자 자리에서 THROW로 직접 예외 발생.
        result = COND #( WHEN value >= 0
                         THEN value * 2
                         ELSE THROW lcx_invalid_arg( attempted = value ) ).
      CATCH lcx_invalid_arg.
        result = -1.
    ENDTRY.
  ENDMETHOD.

  METHOD require_non_negative_age.
    TRY.
        lcl_dbc=>require( that             = `age must be non-negative`
                          which_is_true_if = xsdbool( age >= 0 ) ).
        result = abap_true.
      CATCH lcx_precondition.
        result = abap_false.
      CATCH cx_root.
        " 방어적 catch-all — 인클루드/클래스 동일성 문제로 위 CATCH가 빗나가도 F9 덤프를 막는다.
        result = abap_false.
    ENDTRY.
  ENDMETHOD.

  METHOD resumable_demo.
    " RESUMABLE 소비: CATCH BEFORE UNWIND는 스택을 풀기 전에 잡아, 원인 보정 후 RESUME으로
    " 예외 발생 다음 줄부터 이어가게 한다(일반 CATCH는 TRY를 빠져나가 재개 불가).
    DATA(importer) = NEW lcl_importer( ).
    TRY.
        result = importer->process( ).
      CATCH BEFORE UNWIND lcx_bad_row.
        " 불량 행을 보정했다고 가정하고 RESUME -> process의 RAISE 다음 줄부터 이어간다.
        RESUME.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.
