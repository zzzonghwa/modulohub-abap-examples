CLASS zcl_modulo_expr03_reduce DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
    "!
    "! REDUCE: 반복으로 값을 누적해 하나의 결과로 줄인다(fold).
    "! INIT으로 누적기 초기화, FOR로 반복원, NEXT로 누적 갱신. 구조 누적기로 다중 필드도 가능.
    INTERFACES if_oo_adt_classrun.

    TYPES numbers TYPE STANDARD TABLE OF i WITH EMPTY KEY.
    TYPES texts TYPE STANDARD TABLE OF string WITH EMPTY KEY.

    "! REDUCE(인덱스 기반): 1*2*...*n.
    "! @parameter n      | 상한(0이면 1)
    "! @parameter result | n 팩토리얼
    METHODS factorial
      IMPORTING n             TYPE i
      RETURNING VALUE(result) TYPE i.

    "! REDUCE(문자열 빌드): 구분자로 단어를 잇는다. 첫 원소엔 구분자를 안 붙인다(COND).
    "! @parameter separator | 구분자
    "! @parameter result    | "ABAP{sep}is{sep}fun"
    METHODS join_with
      IMPORTING separator     TYPE string
      RETURNING VALUE(result) TYPE string.

    "! REDUCE(다중 누적기): 구조 누적기로 합계와 개수를 한 번에 모은다.
    "! @parameter result | "sum/count" 형태(예: "15/5")
    METHODS sum_and_count
      RETURNING VALUE(result) TYPE string.

    "! REDUCE(조건 누적): NEXT에 COND를 두어 짝수만 센다.
    "! @parameter result | 샘플의 짝수 개수
    METHODS count_evens
      RETURNING VALUE(result) TYPE i.

  PRIVATE SECTION.
    "! 데모용 정수 1..5.
    METHODS sample_numbers
      RETURNING VALUE(result) TYPE numbers.
ENDCLASS.


CLASS zcl_modulo_expr03_reduce IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== EXPR03 REDUCE ===` ).
    out->write( |factorial(5)    = { factorial( 5 ) }| ).
    out->write( |join_with('-')  = { join_with( `-` ) }| ).
    out->write( |sum_and_count   = { sum_and_count( ) }| ).
    out->write( |count_evens     = { count_evens( ) }| ).
  ENDMETHOD.

  METHOD factorial.
    result = REDUCE i( INIT product = 1
                       FOR i = 1 THEN i + 1 UNTIL i > n
                       NEXT product = product * i ).
  ENDMETHOD.

  METHOD join_with.
    DATA(words) = VALUE texts( ( `ABAP` ) ( `is` ) ( `fun` ) ).
    result = REDUCE string( INIT line = ``
                            FOR word IN words
                            NEXT line = COND #( WHEN line IS INITIAL THEN word
                                                ELSE |{ line }{ separator }{ word }| ) ).
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

  METHOD sample_numbers.
    result = VALUE #( ( 1 ) ( 2 ) ( 3 ) ( 4 ) ( 5 ) ).
  ENDMETHOD.
ENDCLASS.
