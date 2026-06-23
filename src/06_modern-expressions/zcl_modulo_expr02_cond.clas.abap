"! <p>ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.</p>
"! <p>COND·SWITCH — 조건부 표현식의 폭. 구문 형태를 자체완결로 시연한다.</p>
"! <ul>
"! <li>COND: 논리식 분기. WHEN을 순서대로 평가, 첫 참의 THEN 결과를 반환(short-circuit).</li>
"! <li>SWITCH: 한 피연산자의 값 일치 분기(CASE의 표현식판). WHEN 뒤는 리터럴/상수만.</li>
"! <li>ELSE 생략 시 결과 타입의 초기값 반환. ELSE/THEN 자리에 THROW로 인라인 예외도 가능.</li>
"! <li>LET ... IN: 표현식 안에서만 사는 임시 변수(값 1회 계산 후 여러 WHEN에서 재사용).</li>
"! <li>type 결정: 좌변 타입이 완전 결정되면 #, 결과 타입을 고정하려면 명시 타입(text30 등).</li>
"! </ul>
CLASS zcl_modulo_expr02_cond DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    TYPES label30 TYPE c LENGTH 30.
    "! 파트너 기능 코드(SAP PARVW와 동일한 길이 2의 char).
    TYPES partner_function TYPE c LENGTH 2.

    "! COND(범위 분류): 논리식으로 크기 구간을 가른다(첫 참 WHEN 반환).
    "! @parameter number | 분류할 값
    "! @parameter result | <10 'small', <100 'medium', 그 외 'large'
    METHODS classify_size
      IMPORTING number        TYPE i
      RETURNING VALUE(result) TYPE string.

    "! COND(2분기, #): 부호 없는 차이. 좌변 타입이 i라 #로 추론.
    "! @parameter first  | 값 1
    "! @parameter second | 값 2
    "! @parameter result | |first - second|
    METHODS abs_diff
      IMPORTING first         TYPE i
                second        TYPE i
      RETURNING VALUE(result) TYPE i.

    "! COND(두 변수 복합 조건): IF/ELSE로 재작성 없이 WHEN 한 줄로 조건을 확장한다.
    "! @parameter sanity | 0..100 정신력 백분율
    "! @parameter day    | 요일 이름(영문)
    "! @parameter result | 두 필드를 동시에 평가한 기분 라벨
    METHODS monster_mood
      IMPORTING sanity        TYPE i
                day           TYPE string
      RETURNING VALUE(result) TYPE string.

    "! COND(LET ... IN): 비싼/부수효과 호출을 LET으로 1회만 계산해 여러 WHEN이 공유한다.
    "! @parameter now    | 현재 시각(HHMMSS). 호출자가 주입해 결정적으로 테스트한다.
    "! @parameter result | 시간대 인사말
    METHODS greeting_at
      IMPORTING now           TYPE t
      RETURNING VALUE(result) TYPE string.

    "! COND(abap_bool, ELSE 생략): ELSE가 없으면 초기값 abap_false를 조용히 반환한다.
    "! Clean ABAP은 이 형태를 xsdbool의 secondary로만 권장(여기선 동작 시연용).
    "! @parameter text   | 검사할 문자열
    "! @parameter result | 비어있지 않으면 abap_true, 비면 abap_false(초기값)
    METHODS has_content
      IMPORTING text          TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

    "! COND(명시 타입 text30): 결과 타입을 c(30)으로 고정 — 모든 THEN이 그 타입으로 변환된다.
    "! @parameter code   | 등급 코드
    "! @parameter result | 코드별 라벨(c30로 고정, 우측 공백 패딩)
    METHODS grade_label
      IMPORTING code          TYPE i
      RETURNING VALUE(result) TYPE label30.

    "! COND(ELSE THROW): 분모 0이면 값 대신 도메인 예외(lcx_bad_input)를 인라인으로 raise.
    "! lcx_bad_input은 cx_dynamic_check라 RAISING 선언 없이 전파된다(호출부가 CATCH).
    "! @parameter dividend | 피제수
    "! @parameter divisor  | 제수
    "! @parameter result   | dividend / divisor(반올림)
    METHODS safe_divide
      IMPORTING dividend      TYPE i
                divisor       TYPE i
      RETURNING VALUE(result) TYPE i.

    "! SWITCH(정확 값 매칭): 요일 번호 -> 이름. ELSE로 범위 밖 처리.
    "! @parameter day    | 1=Mon .. 7=Sun
    "! @parameter result | 요일 이름, 범위 밖이면 '?'
    METHODS weekday_name
      IMPORTING day           TYPE i
      RETURNING VALUE(result) TYPE string.

    "! SWITCH(문자열 매칭): 신호색 -> 행동. operand 자리에서 to_upper로 대소문자 정규화.
    "! @parameter color  | 'RED'/'GREEN'/'YELLOW'(대소문자 무관)
    "! @parameter result | 'stop'/'go'/'slow', 미일치 '?'
    METHODS traffic_action
      IMPORTING color         TYPE string
      RETURNING VALUE(result) TYPE string.

    "! SWITCH(WHEN ... OR ...): 복수 리터럴을 OR로 묶어 한 WHEN에서 처리(7.54 확정).
    "! 파트너 기능 코드 -> 역할. CASE WHEN ... OR ...과 동일 의미.
    "! @parameter parvw  | 파트너 기능(AG/RE/RG/WE 등)
    "! @parameter result | 'sold-to'/'ship-to'/'other'
    METHODS partner_role
      IMPORTING parvw         TYPE partner_function
      RETURNING VALUE(result) TYPE string.

    "! SWITCH(ELSE 생략): 미일치 시 결과 타입(string)의 초기값(공백)을 반환한다.
    "! @parameter flag   | 단일 문자 플래그
    "! @parameter result | 'X' -> 'on', ' ' -> 'off', 그 외 초기값('')
    METHODS flag_state
      IMPORTING flag          TYPE c
      RETURNING VALUE(result) TYPE string.

    "! SWITCH(루프 + ELSE THROW): 일치하는 코드까지 누적하다 미지원 코드를 만나면 예외로 탈출.
    "! ELSE 뒤 예외가 잡히면 루프가 종료된다.
    "! @parameter codes  | 처리할 코드 목록
    "! @parameter result | 첫 미지원 코드 직전까지의 가중치 합
    METHODS sum_until_unknown
      IMPORTING codes         TYPE stringtab
      RETURNING VALUE(result) TYPE i.
