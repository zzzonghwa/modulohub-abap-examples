"! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
CLASS zcl_modulo_it05_ctorexpr DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    "! 사원 한 명. 생성자식 데모의 공통 행 타입.
    TYPES salary TYPE p LENGTH 13 DECIMALS 2.
    TYPES:
      BEGIN OF employee,
        id     TYPE i,
        name   TYPE string,
        dept   TYPE string,
        salary TYPE salary,
        active TYPE abap_bool,
      END OF employee.
    TYPES employees TYPE STANDARD TABLE OF employee WITH DEFAULT KEY.
    TYPES names TYPE STANDARD TABLE OF string WITH DEFAULT KEY.

    "! FILTER가 쓸 보조 정렬 키(by_dept)를 가진 사원 테이블.
    TYPES:
      emp_filterable TYPE STANDARD TABLE OF employee
        WITH EMPTY KEY
        WITH NON-UNIQUE SORTED KEY by_dept COMPONENTS dept.

    "! CORRESPONDING ... MAPPING의 대상 구조(필드명이 다름).
    TYPES:
      BEGIN OF person_card,
        full_name TYPE string,
        team      TYPE string,
      END OF person_card.
    TYPES person_cards TYPE STANDARD TABLE OF person_card WITH DEFAULT KEY.

    "! VALUE + FOR(테이블 comprehension): 사원 테이블에서 이름 테이블을 만든다.
    "! @parameter result | 전체 이름을 콤마로 이은 문자열
    METHODS map_names
      RETURNING VALUE(result) TYPE string.

    "! FOR ... WHERE: 조건(active)에 맞는 행만 comprehension에 포함한다.
    "! @parameter result | active 사원 이름을 콤마로 이은 문자열
    METHODS names_where_active
      RETURNING VALUE(result) TYPE string.

    "! REDUCE: 누적 변수로 합계를 접는다(fold).
    "! @parameter result | 전체 급여 합
    METHODS reduce_total_salary
      RETURNING VALUE(result) TYPE salary.

    "! REDUCE: 최댓값을 접어 구한다.
    "! @parameter result | 최고 급여
    METHODS reduce_max_salary
      RETURNING VALUE(result) TYPE salary.

    "! FILTER ... USING KEY ... WHERE: 키 기반으로 부서 행만 추려 센다.
    "! @parameter for_dept | 부서명
    "! @parameter result   | 해당 부서 사원 수
    METHODS filter_by_dept
      IMPORTING for_dept      TYPE string
      RETURNING VALUE(result) TYPE i.

    "! CORRESPONDING ... MAPPING: 다른 이름의 필드로 매핑해 테이블을 변환한다.
    "! @parameter result | 첫 카드의 full_name(= 첫 사원 name)
    METHODS correspond_to_cards
      RETURNING VALUE(result) TYPE string.

    "! 중첩 FOR: 두 리스트의 조합(데카르트 곱) 테이블을 만든다.
    "! @parameter result | 2 x 3 조합 행 수(6)
    METHODS nested_for
      RETURNING VALUE(result) TYPE i.

  PRIVATE SECTION.
    "! 데모용 사원 6명(부서 3종) 샘플 데이터.
    METHODS sample
      RETURNING VALUE(result) TYPE employees.

    "! 문자열 테이블을 콤마로 잇는다.
    METHODS join
      IMPORTING parts         TYPE names
      RETURNING VALUE(result) TYPE string.
ENDCLASS.


CLASS zcl_modulo_it05_ctorexpr IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== IT05 모던 생성자식 ===` ).
    out->write( |map_names           = { map_names( ) }| ).
    out->write( |names_where_active  = { names_where_active( ) }| ).
    out->write( |reduce_total_salary = { reduce_total_salary( ) }| ).
    out->write( |reduce_max_salary   = { reduce_max_salary( ) }| ).
    out->write( |filter_by_dept(ENG) = { filter_by_dept( `ENG` ) }| ).
    out->write( |correspond_to_cards = { correspond_to_cards( ) }| ).
    out->write( |nested_for          = { nested_for( ) }| ).
  ENDMETHOD.

  METHOD map_names.
    DATA(emps) = sample( ).
    result = join( VALUE names( FOR e IN emps ( e-name ) ) ).
  ENDMETHOD.

  METHOD names_where_active.
    DATA(emps) = sample( ).
    result = join( VALUE names( FOR e IN emps WHERE ( active = abap_true ) ( e-name ) ) ).
  ENDMETHOD.

  METHOD reduce_total_salary.
    DATA(emps) = sample( ).
    result = REDUCE salary( INIT sum = CONV salary( 0 ) FOR e IN emps NEXT sum = sum + e-salary ).
  ENDMETHOD.

  METHOD reduce_max_salary.
    DATA(emps) = sample( ).
    result = REDUCE salary( INIT max = CONV salary( 0 )
                            FOR e IN emps
                            NEXT max = COND #( WHEN e-salary > max THEN e-salary ELSE max ) ).
  ENDMETHOD.

  METHOD filter_by_dept.
    DATA(emps) = CONV emp_filterable( sample( ) ).
    result = lines( FILTER #( emps USING KEY by_dept WHERE dept = for_dept ) ).
  ENDMETHOD.

  METHOD correspond_to_cards.
    DATA(emps) = sample( ).
    DATA(cards) = CORRESPONDING person_cards( emps MAPPING full_name = name team = dept ).
    result = cards[ 1 ]-full_name.
  ENDMETHOD.

  METHOD nested_for.
    DATA(grid) = VALUE names( FOR x IN VALUE names( ( `A` ) ( `B` ) )
                              FOR y IN VALUE names( ( `1` ) ( `2` ) ( `3` ) )
                              ( |{ x }{ y }| ) ).
    result = lines( grid ).
  ENDMETHOD.

  METHOD join.
    result = REDUCE string( INIT text = ``
                            FOR part IN parts
                            NEXT text = COND #( WHEN text IS INITIAL THEN part
                                                ELSE |{ text },{ part }| ) ).
  ENDMETHOD.

  METHOD sample.
    result = VALUE #(
      ( id = 1 name = `Kim`  dept = `ENG` salary = '50.00' active = abap_true )
      ( id = 2 name = `Lee`  dept = `ENG` salary = '60.00' active = abap_true )
      ( id = 3 name = `Park` dept = `SAL` salary = '40.00' active = abap_false )
      ( id = 4 name = `Choi` dept = `SAL` salary = '55.00' active = abap_true )
      ( id = 5 name = `Ahn`  dept = `HR`  salary = '45.00' active = abap_true )
      ( id = 6 name = `Yoon` dept = `ENG` salary = '70.00' active = abap_false ) ).
  ENDMETHOD.
ENDCLASS.
