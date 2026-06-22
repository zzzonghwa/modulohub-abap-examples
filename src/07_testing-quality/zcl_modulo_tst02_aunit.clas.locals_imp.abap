"! 시각 의존 계약 — 현재 시(0..23)만 노출하는 좁은 인터페이스(주입 대상).
INTERFACE lif_clock.
  METHODS hour RETURNING VALUE(result) TYPE i.
ENDINTERFACE.


"! 고정 시각 클록 — 생성자로 받은 시를 늘 돌려준다(결정적 입력 제공).
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
    DATA(h) = clock->hour( ).
    result = COND #( WHEN h < 12 THEN `Good morning`
                     WHEN h < 18 THEN `Good afternoon`
                     ELSE              `Good evening` ).
  ENDMETHOD.

  METHOD is_business_hours.
    DATA(h) = clock->hour( ).
    result = xsdbool( h >= 9 AND h < 18 ).
  ENDMETHOD.
ENDCLASS.
