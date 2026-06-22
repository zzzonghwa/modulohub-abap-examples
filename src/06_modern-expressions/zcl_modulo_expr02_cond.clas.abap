CLASS zcl_modulo_expr02_cond DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
    "!
    "! COND: 조건(논리식) 기반 분기 표현식. WHEN 순서대로 평가, 첫 참을 반환.
    "! SWITCH: 한 피연산자의 값 일치 기반 분기 표현식(CASE의 표현식판).
    "! 둘 다 ELSE 없이 미일치면 결과 타입 초기값. 미일치에 THROW로 예외도 가능.
    INTERFACES if_oo_adt_classrun.

    "! COND(범위 분류): 논리식으로 크기 구간을 가른다.
    "! @parameter n      | 분류할 값
    "! @parameter result | n<10 'small', n<100 'medium', 그 외 'large'
    METHODS classify_size
      IMPORTING n             TYPE i
      RETURNING VALUE(result) TYPE string.

    "! COND(2분기): 부호 없는 차이.
    "! @parameter a      | 값 1
    "! @parameter b      | 값 2
    "! @parameter result | |a - b|
    METHODS abs_diff
      IMPORTING a             TYPE i
                b             TYPE i
      RETURNING VALUE(result) TYPE i.

    "! SWITCH(정확 값 매칭): 요일 번호 -> 이름.
    "! @parameter day    | 1=Mon .. 7=Sun
    "! @parameter result | 요일 이름, 범위 밖이면 '?'
    METHODS weekday_name
      IMPORTING day           TYPE i
      RETURNING VALUE(result) TYPE string.

    "! SWITCH(문자열 매칭): 신호색 -> 행동. 대소문자 무시.
    "! @parameter color  | 'RED'/'GREEN'/'YELLOW'(대소문자 무관)
    "! @parameter result | 'stop'/'go'/'slow', 미일치 '?'
    METHODS traffic_action
      IMPORTING color         TYPE string
      RETURNING VALUE(result) TYPE string.
ENDCLASS.


CLASS zcl_modulo_expr02_cond IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== EXPR02 COND·SWITCH ===` ).
    out->write( |classify_size(5)        = { classify_size( 5 ) }| ).
    out->write( |classify_size(50)       = { classify_size( 50 ) }| ).
    out->write( |classify_size(500)      = { classify_size( 500 ) }| ).
    out->write( |abs_diff(3,8)           = { abs_diff( a = 3 b = 8 ) }| ).
    out->write( |weekday_name(7)         = { weekday_name( 7 ) }| ).
    out->write( |traffic_action('green') = { traffic_action( `green` ) }| ).
  ENDMETHOD.

  METHOD classify_size.
    result = COND string( WHEN n < 10  THEN `small`
                          WHEN n < 100 THEN `medium`
                          ELSE              `large` ).
  ENDMETHOD.

  METHOD abs_diff.
    result = COND #( WHEN a > b THEN a - b ELSE b - a ).
  ENDMETHOD.

  METHOD weekday_name.
    result = SWITCH string( day
                            WHEN 1 THEN `Mon` WHEN 2 THEN `Tue` WHEN 3 THEN `Wed`
                            WHEN 4 THEN `Thu` WHEN 5 THEN `Fri` WHEN 6 THEN `Sat`
                            WHEN 7 THEN `Sun`
                            ELSE `?` ).
  ENDMETHOD.

  METHOD traffic_action.
    result = SWITCH string( to_upper( color )
                            WHEN `RED`    THEN `stop`
                            WHEN `GREEN`  THEN `go`
                            WHEN `YELLOW` THEN `slow`
                            ELSE `?` ).
  ENDMETHOD.
ENDCLASS.
