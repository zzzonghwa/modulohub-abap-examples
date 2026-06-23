"! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
"!
"! REDUCE — 축약(fold). 노트(06-3)의 구문 형태를 자체완결로 시연한다.
"! - 구조: REDUCE type( [LET] INIT 누적기 FOR 반복 NEXT 갱신 ). FOR는 필수(생성자 중 유일).
"! - 반복 유형: 조건 반복(FOR x = .. THEN .. UNTIL|WHILE)·테이블 반복(FOR wa IN itab).
"! - NEXT 복합 할당: = / += / -= / *= / /= / &&=.
"! - 누적기: 단일·다중(결과는 항상 첫 누적기)·구조·INIT x TYPE dtype.
"! - 빌드: VALUE #( BASE acc ( ... ) )로 테이블 누적. WHERE·STEP·FROM TO·FOR GROUPS.
CLASS zcl_modulo_expr03_reduce DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    TYPES numbers TYPE STANDARD TABLE OF i WITH EMPTY KEY.
    TYPES texts TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    "! 평균 결과 타입 — 메서드 시그니처는 완전 타입이 필요하므로 제네릭 p 대신 별칭을 쓴다.
    TYPES average TYPE p LENGTH 8 DECIMALS 2.
    "! 항공사 코드(c2) — seats_of_carrier 파라미터가 c1로 잡혀 절단되는 것을 막는다.
    TYPES carrier_key TYPE c LENGTH 2.

    "! REDUCE(조건 반복): 1*2*...*n. FOR x = 1 THEN x+1 UNTIL — NEXT에 곱셈 누적.
    "! @parameter n      | 상한(0이면 1)
    "! @parameter result | n 팩토리얼
    METHODS factorial
      IMPORTING n             TYPE i
      RETURNING VALUE(result) TYPE i.

    "! REDUCE(테이블 반복 += ): 정수 합. NEXT 복합 할당 += 로 임시변수 없이 누적.
    "! @parameter values | 합산할 정수들
    "! @parameter result | 합계(빈 입력이면 0)
    METHODS sum_of
      IMPORTING values        TYPE numbers
      RETURNING VALUE(result) TYPE i.

    "! REDUCE(문자열 빌드): 구분자로 단어를 잇는다. 첫 원소엔 구분자를 안 붙인다(COND).
    "! @parameter separator | 구분자
    "! @parameter result    | "ABAP{sep}is{sep}fun"
    METHODS join_with
      IMPORTING separator     TYPE string
      RETURNING VALUE(result) TYPE string.

    "! REDUCE(복합 할당 &&= ): 샘플 정수를 쉼표로 이어 CSV 문자열로 축약.
    "! 선행 쉼표를 피하려고 COND로 첫 원소를 구분. ATF의 대표 use case(comma-delimited).
    "! @parameter result | "1,2,3,4,5"
    METHODS to_csv
      RETURNING VALUE(result) TYPE string.

    "! REDUCE(다중 누적기): 구조 누적기로 합계와 개수를 한 번에 모은다. 결과는 첫 누적기.
    "! @parameter result | "sum/count" 형태(예: "15/5")
    METHODS sum_and_count
      RETURNING VALUE(result) TYPE string.

    "! REDUCE(조건 누적): NEXT에 COND를 두어 짝수만 센다. COND #의 타입은 INIT 누적기에서 추론.
    "! @parameter result | 샘플의 짝수 개수
    METHODS count_evens
      RETURNING VALUE(result) TYPE i.

    "! REDUCE(최댓값): NEXT COND로 직전 최댓값과 비교해 큰 값을 유지(주장 27.3).
    "! @parameter values | 비교할 정수들
    "! @parameter result | 최댓값(빈 입력이면 0)
    METHODS max_of
      IMPORTING values        TYPE numbers
      RETURNING VALUE(result) TYPE i.

    "! REDUCE(최장 문자열): strlen 비교로 가장 긴 단어를 유지(주장 27.2).
    "! @parameter result | 샘플 단어 중 최장 문자열
    METHODS longest_word
      RETURNING VALUE(result) TYPE string.

    "! REDUCE(테이블 빌드): 짝수만 골라 제곱한 테이블을 VALUE BASE로 누적(주장 27.4).
    "! NEXT 안 COND로 분기 — 짝수면 행을 추가, 홀수면 누적기를 그대로 둔다.
    "! @parameter result | 짝수의 제곱 테이블(2,4 -> 4,16)
    METHODS even_squares
      RETURNING VALUE(result) TYPE numbers.

    "! REDUCE(테이블 반복 + WHERE 필터): 반복원에 WHERE를 붙여 LOOP AT ... WHERE 의미론으로
    "! 필터한 뒤 좌석을 합산(주장 27.5). 구조 테이블이라 컴포넌트로 WHERE 조건을 건다.
    "! @parameter carrier_code | 합산할 항공사 코드
    "! @parameter result       | 해당 항공사 좌석 합
    METHODS seats_of_carrier
      IMPORTING carrier_code  TYPE carrier_key
      RETURNING VALUE(result) TYPE i.

    "! REDUCE(조건 반복 UNTIL, THEN 생략): 1..n 삼각수. numeric은 THEN 생략 시 +1 자동증가.
    "! UNTIL은 pre-test — 시작 전 조건 평가, 초기 조건 충족 시 0회(주장 9).
    "! @parameter n      | 상한
    "! @parameter result | 1+2+...+n
    METHODS triangular
      IMPORTING n             TYPE i
      RETURNING VALUE(result) TYPE i.

    "! REDUCE(조건 반복 WHILE, THEN 생략): n 미만 카운트. numeric은 WHILE도 +1 자동증가(주장 8).
    "! WHILE도 pre-test이므로 n<=1이면 0회.
    "! @parameter n      | 상한(미만)
    "! @parameter result | 1..n-1 의 개수
    METHODS count_while
      IMPORTING n             TYPE i
      RETURNING VALUE(result) TYPE i.

    "! REDUCE(STEP 보폭): FOR i = 1 ... STEP 2 로 홀수 인덱스만 밟아 합산(주장 9a).
    "! @parameter n      | 상한(포함)
    "! @parameter result | 1,3,5,... <= n 의 합
    METHODS sum_odd_steps
      IMPORTING n             TYPE i
      RETURNING VALUE(result) TYPE i.

    "! REDUCE(INIT x TYPE dtype): rhs 없이 타입만 선언해 초기값으로 시작(주장 5a).
    "! 결과 타입을 명시하되 초기 rhs를 생략하는 형식. p 누적기로 평균 계산.
    "! @parameter values | 평균낼 정수들
    "! @parameter result | 평균(소수 2자리, 빈 입력이면 0)
    METHODS average_of
      IMPORTING values        TYPE numbers
      RETURNING VALUE(result) TYPE average.

    "! REDUCE(FOR GROUPS): 그룹별 합을 한 REDUCE 안에서 모은다(주장 14·28).
    "! "carrier:sum" 라인을 carrier 순으로 잇는다. GROUP BY + 그룹 멤버 REDUCE 중첩.
    "! @parameter result | 예: "AA=700;LH=460"
    METHODS seats_per_carrier
      RETURNING VALUE(result) TYPE string.

  PRIVATE SECTION.
    "! carrier별 좌석. FOR GROUPS 그룹 집계 데모의 행 타입.
    TYPES:
      BEGIN OF seat_row,
        carrier TYPE c LENGTH 2,
        seats   TYPE i,
      END OF seat_row.
    TYPES seat_rows TYPE STANDARD TABLE OF seat_row WITH EMPTY KEY.

    "! 데모용 정수 1..5.
    METHODS sample_numbers
      RETURNING VALUE(result) TYPE numbers.

    "! 데모용 단어들(길이 차이로 최장 문자열 데모).
    METHODS sample_words
      RETURNING VALUE(result) TYPE texts.

    "! 데모용 carrier·좌석(그룹 집계용).
    METHODS sample_seats
      RETURNING VALUE(result) TYPE seat_rows.
