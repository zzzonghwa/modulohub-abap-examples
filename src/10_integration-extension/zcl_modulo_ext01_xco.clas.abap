"! <p>ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.</p>
"! <p>Released API·XCO(eXtension Components) 소비 — 고전 FM의 released 대체.</p>
"! <p>XCO_CP* 군은 release contract C1 계약 하의 released 유틸이라 업그레이드·Cloud 이전에</p>
"! <p>breaking change가 없다(Clean Core). 고전 FM은 sy-subrc를 조용히 무시할 수 있으나</p>
"! <p>released class의 class-based 예외는 처리 누락을 컴파일/런타임에 강제한다.</p>
"! <ul>
"! <li>문자열 체이닝: xco_cp=>string( )->to_upper/lower/from/to/append/
"! prepend/split, xco_cp=>strings( )->join, ->starts_with/ends_with/matches.</li>
"! <li>UUID: xco_cp=>uuid( )->value / ->as( c36 ), cl_system_uuid 대안.</li>
"! <li>현재 순간: xco_cp=>sy->date/user — sy-datum 직접 접근의 Cloud 호환 경로.</li>
"! <li>랜덤: cl_abap_random_int — 비released 고전 랜덤 FM 대체(C1).</li>
"! <li>고전 대조: TRANSLATE ... TO UPPER CASE 등 전통 구문과 결과 동일함을 보인다.</li>
"! </ul>
CLASS zcl_modulo_ext01_xco DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    "! XCO 문자열 API로 대문자화(고전 TO_UPPER FM·TRANSLATE 대체).
    "! @parameter text   | 입력 문자열
    "! @parameter result | 대문자 변환 결과
    METHODS to_upper
      IMPORTING text          TYPE string
      RETURNING VALUE(result) TYPE string.

    "! XCO 문자열 API로 소문자화.
    "! @parameter text   | 입력 문자열
    "! @parameter result | 소문자 변환 결과
    METHODS to_lower
      IMPORTING text          TYPE string
      RETURNING VALUE(result) TYPE string.

    "! 전통형 대조: TRANSLATE ... TO UPPER CASE. XCO to_upper와 결과가 같음을 보이는 대조군.
    "! @parameter text   | 입력 문자열
    "! @parameter result | 대문자 변환 결과(전통 구문)
    METHODS to_upper_classic
      IMPORTING text          TYPE string
      RETURNING VALUE(result) TYPE string.

    "! 문자열 역순(고전 문자열 처리 FM 대체). 내장 함수 reverse( ).
    "! @parameter text   | 입력 문자열
    "! @parameter result | 역순 문자열
    METHODS reverse
      IMPORTING text          TYPE string
      RETURNING VALUE(result) TYPE string.

    "! 구분자로 분리 후 다른 구분자로 재결합 — split + strings( )->join 체이닝.
    "! @parameter text      | 입력 문자열
    "! @parameter separator | 분리 구분자
    "! @parameter joiner    | 재결합 구분자
    "! @parameter result    | 재결합 결과
    METHODS resplit
      IMPORTING text          TYPE string
                separator     TYPE string
                joiner        TYPE string
      RETURNING VALUE(result) TYPE string.

    "! 분리 후 조각 수 — split이 만든 STRING_TABLE의 행 수.
    "! @parameter text      | 입력 문자열
    "! @parameter separator | 분리 구분자
    "! @parameter result    | 조각 수
    METHODS split_count
      IMPORTING text          TYPE string
                separator     TYPE string
      RETURNING VALUE(result) TYPE i.

    "! 정규식 매치 여부 — xco_cp=>string( )->matches( ). 부울 반환.
    "! @parameter text    | 입력 문자열
    "! @parameter pattern | PCRE 정규식
    "! @parameter result  | 전체 매치면 abap_true
    METHODS matches_pattern
      IMPORTING text          TYPE string
                pattern       TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

    "! 접두 확인 — starts_with. 고전 substring 비교 대체.
    "! @parameter text   | 입력 문자열
    "! @parameter prefix | 접두 후보
    "! @parameter result | 접두면 abap_true
    METHODS starts_with
      IMPORTING text          TYPE string
                prefix        TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

    "! XCO로 UUID 생성(고전 GUID_CREATE FM 대체). 값은 매번 다르다.
    "! @parameter result | 새 UUID 문자열(sysuuid_x16, 32자 hex)
    METHODS new_uuid
      RETURNING VALUE(result) TYPE string.

    "! UUID를 RFC4122 c36 형식으로(8-4-4-4-12, 하이픈 4개·길이 36).
    "! @parameter result | c36 형식 UUID 문자열
    METHODS new_uuid_c36
      RETURNING VALUE(result) TYPE string.

    "! 대안 경로: cl_system_uuid(released)로 c36 UUID 생성 — XCO 없이도 가능함을 보인다.
    "! @parameter result | c36 형식 UUID 문자열
    METHODS new_uuid_via_system
      RETURNING VALUE(result) TYPE string.

    "! XCO sy 핸들로 현재 사용자명(고전 sy-uname 대체 경로, Cloud 호환).
    "! @parameter result | 현재 사용자명
    METHODS current_user
      RETURNING VALUE(result) TYPE string.

    "! released 랜덤 정수(고전 랜덤 FM 대체, C1). 시드를 받아 재현 가능하게 한다.
    "! 결과는 [low, high] 폐구간 안의 정수다.
    "! @parameter seed   | PRNG 시드(같은 시드는 같은 수열)
    "! @parameter low    | 하한(포함)
    "! @parameter high   | 상한(포함)
    "! @parameter result | low..high 범위의 난수
    METHODS random_int
      IMPORTING seed          TYPE i
                low           TYPE i
                high          TYPE i
      RETURNING VALUE(result) TYPE i.

  PRIVATE SECTION.
    "! 데모용 항공사 분류 코드 — 점 구분 토큰을 가진 자체완결 샘플.
    METHODS sample_codes
      RETURNING VALUE(result) TYPE string.
