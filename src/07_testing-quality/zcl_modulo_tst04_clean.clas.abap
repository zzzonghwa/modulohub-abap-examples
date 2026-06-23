"! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
"!
"! Clean ABAP 규칙 모음(코드로 시연). 노트 07-4의 소절을 자체완결로 실행 가능한 형태로 보인다.
"! - 불리언(주장 6~8): abap_bool 타입·abap_true/false 비교·xsdbool로 조건 결과 대입.
"! - 조건문(주장 9~12, A4-3): 긍정 조건·IS NOT·predicative call·CASE/SWITCH·복합 조건 분해.
"! - 상수(주장 A2-1·A2-4·A2-3): 매직 넘버 대신 명명 상수·BEGIN OF 그룹·ENUM 열거.
"! - 메서드(주장 18~24): 가드 절(fail fast)·불리언 입력 회피(메서드 분리)·RETURNING·RESULT 명명.
"! - 생성 표현식(주장 39): VALUE/FOR/COND/SWITCH/REDUCE/CORRESPONDING로 절차형 루프 제거.
CLASS zcl_modulo_tst04_clean DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    "! 요일 한 건. 생성 표현식 데모의 공통 행 타입(서술적 이름, 헝가리안 접두사 없음).
    TYPES:
      BEGIN OF day_entry,
        index TYPE i,
        hours TYPE i,
      END OF day_entry.
    TYPES day_entries TYPE STANDARD TABLE OF day_entry WITH EMPTY KEY.

    "! 주문 한 건. CORRESPONDING·REDUCE 데모용 원본 행 타입.
    TYPES:
      BEGIN OF order_line,
        sku      TYPE string,
        quantity TYPE i,
        price    TYPE i,
      END OF order_line.
    TYPES order_lines TYPE STANDARD TABLE OF order_line WITH EMPTY KEY.

    "! CORRESPONDING 대상 타입 — 원본의 부분 집합(amount는 별도 계산).
    TYPES:
      BEGIN OF order_summary,
        sku    TYPE string,
        amount TYPE i,
      END OF order_summary.
    TYPES order_summaries TYPE STANDARD TABLE OF order_summary WITH EMPTY KEY.

    "! ENUM(주장 A2-3, since 7.51): 타입 안전 열거. 상수 인터페이스 구현보다 우선한다.
    TYPES:
      BEGIN OF ENUM traffic_light,
        unknown,
        stop,
        caution,
        go,
      END OF ENUM traffic_light.

    "! 주장 6·8 — 불리언은 abap_bool로, 조건 결과는 xsdbool로 대입한다.
    "! @parameter day    | 1=Mon .. 7=Sun
    "! @parameter result | 토·일이면 abap_true
    METHODS is_weekend
      IMPORTING day           TYPE i
      RETURNING VALUE(result) TYPE abap_bool.

    "! 주장 11 — predicative method call이 가능하도록 abap_bool을 반환하는 술어 메서드.
    "! @parameter text   | 검사할 문자열
    "! @parameter result | 공백을 제거하고도 내용이 있으면 abap_true
    METHODS has_content
      IMPORTING text          TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

    "! 주장 12 — IF 사슬 대신 SWITCH로 배타적 분기. 회원 등급 -> 할인율(%).
    "! @parameter membership | 'GOLD'/'SILVER'(그 외 0)
    "! @parameter result     | 할인율(%)
    METHODS discount_rate
      IMPORTING membership    TYPE string
      RETURNING VALUE(result) TYPE i.

    "! 주장 A2-3 — ENUM 값으로 분기(CASE). 신호등 색을 행동 라벨로 변환한다.
    "! @parameter light  | traffic_light 열거값
    "! @parameter result | 'DRIVE'/'SLOW'/'HALT', 미정이면 공백
    METHODS light_action
      IMPORTING light         TYPE traffic_light
      RETURNING VALUE(result) TYPE string.

    "! 주장 24·A6-1 — 가드 절(early return)로 들여쓰기를 낮추고 빈 입력을 빠르게 처리.
    "! @parameter sentence | 문장
    "! @parameter result   | 첫 단어(공백 기준), 빈 입력이면 공백
    METHODS first_word
      IMPORTING sentence      TYPE string
      RETURNING VALUE(result) TYPE string.

    "! 주장 21 — 불리언 입력 파라미터를 피해 메서드를 분리(update_and_save 변형).
    "! 저장까지 수행하는 변형. 여기서는 합계에 영구 누계를 더해 반환한다.
    "! @parameter amount | 더할 금액
    "! @parameter result | 누계 반영 후 총액
    METHODS add_and_commit
      IMPORTING amount        TYPE i
      RETURNING VALUE(result) TYPE i.

    "! 주장 21 — 위 메서드의 짝. 저장하지 않는 변형(누계를 건드리지 않는다).
    "! @parameter amount | 더할 금액
    "! @parameter result | 누계와 무관하게 amount만 반영한 임시 총액
    METHODS add_without_commit
      IMPORTING amount        TYPE i
      RETURNING VALUE(result) TYPE i.

    "! 주장 A4-3 — 복합 조건을 명명 불리언으로 분해해 의도를 드러낸다.
    "! @parameter seats     | 좌석 수
    "! @parameter cancelled | 취소 여부
    "! @parameter result    | 운항 가능(좌석 충분 AND 미취소)이면 abap_true
    METHODS is_bookable
      IMPORTING seats         TYPE i
                cancelled     TYPE abap_bool
      RETURNING VALUE(result) TYPE abap_bool.

    "! 주장 39 — VALUE + FOR로 절차형 루프 없이 평일 근무 행을 생성한다.
    "! @parameter result | 1..7 중 평일(1~5)만 hours=8로 채운 테이블
    METHODS workdays
      RETURNING VALUE(result) TYPE day_entries.

    "! 주장 39 — REDUCE로 합계를 누적한다(절차형 LOOP/SUM 대체).
    "! @parameter lines  | 주문 행
    "! @parameter result | quantity*price 합계
    METHODS total_amount
      IMPORTING lines         TYPE order_lines
      RETURNING VALUE(result) TYPE i.

    "! 주장 39 — CORRESPONDING으로 공통 필드를 매핑하고 amount는 FOR로 계산한다.
    "! @parameter lines  | 주문 행
    "! @parameter result | sku + (quantity*price) 요약
    METHODS summarize
      IMPORTING lines         TYPE order_lines
      RETURNING VALUE(result) TYPE order_summaries.

  PRIVATE SECTION.
    "! 주장 A2-1 — 매직 넘버 대신 의미를 담은 명명 상수(주말 시작 인덱스 = 토요일).
    CONSTANTS first_weekend_day TYPE i VALUE 6.
    "! 주장 A2-1 — 평일 마지막 인덱스(금요일).
    CONSTANTS last_workday TYPE i VALUE 5.

    "! 주장 A2-4 — 관련 할인율을 BEGIN OF ... END OF 구조로 묶어 의미 그룹을 드러낸다.
    CONSTANTS:
      BEGIN OF discount_percent,
        gold   TYPE i VALUE 20,
        silver TYPE i VALUE 10,
        none   TYPE i VALUE 0,
      END OF discount_percent.

    "! add_and_commit이 갱신하는 영구 누계(주장 A5-3 — stateful 책임을 한곳에 둔다).
    DATA committed_total TYPE i.

    "! 데모용 주문 3건 샘플 데이터.
    METHODS sample_order
      RETURNING VALUE(result) TYPE order_lines.
