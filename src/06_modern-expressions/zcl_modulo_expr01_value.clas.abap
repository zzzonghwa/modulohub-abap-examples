"! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
"!
"! 생성자 표현식 — VALUE·FOR·CORRESPONDING·NEW·FILTER. 노트(06-1)의 구문 형태를 자체완결로 시연한다.
"! - VALUE(B): 구조체·테이블·BASE 부분갱신·LET·중첩 deep·LINES OF STEP·OPTIONAL/DEFAULT·레인지.
"! - FOR(C): IN WHERE 컴프리헨션·UNTIL/WHILE 수치반복·INDEX INTO·다중 FOR·STEP 역방향·USING KEY.
"! - CORRESPONDING(D): 기본 vs MOVE-CORRESPONDING 초기화 차이·BASE·MAPPING·EXCEPT.
"! - E: VALUE+FOR+CORRESPONDING 구조 변환. F: NEW 데이터 객체+체이닝. G: FILTER sorted 키.
CLASS zcl_modulo_expr01_value DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
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
    TYPES employees TYPE STANDARD TABLE OF employee WITH EMPTY KEY.

    "! 사람(대상 구조) — CORRESPONDING MAPPING 대상. name -> full_name 으로 이름이 다르다.
    TYPES:
      BEGIN OF person,
        id        TYPE i,
        full_name TYPE string,
        salary    TYPE i,
      END OF person.
    TYPES people TYPE STANDARD TABLE OF person WITH EMPTY KEY.

    "! 좌표 — 중첩 deep VALUE 데모용.
    TYPES:
      BEGIN OF point,
        x TYPE i,
        y TYPE i,
      END OF point.

    "! 선분 — point 컴포넌트를 중첩으로 가진 deep 구조.
    TYPES:
      BEGIN OF segment,
        label TYPE string,
        start TYPE point,
        end   TYPE point,
      END OF segment.

    "! sorted 키를 가진 직원 테이블 — FILTER 소스(키 필수).
    TYPES employees_sorted TYPE SORTED TABLE OF employee WITH NON-UNIQUE KEY id.

    "! FOR i = 1 THEN i + 1 UNTIL i > n: 인덱스 기반 생성으로 1..n의 제곱을 만든다.
    "! UNTIL은 pre-test다 — 초기값이 이미 조건을 충족하면 0회 실행.
    "! @parameter n      | 상한
    "! @parameter result | "1,4,9,..." 형태의 제곱 문자열
    METHODS squares_up_to
      IMPORTING n             TYPE i
      RETURNING VALUE(result) TYPE string.

    "! FOR k = 1 WHILE k < n (THEN 생략): 수치 반복 변수는 WHILE에서도 +1 자동증가.
    "! ATF 책의 "WHILE은 자동증가 없음" 서술 정정 — SAP cheat-sheet 05가 자동증가를 실증.
    "! @parameter n      | 상한(미포함)
    "! @parameter result | 1..n-1 합
    METHODS while_auto_increment
      IMPORTING n             TYPE i
      RETURNING VALUE(result) TYPE i.

    "! VALUE #( BASE ... ): 기존 테이블을 보존하며 행을 덧붙인다(APPEND 효과).
    "! @parameter result | BASE 2행 + 추가 2행 = 4
    METHODS extend_with_base
      RETURNING VALUE(result) TYPE i.

    "! VALUE #( BASE struc comp = v ): 구조체 부분 갱신 — 미지정 컴포넌트는 기존 값 보존.
    "! BASE 없는 VALUE는 항상 먼저 초기화하므로 부분 갱신이 불가능한 점이 핵심 대조.
    "! @parameter raise_pct | 인상률(%)
    "! @parameter result    | salary만 인상되고 name·dept는 보존된 "name dept salary"
    METHODS raise_salary
      IMPORTING raise_pct     TYPE i
      RETURNING VALUE(result) TYPE string.

    "! 중첩 deep VALUE: 구조 컴포넌트(point)를 또 다른 VALUE로 인라인 채운다.
    "! @parameter result | "start(x,y)->end(x,y)" 좌표 문자열
    METHODS build_segment
      RETURNING VALUE(result) TYPE string.

    "! FOR i = 1 THEN i + 2: THEN 식으로 보폭 2의 수치 반복(STEP 2 효과).
    "! 노트 B-8/STEP은 라이브 7.54 통과지만 abaplint 파서가 STEP 토큰을 모르므로 THEN으로 등가 시연.
    "! @parameter result | 1..6에서 2칸씩 뽑은 "1,3,5"
    METHODS every_second
      RETURNING VALUE(result) TYPE string.

    "! 테이블 표현식 OPTIONAL/DEFAULT: 행이 없을 때 예외 대신 초기값/대체값.
    "! READ TABLE + TRY/CATCH의 모던 대체. OPTIONAL은 VALUE/REF operand 위치 전용.
    "! @parameter id     | 찾을 직원 id
    "! @parameter result | 있으면 그 이름, 없으면 'N/A'(DEFAULT)
    METHODS name_or_default
      IMPORTING id            TYPE i
      RETURNING VALUE(result) TYPE string.

    "! VALUE로 레인지 테이블을 만들고 IN으로 포함 여부를 본다(공통 컴포넌트 + 행별 차이).
    "! @parameter value  | 검사할 값
    "! @parameter result | 레인지(BT 10..20, EQ 5)에 포함되면 abap_true
    METHODS range_includes
      IMPORTING value         TYPE i
      RETURNING VALUE(result) TYPE abap_bool.

    "! FOR ... IN ... WHERE: 테이블 컴프리헨션. LOOP AT + APPEND의 표현식 대체.
    "! @parameter min_salary | 하한
    "! @parameter result     | salary가 하한 이상인 직원 수
    METHODS high_earners
      IMPORTING min_salary    TYPE i
      RETURNING VALUE(result) TYPE i.

    "! FOR i = lines THEN i - 1 UNTIL i < 1: 역방향 인덱스 순회로 테이블을 거꾸로 읽는다.
    "! 노트 C-11 STEP -1과 등가지만 abaplint 파서가 STEP을 모르므로 인덱스 표현식으로 시연.
    "! @parameter result | 직원 이름을 역순으로 이어붙인 "Choi,Park,Lee,Kim"
    METHODS names_reversed
      RETURNING VALUE(result) TYPE string.

    "! 다중 FOR(중첩 루프 효과): 두 테이블의 카르테시안 곱 행 수.
    "! @parameter result | 직원 수 x 부서 레이블 수
    METHODS cross_join_count
      RETURNING VALUE(result) TYPE i.

    "! FOR ... USING KEY: sorted 테이블을 키 순서로 순회해 첫 직원 id를 읽는다.
    "! @parameter result | id 정렬 시 첫 직원의 id
    METHODS first_by_key
      RETURNING VALUE(result) TYPE i.

    "! CORRESPONDING vs MOVE-CORRESPONDING — 초기화 차이가 핵심.
    "! 표현식 CORRESPONDING은 비매핑 컴포넌트를 초기화, 문장 MOVE-CORRESPONDING은 보존.
    "! @parameter result | "expr:<초기화값> move:<보존값>" 대조 문자열
    METHODS corresponding_vs_move
      RETURNING VALUE(result) TYPE string.

    "! CORRESPONDING ... MAPPING: 이름이 다른 컴포넌트를 매핑한다(name -> full_name).
    "! id·salary는 동명이라 자동 매핑, dept는 person에 없어 자동 제외된다.
    "! @parameter result | "1 Kim 5000" 형태의 매핑 결과
    METHODS map_employee
      RETURNING VALUE(result) TYPE string.

    "! CORRESPONDING #( BASE ( trg ) src ): MOVE-CORRESPONDING에 가까운 보존 매핑.
    "! BASE 인자는 반드시 괄호로 감싼다 — CORRESPONDING의 BASE 문법(VALUE와 다름).
    "! @parameter result | 기존 full_name 보존 + salary 갱신된 "full_name salary"
    METHODS map_with_base
      RETURNING VALUE(result) TYPE string.

    "! VALUE + FOR + CORRESPONDING: 구조가 다른 employees -> people 테이블 변환.
    "! @parameter result | 변환된 people 테이블 행 수
    METHODS convert_table
      RETURNING VALUE(result) TYPE i.

    "! NEW 데이터 객체 + -> 체이닝: 익명 데이터 객체 생성 후 즉시 컴포넌트 접근.
    "! CREATE DATA의 모던 대체. 참조 변수 사전 선언 불필요.
    "! @parameter result | NEW로 만든 직원의 "name salary"
    METHODS new_data_object
      RETURNING VALUE(result) TYPE string.

    "! FILTER ty( src WHERE key > v ): sorted 키 기반 필터(이진탐색). 소스 키 필수.
    "! @parameter min_id | 하한(초과)
    "! @parameter result | id가 하한 초과인 직원 수
    METHODS filter_by_id
      IMPORTING min_id        TYPE i
      RETURNING VALUE(result) TYPE i.

  PRIVATE SECTION.
    "! 데모용 직원 4건 샘플 데이터(id 오름차순).
    METHODS sample_employees
      RETURNING VALUE(result) TYPE employees.

    "! 부서 레이블 샘플(다중 FOR 데모용).
    METHODS sample_depts
      RETURNING VALUE(result) TYPE texts.
