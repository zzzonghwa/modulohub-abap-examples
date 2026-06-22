"! 시각 의존 계약 — 현재 시(0..23)만 노출하는 좁은 인터페이스(주입 대상).
INTERFACE lif_clock.
  METHODS hour RETURNING VALUE(result) TYPE i.
ENDINTERFACE.


"! 알림 싱크 계약 — 두 메서드. 더블이 일부만 구현(PARTIALLY IMPLEMENTED)하는 시연 대상이 된다.
INTERFACE lif_notifier.
  METHODS send IMPORTING text TYPE string.
  METHODS flush.
ENDINTERFACE.


"! 고정 시각 클록 — 생성자로 받은 시를 늘 돌려준다(결정적 입력 제공·수동 스텁).
CLASS lcl_fixed_clock DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES lif_clock.
    METHODS constructor IMPORTING hour TYPE i.
  PRIVATE SECTION.
    DATA hour_value TYPE i.
ENDCLASS.

CLASS lcl_fixed_clock IMPLEMENTATION.
  METHOD constructor.
    hour_value = hour.
  ENDMETHOD.

  METHOD lif_clock~hour.
    result = hour_value.
  ENDMETHOD.
ENDCLASS.


"! 메모리 싱크 — lif_notifier를 완전 구현한 실제 stub(부수효과 없이 메모리에만 누적).
"! 노트 "Only Mock What's Needed"(주장40): 부수효과 없는 의존은 더블 대신 실 구현을 쓴다.
CLASS lcl_memory_sink DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES lif_notifier.
    METHODS sent_count RETURNING VALUE(result) TYPE i.
  PRIVATE SECTION.
    DATA messages TYPE STANDARD TABLE OF string WITH EMPTY KEY.
ENDCLASS.

CLASS lcl_memory_sink IMPLEMENTATION.
  METHOD lif_notifier~send.
    APPEND text TO messages.
  ENDMETHOD.

  METHOD lif_notifier~flush.
    RETURN.
  ENDMETHOD.

  METHOD sent_count.
    result = lines( messages ).
  ENDMETHOD.
ENDCLASS.


"! 인사기(CUT) — 시각 의존을 생성자 주입으로 받아 시간대별 인사를 만든다.
"! 시간(부수효과·비결정성)을 인터페이스 뒤로 숨겨 테스트가 결정적으로 통제한다.
CLASS lcl_greeter DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS constructor IMPORTING clock TYPE REF TO lif_clock.
    METHODS greet RETURNING VALUE(result) TYPE string.
    METHODS is_business_hours RETURNING VALUE(result) TYPE abap_bool.
  PRIVATE SECTION.
    DATA clock TYPE REF TO lif_clock.
ENDCLASS.

CLASS lcl_greeter IMPLEMENTATION.
  METHOD constructor.
    me->clock = clock.
  ENDMETHOD.

  METHOD greet.
    DATA(current_hour) = clock->hour( ).
    result = COND #( WHEN current_hour < 12 THEN `Good morning`
                     WHEN current_hour < 18 THEN `Good afternoon`
                     ELSE                        `Good evening` ).
  ENDMETHOD.

  METHOD is_business_hours.
    DATA(current_hour) = clock->hour( ).
    result = xsdbool( current_hour >= 9 AND current_hour < 18 ).
  ENDMETHOD.
ENDCLASS.


"! 출금 거부 도메인 예외 — 예외 기대 테스트(주장 37)·RAISING 전달(주장 38)의 대상.
CLASS lcx_rejected DEFINITION INHERITING FROM cx_static_check CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS constructor IMPORTING shortfall TYPE i.
    DATA shortfall TYPE i READ-ONLY.
ENDCLASS.

CLASS lcx_rejected IMPLEMENTATION.
  METHOD constructor.
    super->constructor( ).
    me->shortfall = shortfall.
  ENDMETHOD.
ENDCLASS.


"! 알림 발송기(CUT) — 시각 의존(lif_clock)과 싱크 의존(lif_notifier) 둘을 생성자 주입.
"! 두 의존을 더블로 교체해 "업무시간에만 발송"·"한도 초과 시 예외" 같은 분기를 격리 검증한다.
CLASS lcl_dispatcher DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS constructor
      IMPORTING clock    TYPE REF TO lif_clock
                notifier TYPE REF TO lif_notifier.
    "! 업무시간(09~17)일 때만 싱크로 발송하고 1을, 아니면 0을 돌려준다.
    METHODS dispatch
      IMPORTING text          TYPE string
      RETURNING VALUE(result) TYPE i.
    "! amount가 한도(limit) 초과면 lcx_rejected를 던진다. 정상이면 잔액을 발송한다.
    METHODS dispatch_within_limit
      IMPORTING amount        TYPE i
                limit         TYPE i
      RETURNING VALUE(result) TYPE i
      RAISING   lcx_rejected.
  PRIVATE SECTION.
    DATA clock    TYPE REF TO lif_clock.
    DATA notifier TYPE REF TO lif_notifier.
ENDCLASS.

CLASS lcl_dispatcher IMPLEMENTATION.
  METHOD constructor.
    me->clock    = clock.
    me->notifier = notifier.
  ENDMETHOD.

  METHOD dispatch.
    DATA(current_hour) = clock->hour( ).
    IF current_hour < 9 OR current_hour >= 18.
      RETURN.
    ENDIF.
    notifier->send( text ).
    notifier->flush( ).
    result = 1.
  ENDMETHOD.

  METHOD dispatch_within_limit.
    IF amount > limit.
      RAISE EXCEPTION NEW lcx_rejected( shortfall = amount - limit ).
    ENDIF.
    notifier->send( |amount={ amount }| ).
    result = amount.
  ENDMETHOD.
ENDCLASS.