ENDCLASS.


CLASS zcl_modulo_expr03_reduce IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== EXPR03 REDUCE ===` ).
    out->write( |factorial(5)        = { factorial( 5 ) }| ).
    out->write( |sum_of(1..5)        = { sum_of( sample_numbers( ) ) } (+=)| ).
    out->write( |join_with('-')      = { join_with( `-` ) }| ).
    out->write( |to_csv              = { to_csv( ) } (&&=)| ).
    out->write( |sum_and_count       = { sum_and_count( ) } (다중 누적기)| ).
    out->write( |count_evens         = { count_evens( ) }| ).
    out->write( |max_of(1..5)        = { max_of( sample_numbers( ) ) }| ).
    out->write( |longest_word        = { longest_word( ) }| ).
    out->write( |even_squares        = { lines( even_squares( ) ) }행 (VALUE BASE)| ).
    out->write( |seats_of_carrier(AA) = { seats_of_carrier( 'AA' ) } (FOR WHERE)| ).
    out->write( |triangular(5)       = { triangular( 5 ) } (UNTIL pre-test)| ).
    out->write( |count_while(4)      = { count_while( 4 ) } (WHILE +1)| ).
    out->write( |sum_odd_steps(9)    = { sum_odd_steps( 9 ) } (STEP 2)| ).
    out->write( |average_of(1..5)    = { average_of( sample_numbers( ) ) } (INIT TYPE)| ).
    out->write( |seats_per_carrier   = { seats_per_carrier( ) } (FOR GROUPS)| ).
  ENDMETHOD.

  METHOD factorial.
    result = REDUCE i( INIT product = 1
                       FOR i = 1 THEN i + 1 UNTIL i > n
                       NEXT product = product * i ).
  ENDMETHOD.

  METHOD sum_of.
    " 복합 할당 += : 별도 임시변수 없이 누적기를 갱신.
    result = REDUCE i( INIT total = 0
                       FOR n IN values
                       NEXT total += n ).
  ENDMETHOD.

  METHOD join_with.
    DATA(words) = VALUE texts( ( `ABAP` ) ( `is` ) ( `fun` ) ).
    result = REDUCE string( INIT line = ``
                            FOR word IN words
                            NEXT line = COND #( WHEN line IS INITIAL THEN word
                                                ELSE |{ line }{ separator }{ word }| ) ).
  ENDMETHOD.

  METHOD to_csv.
    " &&= : 문자열 이어 붙이기 복합 할당. 첫 원소엔 쉼표를 안 붙여 선행 구분자를 피한다.
    result = REDUCE string( INIT csv = ``
                            FOR n IN sample_numbers( )
                            NEXT csv &&= COND #( WHEN csv IS INITIAL THEN |{ n }|
                                                 ELSE |,{ n }| ) ).
  ENDMETHOD.

  METHOD sum_and_count.
    TYPES:
      BEGIN OF stat,
        sum   TYPE i,
        count TYPE i,
      END OF stat.
    DATA(accumulated) = REDUCE stat( INIT acc = VALUE stat( )
                                     FOR n IN sample_numbers( )
                                     NEXT acc-sum   = acc-sum + n
                                          acc-count = acc-count + 1 ).
    result = |{ accumulated-sum }/{ accumulated-count }|.
  ENDMETHOD.

  METHOD count_evens.
    result = REDUCE i( INIT c = 0
                       FOR n IN sample_numbers( )
                       NEXT c = COND #( WHEN n MOD 2 = 0 THEN c + 1 ELSE c ) ).
  ENDMETHOD.

  METHOD max_of.
    result = REDUCE i( INIT max = 0
                       FOR n IN values
                       NEXT max = COND #( WHEN n > max THEN n ELSE max ) ).
  ENDMETHOD.

  METHOD longest_word.
    result = REDUCE string( INIT longest = ``
                            FOR word IN sample_words( )
                            NEXT longest = COND #( WHEN strlen( word ) > strlen( longest )
                                                   THEN word ELSE longest ) ).
  ENDMETHOD.

  METHOD even_squares.
    " VALUE BASE로 누적 테이블 확장 + NEXT 안 COND로 짝수만 추가.
    result = REDUCE numbers( INIT squares = VALUE numbers( )
                             FOR n IN sample_numbers( )
                             NEXT squares = COND #( WHEN n MOD 2 = 0
                                                    THEN VALUE #( BASE squares ( n * n ) )
                                                    ELSE squares ) ).
  ENDMETHOD.

  METHOD seats_of_carrier.
    " 테이블 반복에 WHERE 필터 — 조건에 맞는 행만 돌며 좌석을 합산.
    DATA(rows) = sample_seats( ).
    result = REDUCE i( INIT total = 0
                       FOR row IN rows WHERE ( carrier = carrier_code )
                       NEXT total += row-seats ).
  ENDMETHOD.

  METHOD triangular.
    " THEN 생략 -> numeric은 +1 자동증가. n<1이면 빈 삼각수 0(가드), n>=1은 UNTIL로 1..n 합산.
    result = COND #( WHEN n < 1 THEN 0
                     ELSE REDUCE i( INIT sum = 0
                                    FOR i = 1 UNTIL i > n
                                    NEXT sum += i ) ).
  ENDMETHOD.

  METHOD count_while.
    " WHILE도 numeric이면 THEN 생략 시 +1 자동증가. pre-test이므로 n<=1이면 0회.
    result = REDUCE i( INIT c = 0
                       FOR i = 1 WHILE i < n
                       NEXT c += 1 ).
  ENDMETHOD.

  METHOD sum_odd_steps.
    " STEP 2 : 1,3,5,... 보폭 2로 밟는다. 양수 STEP은 순방향.
    result = REDUCE i( INIT sum = 0
                       FOR i = 1 THEN i + 2 UNTIL i > n
                       NEXT sum += i ).
  ENDMETHOD.

  METHOD average_of.
    " INIT x TYPE dtype : rhs 없이 타입만 선언해 누적기를 시작한다(주장 5a). 합을 소수 타입으로 모은다.
    DATA(total) = REDUCE average( INIT sum TYPE average
                                  FOR n IN values
                                  NEXT sum = sum + n ).
    DATA(item_count) = lines( values ).
    result = COND #( WHEN item_count > 0 THEN total / item_count ELSE 0 ).
  ENDMETHOD.

  METHOD seats_per_carrier.
    " FOR GROUPS : carrier로 그룹핑하고 그룹 멤버를 다시 REDUCE해 그룹 합을 구한다.
    DATA(rows) = sample_seats( ).
    result = REDUCE string(
      INIT report = ``
      FOR GROUPS carrier_group OF row IN rows
        GROUP BY row-carrier ASCENDING
      LET group_sum = REDUCE i( INIT s = 0
                                FOR member IN GROUP carrier_group
                                NEXT s += member-seats ) IN
      NEXT report = COND #( WHEN report IS INITIAL
                            THEN |{ carrier_group }={ group_sum }|
                            ELSE |{ report };{ carrier_group }={ group_sum }| ) ).
  ENDMETHOD.

  METHOD sample_numbers.
    result = VALUE #( ( 1 ) ( 2 ) ( 3 ) ( 4 ) ( 5 ) ).
  ENDMETHOD.

  METHOD sample_words.
    result = VALUE #( ( `go` ) ( `ABAP` ) ( `is` ) ( `clean` ) ).
  ENDMETHOD.

  METHOD sample_seats.
    result = VALUE #(
      ( carrier = 'AA' seats = 380 )
      ( carrier = 'AA' seats = 320 )
      ( carrier = 'LH' seats = 280 )
      ( carrier = 'LH' seats = 180 ) ).
  ENDMETHOD.
ENDCLASS.
