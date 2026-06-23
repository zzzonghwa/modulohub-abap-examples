"! <p>ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.</p>
"! <p>생성 연산자 4종 — 변환·캐스팅·참조·무손실의 구문 형태를 자체완결로 시연한다.</p>
"! <ul>
"! <li>CONV(C): 명시 변환. 완전 타입 필수(제네릭 거부), # 추론, 테이블 종류 변환, 계산 타입 함정.</li>
"! <li>CAST(K): 참조 캐스팅. 다운캐스트+체이닝, IS INSTANCE OF 가드, ->* 역참조, CAST+NEW.</li>
"! <li>REF(R):  데이터/객체 참조 생성. REF #( ), 테이블 행 참조 DEFAULT, 객체 참조 복사.</li>
"! <li>EXACT(E): 무손실 변환·계산. 손실(잘림·반올림)이면 예외 — CONV는 조용히 자르고 반올림한다.</li>
"! </ul>
CLASS zcl_modulo_expr04_conv DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    "! 완전(complete) packed 타입 — 제네릭 p는 생성 연산자가 거부하므로 길이·소수점을 고정한다.
    TYPES amount TYPE p LENGTH 8 DECIMALS 2.
    "! 3글자 문자 타입 — EXACT 잘림 데모용.
    TYPES char3 TYPE c LENGTH 3.

    "! CONV: 문자열을 정수로 명시 변환. CONV i( text ) 한 식으로 헬퍼 변수+MOVE를 대체한다.
    "! @parameter text   | 숫자 문자열
    "! @parameter result | 정수 값
    METHODS to_integer
      IMPORTING text          TYPE string
      RETURNING VALUE(result) TYPE i.

    "! CONV: 완전 타입(amount = p LENGTH 8 DECIMALS 2)으로 변환. 제네릭 p는 컴파일 거부.
    "! @parameter text   | 소수 문자열
    "! @parameter result | amount(소수 2자리)로 변환된 값
    METHODS conv_to_amount
      IMPORTING text          TYPE string
      RETURNING VALUE(result) TYPE amount.

    "! CONV #( ): 대상 타입을 컨텍스트(여기선 RETURNING 타입)에서 추론한다.
    "! @parameter packed | 변환 원본(amount)
    "! @parameter result | i로 추론·변환된 값(소수부 반올림)
    METHODS conv_infer_hash
      IMPORTING packed        TYPE amount
      RETURNING VALUE(result) TYPE i.

    "! CONV 테이블 종류 변환: SORTED TABLE을 STANDARD TABLE 타입으로 변환.
    "! 라인 타입이 같아도 테이블 종류·키가 다르면 직접 대입 불가 — CONV로 해결한다.
    "! @parameter result | 변환된 STANDARD 테이블의 행 수
    METHODS conv_table_kind
      RETURNING VALUE(result) TYPE i.

    "! CONV 계산 타입 함정: 정수 나눗셈 1/5=0 vs 소수 나눗셈 1.0/5=0.2 (×10 정수로 비교).
    "! @parameter result | 정수식 결과×10 + 소수식 결과×10 = 0 + 2 = 2
    METHODS conv_calc_type
      RETURNING VALUE(result) TYPE i.

    "! CAST: 기반 참조가 가리키는 하위형(lcl_dog)으로 다운캐스트해 고유 메서드를 체이닝 호출한다.
    "! @parameter result | lcl_dog 고유 메서드 fetch의 결과
    METHODS cast_dog_fetch
      RETURNING VALUE(result) TYPE string.

    "! CAST 가드: IS INSTANCE OF로 점검 후 다운캐스트. 점검 실패면 빈 문자열(예외 회피).
    "! @parameter make_dog | abap_true면 lcl_dog 생성(다운캐스트 성공), false면 lcl_animal.
    "! @parameter result   | 다운캐스트 가능하면 fetch 결과, 아니면 공백
    METHODS cast_guarded
      IMPORTING make_dog      TYPE abap_bool
      RETURNING VALUE(result) TYPE string.

    "! CAST ->*: 제네릭 데이터 참조를 특정 타입으로 역참조해 직접 쓴다(헬퍼 변수 없이).
    "! @parameter result | 참조를 통해 기록한 문자열 값
    METHODS cast_deref_write
      RETURNING VALUE(result) TYPE string.

    "! CAST + NEW: 부모 타입 변수를 선언하며 하위 클래스 인스턴스를 동시에 생성한다.
    "! @parameter result | 생성된 인스턴스의 sound( )
    METHODS cast_new_combo
      RETURNING VALUE(result) TYPE string.

    "! REF: 변수의 데이터 참조를 만들어 ->* 로 원본을 직접 바꾼다. GET REFERENCE OF의 식 형태.
    "! @parameter result | 참조를 통해 10 -> +5 한 값(15)
    METHODS bump_via_ref
      RETURNING VALUE(result) TYPE i.

    "! REF 테이블 행 참조: REF #( itab[ index ] OPTIONAL )로 없는 행은 초기(null) 참조를 얻는다.
    "! @parameter index  | 읽을 행 번호(1-based)
    "! @parameter result | 해당 행의 값, 행이 없으면 -1(null 참조 가드)
    METHODS ref_table_row
      IMPORTING index         TYPE i
      RETURNING VALUE(result) TYPE i.

    "! REF 객체 참조: REF #( oref )는 객체 참조도 복사한다 — 같은 인스턴스를 가리킨다.
    "! @parameter result | 복사한 참조로 호출한 sound( )
    METHODS ref_object
      RETURNING VALUE(result) TYPE string.

    "! EXACT: 무손실이면 변환, 손실이면 예외 -> -1. CONV는 같은 입력을 조용히 반올림한다.
    "! @parameter value  | 변환할 십진수
    "! @parameter result | 정수(무손실)일 때 그 값, 손실이면 -1
    METHODS exact_int
      IMPORTING value         TYPE decfloat34
      RETURNING VALUE(result) TYPE i.

    "! EXACT 잘림 가드 vs CONV: char3에 4글자를 넣을 때 EXACT는 DATA_LOSS 예외, CONV는 조용히 자른다.
    "! @parameter result | |EXACT결과/CONV결과| 형태 — EXACT 예외면 EXACT 자리는 '!!!'
    METHODS exact_vs_conv_truncate
      RETURNING VALUE(result) TYPE string.

    "! EXACT 무손실 계산: 0.25는 소수 2자리에 정확히 담겨 성공, 1/3은 반올림 필요 -> ROUNDING.
    "! @parameter divisor | 나눗셈 제수(분자 1.0 고정). 4면 0.25(성공), 3이면 0.333...(예외).
    "! @parameter result  | 무손실이면 amount 값, 반올림 손실이면 -1
    METHODS exact_calc
      IMPORTING divisor       TYPE i
      RETURNING VALUE(result) TYPE amount.

  PRIVATE SECTION.
    "! CAST·REF 객체 데모용 행 타입.
    TYPES:
      BEGIN OF score,
        name  TYPE string,
        value TYPE i,
      END OF score.
    "! SORTED TABLE — CONV 테이블 종류 변환의 원본.
    TYPES sorted_scores TYPE SORTED TABLE OF score WITH UNIQUE KEY name.
    "! STANDARD TABLE — CONV 변환의 대상 타입.
    TYPES standard_scores TYPE STANDARD TABLE OF score WITH EMPTY KEY.
    "! 정수 테이블 — REF 테이블 행 참조 데모용.
    TYPES numbers TYPE STANDARD TABLE OF i WITH EMPTY KEY.