ENDCLASS.


CLASS zcl_modulo_expr01_value IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== EXPR01 VALUE·FOR·CORRESPONDING·NEW·FILTER ===` ).
    out->write( |squares_up_to(4)        = { squares_up_to( 4 ) }| ).
    out->write( |while_auto_increment(4) = { while_auto_increment( 4 ) }| ).
    out->write( |extend_with_base        = { extend_with_base( ) }| ).
    out->write( |raise_salary(10)        = { raise_salary( 10 ) }| ).
    out->write( |build_segment           = { build_segment( ) }| ).
    out->write( |every_second            = { every_second( ) }| ).
    out->write( |name_or_default(2)      = { name_or_default( 2 ) }| ).
    out->write( |name_or_default(99)     = { name_or_default( 99 ) }| ).
    out->write( |range_includes(15)      = { range_includes( 15 ) }| ).
    out->write( |range_includes(7)       = { range_includes( 7 ) }| ).
    out->write( |high_earners(4000)      = { high_earners( 4000 ) }| ).
    out->write( |names_reversed          = { names_reversed( ) }| ).
    out->write( |cross_join_count        = { cross_join_count( ) }| ).
    out->write( |first_by_key            = { first_by_key( ) }| ).
    out->write( |corresponding_vs_move   = { corresponding_vs_move( ) }| ).
    out->write( |map_employee            = { map_employee( ) }| ).
    out->write( |map_with_base           = { map_with_base( ) }| ).
    out->write( |convert_table           = { convert_table( ) }| ).
    out->write( |new_data_object         = { new_data_object( ) }| ).
    out->write( |filter_by_id(2)         = { filter_by_id( 2 ) }| ).
  ENDMETHOD.

  METHOD squares_up_to.
    " UNTIL은 pre-test: n=4면 i=1,2,3,4에서 평가 후 i=5에서 i>4 true로 종료.
    DATA(squares) = VALUE texts( FOR i = 1 THEN i + 1 UNTIL i > n ( |{ i * i }| ) ).
    result = concat_lines_of( table = squares sep = `,` ).
  ENDMETHOD.

  METHOD while_auto_increment.
    " THEN 생략 + 수치 반복변수 -> +1 자동증가. n=4면 k=1,2,3 -> 합 6.
    DATA(parts) = VALUE numbers( FOR k = 1 WHILE k < n ( k ) ).
    result = REDUCE i( INIT sum = 0 FOR part IN parts NEXT sum = sum + part ).
  ENDMETHOD.

  METHOD extend_with_base.
    DATA(base) = VALUE numbers( ( 1 ) ( 2 ) ).
    " BASE는 base의 행을 유지한 채 새 행을 덧붙인다(미지정 시 base가 버려진다).
    DATA(extended) = VALUE numbers( BASE base ( 3 ) ( 4 ) ).
    result = lines( extended ).
  ENDMETHOD.

  METHOD raise_salary.
    DATA(employee) = VALUE employee( id = 1 name = `Kim` dept = `IT` salary = 5000 ).
    " BASE로 employee를 기초에 올린 뒤 salary만 덮어쓴다. name·dept는 보존.
    " BASE가 없으면 VALUE는 먼저 초기화하므로 name·dept가 사라진다.
    DATA(raised) = VALUE employee(
      BASE employee
      salary = employee-salary + employee-salary * raise_pct / 100 ).
    result = |{ raised-name } { raised-dept } { raised-salary }|.
  ENDMETHOD.

  METHOD build_segment.
    " 중첩 deep: start·end 컴포넌트(point)를 또 다른 VALUE로 인라인 채운다.
    DATA(line) = VALUE segment(
      label = `L1`
      start = VALUE #( x = 0 y = 0 )
      end   = VALUE #( x = 3 y = 4 ) ).
    result = |{ line-label } ({ line-start-x },{ line-start-y })->| &&
             |({ line-end-x },{ line-end-y })|.
  ENDMETHOD.

  METHOD every_second.
    " THEN i + 2: 보폭 2 수치 반복 -> 1,3,5(STEP 2 효과). UNTIL은 pre-test.
    DATA(picked) = VALUE texts( FOR i = 1 THEN i + 2 UNTIL i > 6 ( |{ i }| ) ).
    result = concat_lines_of( table = picked sep = `,` ).
  ENDMETHOD.

  METHOD name_or_default.
    DATA(employees) = sample_employees( ).
    " 테이블 표현식이 행을 못 찾으면 DEFAULT 식의 결과(여기선 사람 이름)를 대입.
    DATA(found) = VALUE employee( employees[ id = id ] DEFAULT VALUE #( name = `N/A` ) ).
    result = found-name.
  ENDMETHOD.

  METHOD range_includes.
    " 공통 컴포넌트(sign·option)는 행 바깥, 행별 차이만 내부 괄호에.
    DATA(allowed) = VALUE number_range(
      sign = 'I'
      ( option = 'BT' low = 10 high = 20 )
      ( option = 'EQ' low = 5 ) ).
    result = xsdbool( value IN allowed ).
  ENDMETHOD.

  METHOD high_earners.
    DATA(employees) = sample_employees( ).
    " FOR ... IN ... WHERE: 조건에 맞는 행만 새 테이블로. 루프 변수는 표현식 안으로 스코프 제한.
    DATA(rich) = VALUE employees( FOR e IN employees WHERE ( salary >= min_salary ) ( e ) ).
    result = lines( rich ).
  ENDMETHOD.

  METHOD names_reversed.
    DATA(employees) = sample_employees( ).
    " 인덱스를 lines부터 1까지 감소시켜 역방향으로 행을 읽는다(STEP -1 등가).
    DATA(names) = VALUE texts(
      FOR position = lines( employees ) THEN position - 1 UNTIL position < 1
      ( |{ employees[ position ]-name }| ) ).
    result = concat_lines_of( table = names sep = `,` ).
  ENDMETHOD.

  METHOD cross_join_count.
    DATA(employees) = sample_employees( ).
    DATA(depts) = sample_depts( ).
    " 다중 FOR = 중첩 루프. employees(4) x depts(2) = 8 조합.
    DATA(pairs) = VALUE texts(
      FOR e IN employees
      FOR d IN depts ( |{ e-name }/{ d }| ) ).
    result = lines( pairs ).
  ENDMETHOD.

  METHOD first_by_key.
    DATA(employees) = CORRESPONDING employees_sorted( sample_employees( ) ).
    " USING KEY primary_key: 키 순서(id 오름차순)로 순회. 첫 행의 id를 취한다.
    DATA(ids) = VALUE numbers(
      FOR e IN employees USING KEY primary_key ( e-id ) ).
    result = ids[ 1 ].
  ENDMETHOD.

  METHOD corresponding_vs_move.
    DATA target_expr TYPE person.
    DATA target_move TYPE person.
    DATA(source) = VALUE employee( id = 1 name = `Kim` salary = 5000 ).

    " 두 타깃 모두 full_name을 미리 채워 둔다.
    target_expr = VALUE #( full_name = `OLD` ).
    target_move = VALUE #( full_name = `OLD` ).

    " 표현식: 결과 전체를 먼저 초기화 -> 비매핑 full_name이 사라진다(공백).
    target_expr = CORRESPONDING #( source ).
    " 문장: 비매핑 full_name을 보존 -> `OLD` 유지.
    MOVE-CORRESPONDING source TO target_move.

    result = |expr:[{ target_expr-full_name }] move:[{ target_move-full_name }]|.
  ENDMETHOD.

  METHOD map_employee.
    DATA(employee) = VALUE employee( id = 1 name = `Kim` dept = `IT` salary = 5000 ).
    " name -> full_name 매핑(MAPPING). dept는 person에 없어 자동 제외된다
    " (CORRESPONDING은 대상에 없는 소스 컬럼을 버린다 — EXCEPT는 대상에도 있는 컬럼에만 의미).
    DATA(result_person) = CORRESPONDING person(
      employee MAPPING full_name = name ).
    result = |{ result_person-id } { result_person-full_name } { result_person-salary }|.
  ENDMETHOD.

  METHOD map_with_base.
    DATA(source) = VALUE employee( id = 1 salary = 7000 ).
    DATA(target) = VALUE person( id = 1 full_name = `Kim` salary = 5000 ).
    " BASE ( target ): target을 기초에 올린 뒤 source 동명 컴포넌트(id·salary)를 덮어쓴다.
    " full_name은 source에 동명이 없어 보존된다.
    DATA(merged) = CORRESPONDING person( BASE ( target ) source ).
    result = |{ merged-full_name } { merged-salary }|.
  ENDMETHOD.

  METHOD convert_table.
    DATA(employees) = sample_employees( ).
    " 행마다 CORRESPONDING으로 구조 변환 후 people 행 생성.
    DATA(converted) = VALUE people(
      FOR e IN employees ( CORRESPONDING #( e MAPPING full_name = name ) ) ).
    result = lines( converted ).
  ENDMETHOD.

  METHOD new_data_object.
    " NEW로 익명 데이터 객체 생성 -> 참조. CREATE DATA의 모던 대체.
    DATA(employee_ref) = NEW employee( id = 9 name = `Lee` salary = 6000 ).
    " 생성 직후 -> 로 컴포넌트 접근(체이닝).
    result = |{ employee_ref->name } { employee_ref->salary }|.
  ENDMETHOD.

  METHOD filter_by_id.
    DATA(source) = CORRESPONDING employees_sorted( sample_employees( ) ).
    " sorted 키(id)로 이진탐색 필터. 소스에 sorted/hash 키가 반드시 있어야 한다.
    DATA(filtered) = FILTER employees_sorted( source WHERE id > min_id ).
    result = lines( filtered ).
  ENDMETHOD.

  METHOD sample_employees.
    result = VALUE #(
      ( id = 1 name = `Kim` dept = `IT` salary = 5000 )
      ( id = 2 name = `Lee` dept = `HR` salary = 3500 )
      ( id = 3 name = `Park` dept = `IT` salary = 4200 )
      ( id = 4 name = `Choi` dept = `FI` salary = 6100 ) ).
  ENDMETHOD.

  METHOD sample_depts.
    result = VALUE #( ( `IT` ) ( `HR` ) ).
  ENDMETHOD.
ENDCLASS.
