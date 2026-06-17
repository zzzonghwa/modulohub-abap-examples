CLASS zcl_modulo_df04_constants DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! 열거형(ENUM, since 7.51). 베이스 타입 미지정 시 i. 열거 변수에는
    "! 열거값 외 대입이 금지되어 상수 그룹보다 타입 안전하다.
    TYPES:
      BEGIN OF ENUM severity,
        info,
        warning,
        error,
      END OF ENUM severity.

    "! 상수는 VALUE로 초깃값 지정이 필수다. 매직 넘버를 상수 뒤에 숨겨
    "! 의미를 드러낸다(Clean ABAP).
    CONSTANTS max_retries TYPE i VALUE 3.

    "! 기본 심각도.
    "! @parameter level | info
    METHODS default_level
      RETURNING VALUE(level) TYPE severity.

    "! 흐름을 막는 심각도인지(warning 이상) 판정한다.
    "! @parameter level  | 심각도
    "! @parameter result | warning/error이면 abap_true
    METHODS is_blocking
      IMPORTING level         TYPE severity
      RETURNING VALUE(result) TYPE abap_bool.

    "! 심각도를 텍스트로. CASE가 모든 열거값을 처리한다.
    "! @parameter level | 심각도
    "! @parameter text  | "info"/"warning"/"error"
    METHODS level_text
      IMPORTING level       TYPE severity
      RETURNING VALUE(text) TYPE string.

    "! 한 단계 격상한다. error는 더 격상되지 않는다.
    "! @parameter level  | 현재 심각도
    "! @parameter result | 한 단계 높은 심각도
    METHODS escalate
      IMPORTING level         TYPE severity
      RETURNING VALUE(result) TYPE severity.

    "! 재시도 한도 도달 여부.
    "! @parameter attempt | 현재 시도 횟수
    "! @parameter result  | 한도 도달 시 abap_true
    METHODS retries_exhausted
      IMPORTING attempt       TYPE i
      RETURNING VALUE(result) TYPE abap_bool.

    "! 남은 재시도 횟수(음수는 0으로 가드).
    "! @parameter attempt | 현재 시도 횟수
    "! @parameter result  | max_retries - attempt (최소 0)
    METHODS remaining_retries
      IMPORTING attempt       TYPE i
      RETURNING VALUE(result) TYPE i.
ENDCLASS.


CLASS zcl_modulo_df04_constants IMPLEMENTATION.
  METHOD default_level.
    level = info.
  ENDMETHOD.

  METHOD is_blocking.
    result = xsdbool( level = warning OR level = error ).
  ENDMETHOD.

  METHOD level_text.
    CASE level.
      WHEN info.
        text = `info`.
      WHEN warning.
        text = `warning`.
      WHEN error.
        text = `error`.
    ENDCASE.
  ENDMETHOD.

  METHOD escalate.
    result = SWITCH severity( level
                              WHEN info    THEN warning
                              WHEN warning THEN error
                              ELSE error ).
  ENDMETHOD.

  METHOD retries_exhausted.
    result = xsdbool( attempt >= max_retries ).
  ENDMETHOD.

  METHOD remaining_retries.
    result = COND i( WHEN attempt >= max_retries THEN 0
                     ELSE max_retries - attempt ).
  ENDMETHOD.
ENDCLASS.