ENDCLASS.


CLASS zcl_modulo_expr04_conv IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== EXPR04 CONV·CAST·REF·EXACT ===` ).
    out->write( `-- CONV --` ).
    out->write( |to_integer('42')       = { to_integer( `42` ) }| ).
    out->write( |conv_to_amount('3.14')  = { conv_to_amount( `3.14` ) }| ).
    out->write( |conv_infer_hash(2.6)    = { conv_infer_hash( '2.6' ) } (#로 i 추론)| ).
    out->write( |conv_table_kind         = { conv_table_kind( ) } (SORTED->STANDARD)| ).
    out->write( |conv_calc_type          = { conv_calc_type( ) } (정수0+소수2)| ).
    out->write( `-- CAST --` ).
    out->write( |cast_dog_fetch          = { cast_dog_fetch( ) }| ).
    out->write( |cast_guarded(X)         = { cast_guarded( abap_true ) }| ).
    out->write( |cast_guarded( )         = { cast_guarded( abap_false ) } (가드로 예외 회피)| ).
    out->write( |cast_deref_write        = { cast_deref_write( ) } (->* 역참조 쓰기)| ).
    out->write( |cast_new_combo          = { cast_new_combo( ) }| ).
    out->write( `-- REF --` ).
    out->write( |bump_via_ref            = { bump_via_ref( ) }| ).
    out->write( |ref_table_row(2)        = { ref_table_row( 2 ) }| ).
    out->write( |ref_table_row(9)        = { ref_table_row( 9 ) } (없는 행 -> OPTIONAL null)| ).
    out->write( |ref_object              = { ref_object( ) }| ).
    out->write( `-- EXACT --` ).
    out->write( |exact_int(4)            = { exact_int( '4' ) }| ).
    out->write( |exact_int(4.5) 손실      = { exact_int( '4.5' ) }| ).
    out->write( |exact_vs_conv_truncate  = { exact_vs_conv_truncate( ) }| ).
    out->write( |exact_calc(4)           = { exact_calc( 4 ) } (0.25 무손실)| ).
    out->write( |exact_calc(3) 반올림     = { exact_calc( 3 ) } (-1)| ).
  ENDMETHOD.

  METHOD to_integer.
    " 문자열 -> 정수. CONV로 변환 타입을 명시한다.
    result = CONV i( text ).
  ENDMETHOD.

  METHOD conv_to_amount.
    " 완전 타입 amount(p LENGTH 8 DECIMALS 2)로 변환. 제네릭 p는 컴파일러가 거부한다.
    result = CONV amount( text ).
  ENDMETHOD.

  METHOD conv_infer_hash.
    " CONV #( ): RETURNING 타입 i를 컨텍스트로 보고 추론·변환한다. 2.6 -> 3(반올림).
    result = CONV #( packed ).
  ENDMETHOD.

  METHOD conv_table_kind.
    " 라인 타입이 같아도 SORTED vs STANDARD는 직접 대입 불가 — CONV로 테이블 종류를 변환한다.
    DATA(sorted) = VALUE sorted_scores(
      ( name = `ann` value = 1 )
      ( name = `ben` value = 2 ) ).
    DATA(standard) = CONV standard_scores( sorted ).
    result = lines( standard ).
  ENDMETHOD.

  METHOD conv_calc_type.
    " 정수 나눗셈: 1/5는 두 정수 리터럴 -> 계산 타입 i -> 0. ×10 해도 0.
    DATA(integer_division) = CONV i( 1 / 5 ) * 10.
    " 소수 나눗셈: 1.0/5는 계산 타입이 decfloat -> 0.2. ×10 -> 2.
    DATA(decimal_division) = CONV i( CONV decfloat34( '1.0' ) / 5 * 10 ).
    result = integer_division + decimal_division.
  ENDMETHOD.

  METHOD cast_dog_fetch.
    " 업캐스트: lcl_dog 객체를 기반 참조(lcl_animal)에 담는다(넓히기, 항상 안전).
    DATA(animal) = CAST lcl_animal( NEW lcl_dog( ) ).
    " 다운캐스트: CAST로 하위형 참조를 얻어 lcl_dog 고유 메서드를 체이닝 호출한다(좁히기).
    result = CAST lcl_dog( animal )->fetch( ).
  ENDMETHOD.

  METHOD cast_guarded.
    " 동적 타입에 따라 기반 참조를 만든다 — make_dog면 lcl_dog, 아니면 lcl_animal.
    DATA(animal) = COND #( WHEN make_dog = abap_true
                           THEN CAST lcl_animal( NEW lcl_dog( ) )
                           ELSE NEW lcl_animal( ) ).
    " 다운캐스트 가능성을 IS INSTANCE OF로 먼저 점검해야 CX_SY_MOVE_CAST_ERROR를 피한다.
    IF animal IS INSTANCE OF lcl_dog.
      result = CAST lcl_dog( animal )->fetch( ).
    ENDIF.
  ENDMETHOD.

  METHOD cast_deref_write.
    " 제네릭 데이터 참조(TYPE REF TO data)를 만든다.
    DATA(generic_ref) = CAST data( NEW string( ) ).
    " CAST string( ... )->* 로 특정 타입 역참조 위치에 직접 쓴다 — 헬퍼 변수가 필요 없다.
    CAST string( generic_ref )->* = `abap`.
    DATA(typed_ref) = CAST string( generic_ref ).
    result = typed_ref->*.
  ENDMETHOD.

  METHOD cast_new_combo.
    " CAST iface( NEW impl( ) ): 부모 타입으로 선언하며 하위 인스턴스를 동시에 만든다.
    DATA(animal) = CAST lcl_animal( NEW lcl_dog( ) ).
    result = animal->sound( ).
  ENDMETHOD.

  METHOD bump_via_ref.
    DATA value TYPE i VALUE 10.
    DATA(ref) = REF #( value ).
    " ->* 는 참조가 가리키는 원본 데이터. 참조로 바꾸면 원본이 바뀐다.
    ref->* = ref->* + 5.
    result = value.
  ENDMETHOD.

  METHOD ref_table_row.
    DATA(values) = VALUE numbers( ( 10 ) ( 20 ) ( 30 ) ).
    " REF #( itab[ i ] OPTIONAL ): 행이 있으면 그 행의 참조, 없으면 초기(null) 참조를 얻는다.
    DATA(ref) = REF #( values[ index ] OPTIONAL ).
    " null 참조 역참조는 덤프 — 없는 행은 -1로 대체한다(DEFAULT 절의 효과를 가드로 표현).
    result = COND #( WHEN ref IS BOUND THEN ref->* ELSE -1 ).
  ENDMETHOD.

  METHOD ref_object.
    DATA(dog) = NEW lcl_dog( ).
    " REF #( oref )는 객체 참조도 복사한다 — 같은 인스턴스를 가리키는 두 번째 참조.
    DATA(same_dog) = REF #( dog ).
    result = same_dog->*->sound( ).
  ENDMETHOD.

  METHOD exact_int.
    TRY.
        " EXACT는 무손실만 허용 — 4.5처럼 정수로 못 줄이면 예외.
        result = EXACT i( value ).
      CATCH cx_sy_conversion_error.
        result = -1.
    ENDTRY.
  ENDMETHOD.

  METHOD exact_vs_conv_truncate.
    " CONV는 4글자를 char3에 조용히 자른다 -> 'abc'.
    DATA(conv_part) = CONV char3( `abcd` ).
    " 손실 시 표시값으로 먼저 인라인 선언하고, 성공 시 EXACT 결과로 덮어쓴다.
    DATA(exact_part) = CONV char3( `!!!` ).
    TRY.
        " EXACT는 잘림을 손실로 보고 CX_SY_CONVERSION_DATA_LOSS를 던진다.
        exact_part = EXACT char3( `abcd` ).
      CATCH cx_sy_conversion_data_loss.
        exact_part = `!!!`.
    ENDTRY.
    result = |{ exact_part }/{ conv_part }|.
  ENDMETHOD.

  METHOD exact_calc.
    DATA(dividend) = CONV decfloat34( '1.0' ).
    DATA(quotient) = dividend / divisor.
    TRY.
        " 무손실 계산: 1.0/4 = 0.25는 소수 2자리에 정확. 1.0/3 = 0.333...은 반올림 필요 -> 예외.
        result = EXACT amount( quotient ).
      CATCH cx_sy_conversion_rounding.
        result = -1.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
