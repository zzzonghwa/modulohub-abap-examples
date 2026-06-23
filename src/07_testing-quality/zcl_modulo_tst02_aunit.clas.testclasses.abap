"! 테스트 더블(spy) — hour를 고정 반환하면서 호출 횟수를 기록한다(상호작용 검증용).
"! 수동 스파이: 표준 CL_ABAP_TESTDOUBLE는 글로벌 타입만 더블링하므로 로컬 의존엔 수동 스파이를 쓴다.
CLASS lcl_clock_spy DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES lif_clock.
    DATA calls TYPE i READ-ONLY.
    METHODS set_hour IMPORTING value TYPE i.
  PRIVATE SECTION.
    DATA hour_value TYPE i.
ENDCLASS.

CLASS lcl_clock_spy IMPLEMENTATION.
  METHOD set_hour.
    hour_value = value.
  ENDMETHOD.

  METHOD lif_clock~hour.
    calls = calls + 1.
    result = hour_value.
  ENDMETHOD.
ENDCLASS.


"! 발송 싱크 스파이 — send 호출 본문(텍스트)과 flush 횟수를 기록한다(상호작용 검증).
"! spy 패턴: "어떤 메서드가 몇 번·무엇으로 호출됐나"를 본다.
CLASS lcl_sink_spy DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES lif_notifier.
    DATA sends    TYPE i READ-ONLY.
    DATA flushes  TYPE i READ-ONLY.
    DATA last_text TYPE string READ-ONLY.
ENDCLASS.

CLASS lcl_sink_spy IMPLEMENTATION.
  METHOD lif_notifier~send.
    sends = sends + 1.
    last_text = text.
  ENDMETHOD.

  METHOD lif_notifier~flush.
    flushes = flushes + 1.
  ENDMETHOD.
ENDCLASS.


"! 부분 구현 더블 — INTERFACES ... PARTIALLY IMPLEMENTED는 테스트 클래스에서만 허용.
"! flush만 구현하고 send는 미구현 — 테스트가 send를 부르지 않는 시나리오에 충분하다.
"! send를 부르면 런타임 오류가 나므로, 테스트가 더블의 사용 범위를 좁히는 효과가 있다.
CLASS ltcl_flush_only_double DEFINITION FOR TESTING.
  PUBLIC SECTION.
    INTERFACES lif_notifier PARTIALLY IMPLEMENTED.
    DATA flushes TYPE i READ-ONLY.
ENDCLASS.

CLASS ltcl_flush_only_double IMPLEMENTATION.
  METHOD lif_notifier~flush.
    flushes = flushes + 1.
  ENDMETHOD.
ENDCLASS.


"! 커스텀 단언 헬퍼 — 도메인을 이해하는 단언을 표준과 같은 계약(msg)으로 제공.
"! ABSTRACT FINAL 유틸리티 클래스로 정적 메서드만 노출(상속 불필요한 헬퍼 패턴).
"! 테스트 인클루드 전용 헬퍼이며 FOR TESTING은 붙이지 않는다(테스트 메서드를 담지 않으므로).
CLASS lcl_greeting_assert DEFINITION ABSTRACT FINAL.
  PUBLIC SECTION.
    "! 인사말이 정해진 어휘집(아침·점심·저녁) 중 하나인지 단언한다.
    CLASS-METHODS assert_is_valid_greeting
      IMPORTING actual TYPE string
                msg    TYPE string OPTIONAL.
ENDCLASS.

