CLASS zcl_modulo_df01_types DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
    INTERFACES if_oo_adt_classrun.

    "! 독립(standalone) 타입. TYPES로 한 번 정의하면 여러 데이터 객체가
    "! 재사용한다. DATA로 인라인 정의한 타입은 그 객체에만 bound 된다.
    TYPES count_value TYPE i.
    TYPES count_list  TYPE STANDARD TABLE OF count_value WITH EMPTY KEY.

    "! 리스트가 비었는지 판정한다. 술어식 IS INITIAL.
    "! @parameter counts | 카운트들
    "! @parameter result | 비었으면 abap_true
    METHODS is_empty
      IMPORTING counts        TYPE count_list
      RETURNING VALUE(result) TYPE abap_bool.

    "! 최댓값. 본문은 인라인 선언 DATA(x)(7.40+)로 작업 변수를 사용 시점에
    "! 선언하는 모던 스타일을 보인다.
    "! @parameter counts  | 카운트들(빈 리스트는 0)
    "! @parameter highest | 최댓값
    METHODS highest_count
      IMPORTING counts         TYPE count_list
      RETURNING VALUE(highest) TYPE count_value.

    "! 최솟값(빈 리스트는 0).
    "! @parameter counts | 카운트들
    "! @parameter lowest | 최솟값
    METHODS lowest_count
      IMPORTING counts        TYPE count_list
      RETURNING VALUE(lowest) TYPE count_value.

    "! 합계. REDUCE 생성 표현식으로 누적한다.
    "! @parameter counts | 카운트들
    "! @parameter total  | 합계
    METHODS total_count
      IMPORTING counts       TYPE count_list
      RETURNING VALUE(total) TYPE count_value.

    "! 평균. 빈 리스트는 0으로 나눌 수 없으므로 가드로 예외를 던진다.
    "! @parameter counts  | 카운트들(비어 있으면 안 됨)
    "! @parameter average | 산술 평균(소수 보존)
    "! @raising cx_parameter_invalid_range | 빈 리스트일 때
    METHODS average_count
      IMPORTING counts          TYPE count_list
      RETURNING VALUE(average)  TYPE decfloat34
      RAISING   cx_parameter_invalid_range.
ENDCLASS.


CLASS zcl_modulo_df01_types IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== DF01 타입 시스템 ===` ).
    DATA(counts) = VALUE count_list( ( 3 ) ( 7 ) ( 2 ) ).
    out->write( |counts        = 3, 7, 2| ).
    out->write( |highest_count = { highest_count( counts ) }| ).
    out->write( |lowest_count  = { lowest_count( counts ) }| ).
    out->write( |total_count   = { total_count( counts ) }| ).
    out->write( |is_empty( )   = { is_empty( VALUE #( ) ) }| ).
    TRY.
        out->write( |average_count = { average_count( counts ) }| ).
        average_count( VALUE #( ) ).
      CATCH cx_parameter_invalid_range.
        out->write( `average_count( empty ) -> 가드 예외 발생(정상)` ).
    ENDTRY.
  ENDMETHOD.

  METHOD is_empty.
    result = xsdbool( counts IS INITIAL ).
  ENDMETHOD.

  METHOD highest_count.
    " DATA(current)는 LOOP 위치에서 타입이 정적으로 결정되는 인라인 선언
    LOOP AT counts INTO DATA(current).
      IF current > highest.
        highest = current.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD lowest_count.
    LOOP AT counts INTO DATA(current).
      IF sy-tabix = 1 OR current < lowest.
        lowest = current.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD total_count.
    total = REDUCE count_value( INIT sum TYPE count_value
                                FOR count IN counts
                                NEXT sum = sum + count ).
  ENDMETHOD.

  METHOD average_count.
    IF counts IS INITIAL.
      RAISE EXCEPTION TYPE cx_parameter_invalid_range.
    ENDIF.
    DATA(total) = total_count( counts ).
    average = CONV decfloat34( total ) / lines( counts ).
  ENDMETHOD.
ENDCLASS.