ENDCLASS.


CLASS zcl_modulo_expr02_cond IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== EXPR02 COND·SWITCH ===` ).
    out->write( |classify_size(50)        = { classify_size( 50 ) }| ).
    out->write( |abs_diff(3,8)            = { abs_diff( first = 3 second = 8 ) }| ).
    out->write( |monster_mood(1,Tuesday)  = { monster_mood( sanity = 1 day = `Tuesday` ) }| ).
    out->write( |greeting_at(073000)      = { greeting_at( '073000' ) } (LET IN)| ).
    out->write( |has_content('')          = { has_content( `` ) } (ELSE 생략 -> 초기값)| ).
    out->write( |grade_label(2)           = { grade_label( 2 ) } (명시 타입 text30)| ).
    out->write( |weekday_name(7)          = { weekday_name( 7 ) }| ).
    out->write( |traffic_action('green')  = { traffic_action( `green` ) }| ).
    out->write( |partner_role('WE')       = { partner_role( 'WE' ) } (WHEN OR)| ).
    out->write( |flag_state('?')          = { flag_state( '?' ) } (ELSE 생략 -> 공백)| ).
    out->write( |sum_until_unknown        = { sum_until_unknown( VALUE #( ( `A` ) ( `B` ) ( `Z` ) ( `A` ) ) ) }| ).
    TRY.
        out->write( |safe_divide(10,0)        = { safe_divide( dividend = 10 divisor = 0 ) }| ).
      CATCH lcx_bad_input INTO DATA(error).
        out->write( |safe_divide(10,0)        -> 예외: { error->get_reason( ) } (ELSE THROW)| ).
      CATCH cx_root.
        " 방어적 catch-all — 인클루드/클래스 동일성 문제로 위 CATCH가 빗나가도 F9 덤프를 막는다.
        out->write( |safe_divide(10,0)        -> 예외 잡음 (division by zero, COND ELSE THROW)| ).
    ENDTRY.
  ENDMETHOD.

  METHOD classify_size.
    " COND는 WHEN을 순서대로 평가하고 첫 참의 THEN을 반환한다(이후 WHEN은 미평가).
    result = COND string( WHEN number < 10  THEN `small`
                          WHEN number < 100 THEN `medium`
                          ELSE                   `large` ).
  ENDMETHOD.

  METHOD abs_diff.
    " 좌변 result가 i로 결정되므로 #로 결과 타입을 추론한다.
    result = COND #( WHEN first > second THEN first - second ELSE second - first ).
  ENDMETHOD.

  METHOD monster_mood.
    " 두 변수(sanity, day)의 복합 논리식 — SWITCH/CASE는 단일 변수만 보므로 COND가 필요하다.
    result = COND string(
      WHEN sanity = 100                      THEN `perfectly sane`
      WHEN sanity = 1 AND day = `Tuesday`    THEN `having an off day`
      WHEN sanity < 20                       THEN `losing it`
      ELSE                                        `coping` ).
  ENDMETHOD.

  METHOD greeting_at.
    " LET ... IN: hour를 1회 계산해 모든 WHEN이 공유 — WHEN마다 substring을 반복하지 않는다.
    result = COND string( LET hour = now(2) IN
                          WHEN hour < '12' THEN `Good morning`
                          WHEN hour < '18' THEN `Good afternoon`
                          WHEN hour < '22' THEN `Good evening`
                          ELSE                  `Good night` ).
  ENDMETHOD.

  METHOD has_content.
    " ELSE 생략: abap_false가 결과 타입 초기값이라 빈 문자열에서 조용히 false가 된다.
    result = COND abap_bool( WHEN text IS NOT INITIAL THEN abap_true ).
  ENDMETHOD.

  METHOD grade_label.
    " 명시 타입 text30(label30): 모든 THEN 결과가 c(30)으로 변환·우측 공백 패딩된다.
    result = COND label30( WHEN code = 1 THEN `A`
                           WHEN code = 2 THEN `B`
                           WHEN code = 3 THEN `C`
                           ELSE               `?` ).
  ENDMETHOD.

  METHOD safe_divide.
    " ELSE THROW: 값을 만들 수 없는 분기에서 RAISE EXCEPTION TYPE와 동일하게 예외를 발생.
    result = COND #( WHEN divisor <> 0 THEN dividend / divisor
                     ELSE THROW lcx_bad_input( reason = `division by zero` ) ).
  ENDMETHOD.

  METHOD weekday_name.
    result = SWITCH string( day
                            WHEN 1 THEN `Mon` WHEN 2 THEN `Tue` WHEN 3 THEN `Wed`
                            WHEN 4 THEN `Thu` WHEN 5 THEN `Fri` WHEN 6 THEN `Sat`
                            WHEN 7 THEN `Sun`
                            ELSE `?` ).
  ENDMETHOD.

  METHOD traffic_action.
    " operand는 general expression position — to_upper( ) 호출 결과를 그대로 검사한다.
    result = SWITCH string( to_upper( color )
                            WHEN `RED`    THEN `stop`
                            WHEN `GREEN`  THEN `go`
                            WHEN `YELLOW` THEN `slow`
                            ELSE `?` ).
  ENDMETHOD.

  METHOD partner_role.
    " WHEN ... OR ...: 복수 리터럴을 한 WHEN에 묶는다(CASE WHEN ... OR ...과 동일 의미).
    result = SWITCH string( parvw
                            WHEN 'AG' THEN `sold-to`
                            WHEN 'WE' OR 'W1' THEN `ship-to`
                            WHEN 'RE' OR 'RG' THEN `bill-to`
                            ELSE `other` ).
  ENDMETHOD.

  METHOD flag_state.
    " ELSE 생략: 미일치 시 결과 타입 string의 초기값('')을 반환한다.
    result = SWITCH string( flag
                            WHEN 'X' THEN `on`
                            WHEN ' ' THEN `off` ).
  ENDMETHOD.

  METHOD sum_until_unknown.
    " 루프 + SWITCH ELSE THROW: 미지원 코드를 만나면 예외로 루프를 탈출한다.
    TRY.
        LOOP AT codes INTO DATA(code).
          result = result + SWITCH i( code
                                      WHEN `A` THEN 1
                                      WHEN `B` THEN 2
                                      ELSE THROW lcx_bad_input( ) ).
        ENDLOOP.
      CATCH lcx_bad_input.
        " 첫 미지원 코드에서 result는 직전까지 누적된 값으로 고정된다.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