CLASS lcl_greeting_assert IMPLEMENTATION.
  METHOD assert_is_valid_greeting.
    DATA(allowed) = VALUE string_table( ( `Good morning` ) ( `Good afternoon` ) ( `Good evening` ) ).
    cl_abap_unit_assert=>assert_true(
      act = xsdbool( line_exists( allowed[ table_line = actual ] ) )
      msg = COND #( WHEN msg IS NOT INITIAL THEN msg ELSE |unexpected greeting: { actual }| ) ).
  ENDMETHOD.
ENDCLASS.


"! 시간대별 인사 — 클래스명은 공통 when(by_time)을, 메서드명은 then을 담는다.
CLASS ltcl_greeting_by_time DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_tst02_aunit.
    "! given 추출: 고정 시각으로 인사기를 직접 조립해 돌려준다.
    METHODS greeter_at
      IMPORTING hour          TYPE i
      RETURNING VALUE(result) TYPE REF TO lcl_greeter.
    METHODS setup.
    METHODS morning_before_noon    FOR TESTING.
    METHODS afternoon_before_six   FOR TESTING.
    METHODS evening_after_six      FOR TESTING.
    METHODS facade_matches_greeter FOR TESTING.
    METHODS greeting_is_in_lexicon FOR TESTING.
    METHODS boundary_at_noon       FOR TESTING.
ENDCLASS.


CLASS ltcl_greeting_by_time IMPLEMENTATION.
  METHOD setup.
    " 픽스처: 매 테스트 전 cut를 새로 만든다. teardown은 불필요(런타임이 새 인스턴스 생성).
    cut = NEW #( ).
  ENDMETHOD.

  METHOD greeter_at.
    result = NEW lcl_greeter( NEW lcl_fixed_clock( hour ) ).
  ENDMETHOD.

  METHOD morning_before_noon.
    cl_abap_unit_assert=>assert_equals( act = greeter_at( 8 )->greet( ) exp = `Good morning` ).
  ENDMETHOD.

  METHOD afternoon_before_six.
    cl_abap_unit_assert=>assert_equals( act = greeter_at( 14 )->greet( ) exp = `Good afternoon` ).
  ENDMETHOD.

  METHOD evening_after_six.
    cl_abap_unit_assert=>assert_equals( act = greeter_at( 20 )->greet( ) exp = `Good evening` ).
  ENDMETHOD.

  METHOD boundary_at_noon.
    " 경계값: 12시는 정확히 오후로 넘어가는 첫 시각이다.
    cl_abap_unit_assert=>assert_equals( act = greeter_at( 12 )->greet( ) exp = `Good afternoon` ).
  ENDMETHOD.

  METHOD facade_matches_greeter.
    " 파사드와 도메인 객체가 같은 결과를 내는지 — 파사드 회귀 가드.
    cl_abap_unit_assert=>assert_equals( act = cut->greeting_at( 8 ) exp = greeter_at( 8 )->greet( ) ).
  ENDMETHOD.

  METHOD greeting_is_in_lexicon.
    " 커스텀 단언 헬퍼: 정확한 문자열이 아니라 "유효한 인사말" 속성을 단언.
    lcl_greeting_assert=>assert_is_valid_greeting( cut->greeting_at( 23 ) ).
  ENDMETHOD.
ENDCLASS.


"! 업무시간 판정 — bool·initial·char_cp·that 등 단언 다양체를 모은다.
CLASS ltcl_business_hours DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_tst02_aunit.
    METHODS setup.
    METHODS true_during_office  FOR TESTING.
    METHODS false_at_night      FOR TESTING.
    METHODS assert_bound_double FOR TESTING.
    METHODS char_pattern_match  FOR TESTING.
    METHODS differs_across_times FOR TESTING.
ENDCLASS.


CLASS ltcl_business_hours IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD true_during_office.
    cl_abap_unit_assert=>assert_true( act = cut->is_business_hours_at( 10 ) ).
  ENDMETHOD.

  METHOD false_at_night.
    cl_abap_unit_assert=>assert_false( act = cut->is_business_hours_at( 20 ) ).
  ENDMETHOD.

  METHOD assert_bound_double.
    " assert_bound: 더블 참조가 바운드(생성됨)인지 — given의 사전조건 점검.
    DATA(clock) = NEW lcl_fixed_clock( 10 ).
    cl_abap_unit_assert=>assert_bound( act = clock ).
  ENDMETHOD.

  METHOD char_pattern_match.
    " assert_char_cp: 인사말이 'Good *' 패턴에 매치되는지(CP 연산자) — 내용이 아닌 형태 단언.
    cl_abap_unit_assert=>assert_char_cp( act = NEW zcl_modulo_tst02_aunit( )->greeting_at( 8 )
                                         exp = `Good *` ).
  ENDMETHOD.

  METHOD differs_across_times.
    " assert_differs: 두 기본형이 서로 다름을 단언. 아침≠저녁 인사여야 한다.
    cl_abap_unit_assert=>assert_differs( act = cut->greeting_at( 8 ) exp = cut->greeting_at( 20 ) ).
  ENDMETHOD.
ENDCLASS.


"! 발송 분기 — 더블 주입으로 lcl_dispatcher를 격리하고 상호작용·예외를 검증한다.
"! class_setup/class_teardown도 시연: 클래스 전체 1회 공유 준비.
CLASS ltcl_dispatch DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CLASS-DATA office_hour TYPE i.
    DATA sink TYPE REF TO lcl_sink_spy.
    "! given 추출: 주어진 시각·스파이 싱크로 발송기를 조립한다.
    METHODS dispatcher_at
      IMPORTING hour          TYPE i
      RETURNING VALUE(result) TYPE REF TO lcl_dispatcher.
    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.
    METHODS setup.
    METHODS sends_during_office     FOR TESTING.
    METHODS silent_after_hours      FOR TESTING.
    METHODS flushes_once_when_sent  FOR TESTING.
    METHODS partial_double_flush    FOR TESTING.
    METHODS within_limit_sends      FOR TESTING RAISING cx_static_check.
    METHODS over_limit_raises       FOR TESTING.
    METHODS over_limit_shortfall    FOR TESTING.
ENDCLASS.


CLASS ltcl_dispatch IMPLEMENTATION.
  METHOD class_setup.
    " class_setup: 전체 클래스 시작 전 1회. 변경 없는 공유 상수만 준비한다.
    office_hour = 10.
  ENDMETHOD.

  METHOD class_teardown.
    " class_teardown: 로컬 더블만 쓰므로 외부 정리 대상 없음 — 형태 시연용.
    RETURN.
  ENDMETHOD.

  METHOD setup.
    sink = NEW lcl_sink_spy( ).
  ENDMETHOD.

  METHOD dispatcher_at.
    result = NEW lcl_dispatcher( clock = NEW lcl_fixed_clock( hour ) notifier = sink ).
  ENDMETHOD.

  METHOD sends_during_office.
    " when=업무시간 발송 -> then=1건 발송, 스파이 송신 1회, 본문 일치.
    cl_abap_unit_assert=>assert_equals( act = dispatcher_at( office_hour )->dispatch( `hi` ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = sink->sends    exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = sink->last_text exp = `hi` ).
  ENDMETHOD.

  METHOD silent_after_hours.
    " when=시간 밖 -> then=미발송. 스파이가 한 번도 안 불렸음을 단언(상호작용 부재).
    cl_abap_unit_assert=>assert_equals( act = dispatcher_at( 22 )->dispatch( `hi` ) exp = 0 ).
    cl_abap_unit_assert=>assert_initial( act = sink->sends ).
  ENDMETHOD.

  METHOD flushes_once_when_sent.
    " 상호작용 검증: flush가 정확히 1회 호출됐는지.
    dispatcher_at( office_hour )->dispatch( `hi` ).
    cl_abap_unit_assert=>assert_equals( act = sink->flushes exp = 1 ).
  ENDMETHOD.

  METHOD partial_double_flush.
    " PARTIALLY IMPLEMENTED 더블: 시간 밖 시나리오는 send를 부르지 않으므로
    " flush만 구현한 더블로 충분하다 — 더블의 표면을 시나리오 크기에 맞춘다.
    DATA(partial) = NEW ltcl_flush_only_double( ).
    DATA(dispatcher) = NEW lcl_dispatcher( clock = NEW lcl_fixed_clock( 22 ) notifier = partial ).
    cl_abap_unit_assert=>assert_equals( act = dispatcher->dispatch( `hi` ) exp = 0 ).
    cl_abap_unit_assert=>assert_initial( act = partial->flushes ).
  ENDMETHOD.

  METHOD within_limit_sends.
    " RAISING 전달 패턴: happy path는 예외가 무의미하므로 메서드 시그니처에
    " RAISING cx_static_check를 달아 전달한다. 예외가 나면 런타임이 실패로 보고한다.
    DATA(result) = dispatcher_at( office_hour )->dispatch_within_limit( amount = 50 limit = 80 ).
    cl_abap_unit_assert=>assert_equals( act = result exp = 50 ).
    cl_abap_unit_assert=>assert_equals( act = sink->sends exp = 1 ).
  ENDMETHOD.

  METHOD over_limit_raises.
    " 예외 기대 패턴: TRY-호출-FAIL-CATCH. 예외가 안 나면 FAIL이 실패시킨다.
    TRY.
        dispatcher_at( office_hour )->dispatch_within_limit( amount = 99 limit = 80 ).
        cl_abap_unit_assert=>fail( msg = `expected lcx_rejected` ).
      CATCH lcx_rejected.
        " 기대한 예외 — 통과.
    ENDTRY.
  ENDMETHOD.

  METHOD over_limit_shortfall.
    " 예외의 페이로드까지 검증: 부족액 = amount - limit = 99 - 80 = 19.
    TRY.
        dispatcher_at( office_hour )->dispatch_within_limit( amount = 99 limit = 80 ).
        cl_abap_unit_assert=>fail( msg = `expected lcx_rejected` ).
      CATCH lcx_rejected INTO DATA(rejected).
        cl_abap_unit_assert=>assert_equals( act = rejected->shortfall exp = 19 ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
