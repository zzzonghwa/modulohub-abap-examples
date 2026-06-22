CLASS zcl_modulo_expr01_value DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
    INTERFACES if_oo_adt_classrun.

    TYPES texts TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    TYPES numbers TYPE STANDARD TABLE OF i WITH EMPTY KEY.
    TYPES number_range TYPE RANGE OF i.

    "! 직원(원본 구조).
    TYPES:
      BEGIN OF employee,
        id     TYPE i,
        name   TYPE string,
        dept   TYPE string,
        salary TYPE i,
      END OF employee.

    "! 사람(대상 구조) — CORRESPONDING MAPPING 대상. name -> full_name 으로 이름이 다르다.
    TYPES:
      BEGIN OF person,
        id        TYPE i,
        full_name TYPE string,
        salary    TYPE i,
      END OF person.

    "! FOR i = 1 THEN i + 1 UNTIL i > n: 인덱스 기반 생성으로 1..n의 제곱을 만든다.
    "! @parameter n      | 상한
    "! @parameter result | "1,4,9,..." 형태의 제곱 문자열
    METHODS squares_up_to
      IMPORTING n             TYPE i
      RETURNING VALUE(result) TYPE string.

    "! VALUE #( BASE ... ): 기존 테이블을 보존하며 행을 덧붙인다.
    "! @parameter result | BASE 2행 + 추가 2행 = 4
    METHODS extend_with_base
      RETURNING VALUE(result) TYPE i.

    "! VALUE로 레인지 테이블을 만들고 IN으로 포함 여부를 본다.
    "! @parameter value  | 검사할 값
    "! @parameter result | 레인지(BT 10..20, EQ 5)에 포함되면 abap_true
    METHODS range_includes
      IMPORTING value         TYPE i
      RETURNING VALUE(result) TYPE abap_bool.

    "! CORRESPONDING ... MAPPING: 이름이 다른 컴포넌트를 매핑해 구조를 옮긴다.
    "! id·salary는 이름이 같아 자동 매핑, name은 full_name으로 매핑(MAPPING).
    "! @parameter result | "1 Kim 5000" 형태의 매핑 결과
    METHODS map_employee
      RETURNING VALUE(result) TYPE string.
ENDCLASS.


CLASS zcl_modulo_expr01_value IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== EXPR01 VALUE·FOR·CORRESPONDING ===` ).
    out->write( |squares_up_to(4)     = { squares_up_to( 4 ) }| ).
    out->write( |extend_with_base     = { extend_with_base( ) }| ).
    out->write( |range_includes(15)   = { range_includes( 15 ) }| ).
    out->write( |range_includes(7)    = { range_includes( 7 ) }| ).
    out->write( |map_employee         = { map_employee( ) }| ).
  ENDMETHOD.

  METHOD squares_up_to.
    DATA(squares) = VALUE texts( FOR i = 1 THEN i + 1 UNTIL i > n ( |{ i * i }| ) ).
    result = concat_lines_of( table = squares sep = `,` ).
  ENDMETHOD.

  METHOD extend_with_base.
    DATA(base) = VALUE numbers( ( 1 ) ( 2 ) ).
    " BASE는 base의 행을 유지한 채 새 행을 덧붙인다(미지정 시 base가 버려진다).
    DATA(extended) = VALUE numbers( BASE base ( 3 ) ( 4 ) ).
    result = lines( extended ).
  ENDMETHOD.

  METHOD range_includes.
    DATA(allowed) = VALUE number_range(
      ( sign = 'I' option = 'BT' low = 10 high = 20 )
      ( sign = 'I' option = 'EQ' low = 5 ) ).
    result = xsdbool( value IN allowed ).
  ENDMETHOD.

  METHOD map_employee.
    DATA(emp) = VALUE employee( id = 1 name = `Kim` dept = `IT` salary = 5000 ).
    " name -> full_name 매핑. dept는 person에 대상이 없어 자동 제외(EXCEPT로 명시도 가능).
    DATA(result_person) = CORRESPONDING person( emp MAPPING full_name = name ).
    result = |{ result_person-id } { result_person-full_name } { result_person-salary }|.
  ENDMETHOD.
ENDCLASS.