ENDCLASS.


CLASS zcl_modulo_tst04_clean IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== TST04 Clean ABAP 규칙 ===` ).
    out->write( |is_weekend(6)            = { is_weekend( first_weekend_day ) }| ).
    out->write( |is_weekend(3)            = { is_weekend( 3 ) }| ).
    out->write( |has_content(' abap ')    = { has_content( ` abap ` ) } (predicative)| ).
    out->write( |discount_rate('GOLD')    = { discount_rate( `GOLD` ) }| ).
    out->write( |light_action(go)         = { light_action( go ) } (ENUM+CASE)| ).
    out->write( |light_action(unknown)    = '{ light_action( unknown ) }' (ENUM 미정값)| ).
    out->write( |first_word('hello abap') = { first_word( `hello abap` ) }| ).
    out->write( |is_bookable(120,false)   = { is_bookable( seats = 120 cancelled = abap_false ) }| ).
    out->write( |workdays count           = { lines( workdays( ) ) } (VALUE+FOR)| ).
    out->write( |total_amount             = { total_amount( sample_order( ) ) } (REDUCE)| ).
    out->write( |summarize lines          = { lines( summarize( sample_order( ) ) ) } (CORRESPONDING)| ).
  ENDMETHOD.

  METHOD is_weekend.
    " 주장 8 — IF/ELSE 4줄 블록 대신 xsdbool로 abap_bool을 한 줄에 대입한다.
    result = xsdbool( day = first_weekend_day OR day = 7 ).
  ENDMETHOD.

  METHOD has_content.
    " 주장 7 — initial 비교 대신 의도를 명시한 비교. condense로 공백만 있는 입력도 걸러낸다.
    " IS INITIAL은 데이터 오브젝트에만 쓸 수 있다(함수 결과엔 불가) -> 변수로 받아 검사.
    DATA(condensed) = condense( text ).
    result = xsdbool( condensed IS NOT INITIAL ).
  ENDMETHOD.

  METHOD discount_rate.
    " 주장 12 — 배타적 분기는 SWITCH. 값은 명명 상수 그룹에서 가져온다(주장 A2-1).
    result = SWITCH i( membership
                       WHEN `GOLD`   THEN discount_percent-gold
                       WHEN `SILVER` THEN discount_percent-silver
                       ELSE discount_percent-none ).
  ENDMETHOD.

  METHOD light_action.
    " 주장 A2-3 — ENUM 값으로 CASE 분기. 컴파일러가 열거 타입을 검사한다.
    result = SWITCH string( light
                            WHEN go      THEN `DRIVE`
                            WHEN caution THEN `SLOW`
                            WHEN stop    THEN `HALT`
                            ELSE space ).
  ENDMETHOD.

  METHOD first_word.
    " 주장 A6-1 — 가드 절로 빈 입력을 즉시 반환(fail fast). 본문 들여쓰기를 낮춘다.
    IF sentence IS INITIAL.
      RETURN.
    ENDIF.
    SPLIT sentence AT ` ` INTO TABLE DATA(words).
    result = words[ 1 ].
  ENDMETHOD.

  METHOD add_and_commit.
    " 주장 21 — 불리언 플래그(do_save) 대신 메서드 이름으로 의도를 표현한다.
    committed_total += amount.
    result = committed_total.
  ENDMETHOD.

  METHOD add_without_commit.
    " 주장 21 — 짝 메서드. 누계 상태를 바꾸지 않는다.
    result = committed_total + amount.
  ENDMETHOD.

  METHOD is_bookable.
    " 주장 A4-3 — 긴 복합 조건을 명명 불리언으로 분해해 의도를 드러낸다.
    DATA(has_free_seats) = xsdbool( seats > 0 ).
    DATA(is_active) = xsdbool( cancelled = abap_false ).
    " 주장 9 — 긍정 조건 결합. IS NOT INITIAL 대신 명시적 abap_true 비교.
    result = xsdbool( has_free_seats = abap_true AND is_active = abap_true ).
  ENDMETHOD.

  METHOD workdays.
    " 주장 39 — VALUE + FOR로 1..5(평일)만 hours=8 행을 생성. 절차형 LOOP 불필요.
    result = VALUE #( FOR day = 1 WHILE day <= last_workday
                      ( index = day hours = 8 ) ).
  ENDMETHOD.

  METHOD total_amount.
    " 주장 39 — REDUCE로 합계 누적. 누계 변수 타입은 결과 타입과 같게 둔다.
    result = REDUCE i( INIT sum = 0
                       FOR line IN lines
                       NEXT sum = sum + line-quantity * line-price ).
  ENDMETHOD.

  METHOD summarize.
    " 주장 39 — CORRESPONDING으로 공통 필드(sku)를 매핑하고 amount는 BASE 위에 덮어쓴다.
    result = VALUE #( FOR line IN lines
                      ( VALUE #( BASE CORRESPONDING #( line )
                                 amount = line-quantity * line-price ) ) ).
  ENDMETHOD.

  METHOD sample_order.
    result = VALUE #(
      ( sku = `A-100` quantity = 2 price = 50 )
      ( sku = `B-200` quantity = 3 price = 30 )
      ( sku = `C-300` quantity = 1 price = 75 ) ).
  ENDMETHOD.
ENDCLASS.