ENDCLASS.


CLASS zcl_modulo_ext01_xco IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== EXT01 released API·XCO 소비 ===` ).
    out->write( |to_upper('abap')             = { to_upper( `abap` ) }| ).
    out->write( |to_upper_classic('abap')     = { to_upper_classic( `abap` ) } (전통 TRANSLATE)| ).
    out->write( |to_lower('ABAP')             = { to_lower( `ABAP` ) }| ).
    out->write( |reverse('abc')               = { reverse( `abc` ) }| ).
    DATA(codes) = sample_codes( ).
    out->write( |resplit('{ codes }' . -> /)  = { resplit( text = codes separator = `.` joiner = `/` ) }| ).
    out->write( |split_count('{ codes }' .)   = { split_count( text = codes separator = `.` ) }| ).
    out->write( |matches_pattern('A1' \\w\\d) = { matches_pattern( text = `A1` pattern = `\w\d` ) }| ).
    out->write( |starts_with('ZCL_X' ZCL_)    = { starts_with( text = `ZCL_X` prefix = `ZCL_` ) }| ).
    out->write( |new_uuid                      = { new_uuid( ) }| ).
    out->write( |new_uuid_c36                  = { new_uuid_c36( ) }| ).
    out->write( |new_uuid_via_system           = { new_uuid_via_system( ) }| ).
    out->write( |current_user                  = { current_user( ) }| ).
    out->write( |random_int(seed=1 1..6)       = { random_int( seed = 1 low = 1 high = 6 ) }| ).
  ENDMETHOD.

  METHOD to_upper.
    result = xco_cp=>string( text )->to_upper_case( )->value.
  ENDMETHOD.

  METHOD to_lower.
    result = xco_cp=>string( text )->to_lower_case( )->value.
  ENDMETHOD.

  METHOD to_upper_classic.
    " 전통 구문 대조군 — XCO to_upper와 결과가 같다(불변값이라 RETURNING에 직접 못 써서 임시 복사).
    result = text.
    TRANSLATE result TO UPPER CASE.
  ENDMETHOD.

  METHOD reverse.
    " XCO 단일 문자열 핸들러엔 역순 메서드가 없다 — 내장 함수 reverse를 쓴다.
    result = reverse( text ).
  ENDMETHOD.

  METHOD resplit.
    " split -> STRING_TABLE, strings( )->join으로 다른 구분자로 재결합.
    DATA(parts) = xco_cp=>string( text )->split( separator )->value.
    result = xco_cp=>strings( parts )->join( joiner )->value.
  ENDMETHOD.

  METHOD split_count.
    result = lines( xco_cp=>string( text )->split( separator )->value ).
  ENDMETHOD.

  METHOD matches_pattern.
    result = xco_cp=>string( text )->matches( pattern ).
  ENDMETHOD.

  METHOD starts_with.
    result = xco_cp=>string( text )->starts_with( prefix ).
  ENDMETHOD.

  METHOD new_uuid.
    result = xco_cp=>uuid( )->value.
  ENDMETHOD.

  METHOD new_uuid_c36.
    " c36 = RFC4122 형식(8-4-4-4-12). 고전 GUID_CREATE의 형식 변환을 플루언트로.
    result = xco_cp=>uuid( )->as( xco_cp_uuid=>format->c36 )->value.
  ENDMETHOD.

  METHOD new_uuid_via_system.
    " 대안: released cl_system_uuid. XCO 없이도 c36 UUID를 얻는 경로.
    result = cl_system_uuid=>create_uuid_c36_static( ).
  ENDMETHOD.

  METHOD current_user.
    " xco_cp=>sy 는 SY 구조의 XCO 표현 — Cloud 호환 sy 접근 경로.
    result = xco_cp=>sy->user( )->name.
  ENDMETHOD.

  METHOD random_int.
    " 시드 고정 -> 재현 가능. 비released 고전 랜덤 FM 대신 C1 released 클래스.
    result = cl_abap_random_int=>create( seed = seed
                                         min  = low
                                         max  = high )->get_next( ).
  ENDMETHOD.

  METHOD sample_codes.
    result = `AA.LH.UA`.
  ENDMETHOD.
ENDCLASS.
