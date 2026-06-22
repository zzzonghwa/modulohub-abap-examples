CLASS zcl_modulo_tst04_clean DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
    "!
    "! Clean ABAP 규칙 모음(코드로 시연).
    "! - 불리언은 abap_bool로 반환(xsdbool) — 직접 'X'/' '를 쓰지 않는다.
    "! - 불리언 입력 파라미터를 피한다 — 의미 있는 값으로 받는다(여기 메서드들도 플래그 인자 없음).
    "! - 가드 절(early return)로 들여쓰기를 낮춘다.
    "! - IF 사슬 대신 SWITCH로 분기한다.
    "! - 서술적 이름(타입/헝가리안 접두사 금지), 작은 함수형 메서드(RETURNING).
    INTERFACES if_oo_adt_classrun.

    "! 불리언 반환은 xsdbool로 — 비교식을 abap_bool로 변환한다.
    "! @parameter day    | 1=Mon .. 7=Sun
    "! @parameter result | 토·일이면 abap_true
    METHODS is_weekend
      IMPORTING day           TYPE i
      RETURNING VALUE(result) TYPE abap_bool.

    "! SWITCH 디스패치(IF 사슬 회피). 회원 등급 -> 할인율(%).
    "! @parameter membership | 'GOLD'/'SILVER'(그 외 0)
    "! @parameter result     | 할인율(%)
    METHODS discount_rate
      IMPORTING membership    TYPE string
      RETURNING VALUE(result) TYPE i.

    "! 가드 절 시연 — 빈 입력은 즉시 빈 결과로 반환해 본문 들여쓰기를 낮춘다.
    "! @parameter sentence | 문장
    "! @parameter result   | 첫 단어(공백 기준), 빈 입력이면 공백
    METHODS first_word
      IMPORTING sentence      TYPE string
      RETURNING VALUE(result) TYPE string.
ENDCLASS.


CLASS zcl_modulo_tst04_clean IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== TST04 Clean ABAP 규칙 ===` ).
    out->write( |is_weekend(6)          = { is_weekend( 6 ) }| ).
    out->write( |is_weekend(3)          = { is_weekend( 3 ) }| ).
    out->write( |discount_rate('GOLD')  = { discount_rate( `GOLD` ) }| ).
    out->write( |first_word('hello abap') = { first_word( `hello abap` ) }| ).
  ENDMETHOD.

  METHOD is_weekend.
    result = xsdbool( day = 6 OR day = 7 ).
  ENDMETHOD.

  METHOD discount_rate.
    result = SWITCH i( membership
                       WHEN `GOLD`   THEN 20
                       WHEN `SILVER` THEN 10
                       ELSE 0 ).
  ENDMETHOD.

  METHOD first_word.
    IF sentence IS INITIAL.
      RETURN.
    ENDIF.
    SPLIT sentence AT ` ` INTO TABLE DATA(words).
    result = words[ 1 ].
  ENDMETHOD.
ENDCLASS.
