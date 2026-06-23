"! <p>ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.</p>
CLASS zcl_modulo_pf02_logic DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    TYPES number_list TYPE STANDARD TABLE OF i WITH EMPTY KEY.

    "! 빈 문자열인지(술어식 IS INITIAL + xsdbool). xsdbool은 c LENGTH 1
    "! (abap_bool 호환)을 돌려준다 — boolc(string) 대신 사용.
    METHODS is_blank
      IMPORTING text          TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

    "! 두 문자열 중 하나라도 비었는지(OR + IS INITIAL).
    METHODS either_blank
      IMPORTING first         TYPE string
                second        TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

    "! 값이 [low, high] 범위 안인지(복합 AND 비교).
    METHODS in_range
      IMPORTING value         TYPE i
                low           TYPE i
                high          TYPE i
      RETURNING VALUE(result) TYPE abap_bool.

    "! 테이블에 값이 있는지. 술어함수 line_exists가 READ TABLE+sy-subrc를
    "! 한 식으로 대체한다.
    METHODS contains_value
      IMPORTING numbers       TYPE number_list
                value         TYPE i
      RETURNING VALUE(result) TYPE abap_bool.

    "! 모든 원소가 양수인지. LOOP로 반례를 찾으면 즉시 abap_false.
    METHODS all_positive
      IMPORTING numbers       TYPE number_list
      RETURNING VALUE(result) TYPE abap_bool.

    "! 텍스트가 단어를 포함하는지. 술어함수 contains.
    METHODS mentions
      IMPORTING text          TYPE string
                word          TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

    "! 접두사로 시작하는지. 비교 연산자 CP(covers pattern, * 와일드카드).
    METHODS starts_with
      IMPORTING text          TYPE string
                prefix        TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

    "! 참조가 인스턴스를 가리키는지(술어식 IS BOUND).
    METHODS is_bound
      IMPORTING object        TYPE REF TO object
      RETURNING VALUE(result) TYPE abap_bool.
ENDCLASS.


CLASS zcl_modulo_pf02_logic IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== PF02 논리식/술어 ===` ).
    out->write( |is_blank( `` )       = { is_blank( `` ) }| ).
    out->write( |in_range( 5,1,10 )   = { in_range( value = 5 low = 1 high = 10 ) }| ).
    DATA(numbers) = VALUE number_list( ( 1 ) ( 2 ) ( 3 ) ).
    out->write( |contains_value( 2 )  = { contains_value( numbers = numbers value = 2 ) }| ).
    out->write( |all_positive         = { all_positive( numbers ) }| ).
    out->write( |mentions( abap )     = { mentions( text = `clean abap` word = `abap` ) }| ).
    out->write( |starts_with( abap )  = { starts_with( text = `abapGit` prefix = `abap` ) }| ).
    out->write( |is_bound( me )       = { is_bound( me ) }| ).
  ENDMETHOD.

  METHOD is_blank.
    result = xsdbool( text IS INITIAL ).
  ENDMETHOD.

  METHOD either_blank.
    result = xsdbool( first IS INITIAL OR second IS INITIAL ).
  ENDMETHOD.

  METHOD in_range.
    result = xsdbool( value >= low AND value <= high ).
  ENDMETHOD.

  METHOD contains_value.
    result = xsdbool( line_exists( numbers[ table_line = value ] ) ).
  ENDMETHOD.

  METHOD all_positive.
    result = abap_true.
    LOOP AT numbers INTO DATA(number).
      IF number <= 0.
        result = abap_false.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD mentions.
    result = xsdbool( contains( val = text sub = word ) ).
  ENDMETHOD.

  METHOD starts_with.
    result = xsdbool( text CP |{ prefix }*| ).
  ENDMETHOD.

  METHOD is_bound.
    result = xsdbool( object IS BOUND ).
  ENDMETHOD.
ENDCLASS.
