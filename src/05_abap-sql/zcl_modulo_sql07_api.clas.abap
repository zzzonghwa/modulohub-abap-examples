"! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
"!
"! released API 소비와 "확장 계약(release contract)" 읽기 — 노트 05-7을 자체완결로 시연한다.
"! 계약은 두 분류의 결합이다(W2): ① release contract(안정성 약속) + ② restricted ABAP
"! language version용 visibility. 둘 다 충족돼야 released API다.
"!
"! release contract 5종(W4~W10): C0=확장(enhancement 필드 추가) / C1=내부 소비(AS ABAP 내) /
"! C2=원격 소비(RFC·OData 등 AS ABAP 밖) / C3=설정 영속 / C4=AMDP 간. C1·C2는 공존 가능(W6).
"! 소비 판단(S2·S4): ABAP 코드에서 ->method() 호출 = C1로 충분. 외부(RFC/OData) = C2 필요.
"!
"! 실제 released API 소비: CL_ABAP_CONTEXT_INFO(C1)로 SY/SYST 전역 대신 시스템·사용자 정보를
"! 읽는다(읽기 전용). 출력(날짜·시간)은 실행 시점·시스템마다 달라 manual-report로 분류한다.
"!
"! released 카탈로그 조회(G6·G7·라이브): 실 시스템은 released 객체를 CDS 뷰
"! I_APIsForCloudDevelopment(WHERE ReleaseState='RELEASED')로, deprecated+후속을
"! I_APIsWithCloudDevSuccessor로 ABAP SQL 소비한다. 7.54 자체완결을 위해 동일한 SELECT 구문
"! 형태를 메모리 카탈로그(단일 itab SELECT FROM @catalog AS api)로 시연한다 — 쿼리 모양은 동일.
CLASS zcl_modulo_sql07_api DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    "! release contract 등급(C0~C4). 실 카탈로그의 분류 컬럼을 모사한다.
    TYPES release_contract TYPE c LENGTH 2.
    "! released 여부 상태값(RELEASED·NOT_RELEASED·DEPRECATED). 실 ReleaseState 컬럼을 모사한다.
    TYPES release_state TYPE c LENGTH 12.
    "! repository 객체 종류(CLAS·INTF·DDLS 등). 실 ReleasedObjectType 컬럼을 모사한다.
    TYPES object_type TYPE c LENGTH 4.

    "! released 카탈로그의 한 행(I_APIsForCloudDevelopment 투영 모사).
    "! 실 CDS의 CamelCase 요소(ReleasedObjectType·ReleasedObjectName·ReleaseState)에 대응한다.
    TYPES:
      BEGIN OF api_entry,
        object_type TYPE object_type,
        object_name TYPE c LENGTH 30,
        state       TYPE release_state,
        contract    TYPE release_contract,
      END OF api_entry.
    TYPES api_catalog TYPE STANDARD TABLE OF api_entry WITH EMPTY KEY.

    "! deprecated 객체와 그 Cloud successor 쌍(I_APIsWithCloudDevSuccessor 투영 모사).
    TYPES:
      BEGIN OF successor_entry,
        predecessor TYPE c LENGTH 30,
        successor   TYPE c LENGTH 30,
      END OF successor_entry.
    TYPES successor_map TYPE STANDARD TABLE OF successor_entry WITH EMPTY KEY.

    "! 실제 released API(C1) 소비: SY-DATUM 대신 CL_ABAP_CONTEXT_INFO로 시스템 날짜를 읽는다.
    "! @parameter result | 시스템 날짜
    METHODS system_date
      RETURNING VALUE(result) TYPE d.

    "! 실제 released API(C1) 소비: SY-UZEIT 대신 CL_ABAP_CONTEXT_INFO로 시스템 시간을 읽는다.
    "! @parameter result | 시스템 시간
    METHODS system_time
      RETURNING VALUE(result) TYPE t.

    "! G6 패턴: released 카탈로그에서 RELEASED 상태 객체 수를 센다(WHERE ReleaseState='RELEASED').
    "! 실 구문: SELECT COUNT(*) FROM i_apisforclouddevelopment WHERE releasestate='RELEASED'.
    "! @parameter result | RELEASED 상태 객체 수
    METHODS released_count
      RETURNING VALUE(result) TYPE i.

    "! G6 패턴: 객체 종류별 released 카탈로그 조회(WHERE ReleaseState·ReleasedObjectType, ORDER BY).
    "! @parameter object_type | 필터할 객체 종류(예: CLAS)
    "! @parameter result      | 해당 종류의 RELEASED 객체명 목록(이름 오름차순)
    METHODS released_names_of_type
      IMPORTING object_type   TYPE object_type
      RETURNING VALUE(result) TYPE string_table.

    "! S2 2단계 체크 1단계: 객체가 released 카탈로그에 RELEASED로 존재하는가(존재 확인 SELECT SINGLE).
    "! @parameter object_name | 조회할 객체명
    "! @parameter result      | RELEASED로 카탈로그에 있으면 abap_true
    METHODS is_released
      IMPORTING object_name   TYPE csequence
      RETURNING VALUE(result) TYPE abap_bool.

    "! S2 2단계 체크 2단계: 객체의 release contract 등급을 읽는다(SELECT SINGLE contract).
    "! @parameter object_name | 조회할 객체명
    "! @parameter result      | 계약 등급(C0~C4), 미등록이면 공백
    METHODS contract_of
      IMPORTING object_name   TYPE csequence
      RETURNING VALUE(result) TYPE release_contract.

    "! S4 소비 판단: 주어진 호출 경계에 맞는 계약을 객체가 보유하는지 판정한다.
    "! 내부 ABAP 호출(->method())은 C1이면 충분, 원격(RFC·OData)은 C2가 필요(S3·S4).
    "! @parameter object_name | 조회할 객체명
    "! @parameter remote      | abap_true=원격 호출(C2 필요), abap_false=내부 호출(C1 충분)
    "! @parameter result      | 해당 호출에 안전하게 소비 가능하면 abap_true
    METHODS may_consume
      IMPORTING object_name   TYPE csequence
                remote        TYPE abap_bool
      RETURNING VALUE(result) TYPE abap_bool.

    "! S5·G7·G17 패턴: deprecated 객체의 Cloud successor를 조회한다(successor 맵 SELECT SINGLE).
    "! 실 구문: SELECT SINGLE successorobjectname FROM i_apiswithclouddevsuccessor
    "!         WHERE predecessorobjectname = @old.
    "! @parameter object_name | deprecated(예정) 객체명
    "! @parameter result      | 이행 대상 successor 객체명, 없으면 공백
    METHODS successor_of
      IMPORTING object_name   TYPE csequence
      RETURNING VALUE(result) TYPE successor_entry-successor.

    "! S5 deprecated 발견 대응: 카탈로그에서 DEPRECATED 상태 객체와 successor를 함께 조회한다.
    "! 메모리 두 테이블이라 itab 식으로 successor를 붙인다(7.54 자체완결 — 두 itab JOIN 회피).
    "! @parameter result | (deprecated 객체명·successor) 쌍, 객체명 오름차순
    METHODS deprecated_with_successor
      RETURNING VALUE(result) TYPE successor_map.

  PRIVATE SECTION.
    "! released 카탈로그 데모 데이터(I_APIsForCloudDevelopment 투영 모사).
    "! 실 클래스(CL_ABAP_CONTEXT_INFO=C1·CL_ABAP_RANDOM_INT=C1·G3)와 가상 객체를 섞어 등급을 보인다.
    METHODS sample_catalog
      RETURNING VALUE(result) TYPE api_catalog.
    "! deprecated->successor 데모 데이터(I_APIsWithCloudDevSuccessor 투영 모사).
    METHODS sample_successors
      RETURNING VALUE(result) TYPE successor_map.
ENDCLASS.


CLASS zcl_modulo_sql07_api IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== SQL07 released API 소비·확장 계약(C0~C4) 읽기 ===` ).
    out->write( |system_date = { system_date( ) DATE = ISO } (CL_ABAP_CONTEXT_INFO·C1)| ).
    out->write( |system_time = { system_time( ) TIME = ISO } (CL_ABAP_CONTEXT_INFO·C1)| ).
    out->write( |released_count                       = { released_count( ) }| ).
    out->write( |released_names_of_type(CLAS)          = { lines( released_names_of_type( 'CLAS' ) ) }편| ).
    out->write( |is_released(CL_ABAP_CONTEXT_INFO)     = { is_released( 'CL_ABAP_CONTEXT_INFO' ) }| ).
    out->write( |contract_of(CL_ABAP_CONTEXT_INFO)     = { contract_of( 'CL_ABAP_CONTEXT_INFO' ) }| ).
    DATA(target) = `CL_ABAP_CONTEXT_INFO`.
    out->write( |may_consume(internal,C1 충분) = { may_consume( object_name = target remote = abap_false ) }| ).
    out->write( |may_consume(remote,C2 필요)   = { may_consume( object_name = target remote = abap_true ) }| ).
    out->write( |successor_of(CL_OLD_THING)           = { successor_of( 'CL_OLD_THING' ) }| ).
    out->write( |deprecated_with_successor             = { lines( deprecated_with_successor( ) ) }쌍| ).
    out->write( `값은 카탈로그 모사 데이터 기준. 실 시스템은 I_APIsForCloudDevelopment를 같은 SQL로 읽는다.` ).
  ENDMETHOD.

  METHOD system_date.
    " SY-DATUM 대신 released API(C1)로 읽는다 — 클라우드 준비·Clean Core.
    result = cl_abap_context_info=>get_system_date( ).
  ENDMETHOD.

  METHOD system_time.
    result = cl_abap_context_info=>get_system_time( ).
  ENDMETHOD.

  METHOD released_count.
    " G6: 실 시스템은 I_APIsForCloudDevelopment를 같은 WHERE 절로 읽는다. 여기선 카탈로그를 모사한다.
    DATA(catalog) = sample_catalog( ) ##NEEDED.
    SELECT COUNT(*)
      FROM @catalog AS api
      WHERE state = 'RELEASED'
      INTO @DATA(matches).
    result = matches.
  ENDMETHOD.

  METHOD released_names_of_type.
    DATA(catalog) = sample_catalog( ) ##NEEDED.
    " G6: WHERE ReleaseState + ReleasedObjectType, ORDER BY ReleasedObjectName 패턴.
    SELECT object_name
      FROM @catalog AS api
      WHERE state       = 'RELEASED'
        AND object_type = @object_type
      ORDER BY object_name
      INTO TABLE @DATA(names).
    result = VALUE #( FOR entry IN names ( CONV string( entry-object_name ) ) ).
  ENDMETHOD.

  METHOD is_released.
    " S2 1단계: 존재 확인 — 데이터를 안 읽고 RELEASED 행 존재 여부만 본다.
    DATA(catalog) = sample_catalog( ) ##NEEDED.
    SELECT SINGLE @abap_true
      FROM @catalog AS api
      WHERE object_name = @object_name
        AND state       = 'RELEASED'
      INTO @DATA(exists).
    result = exists.
  ENDMETHOD.

  METHOD contract_of.
    " S2 2단계: 계약 등급 읽기 — 미등록이면 sy-subrc<>0 이므로 공백 반환.
    DATA(catalog) = sample_catalog( ) ##NEEDED.
    SELECT SINGLE contract
      FROM @catalog AS api
      WHERE object_name = @object_name
      INTO @DATA(contract).
    result = COND #( WHEN sy-subrc = 0 THEN contract ).
  ENDMETHOD.

  METHOD may_consume.
    " S3·S4: 내부 ABAP 호출은 C1로 충분, 원격(RFC·OData)은 C2가 필요하다.
    " 카탈로그가 RELEASED 상태이고 호출 경계에 맞는 계약을 보유할 때만 소비 가능으로 판정한다.
    DATA(contract) = contract_of( object_name ).
    DATA(released) = is_released( object_name ).
    result = COND #(
      WHEN released = abap_false THEN abap_false
      WHEN remote   = abap_true  THEN xsdbool( contract = 'C2' )
      ELSE                            xsdbool( contract = 'C1' OR contract = 'C2' ) ).
  ENDMETHOD.

  METHOD successor_of.
    " S5·G7: deprecated 객체의 Cloud successor 조회(I_APIsWithCloudDevSuccessor 등가).
    DATA(successors) = sample_successors( ) ##NEEDED.
    SELECT SINGLE successor
      FROM @successors AS link
      WHERE predecessor = @object_name
      INTO @DATA(successor).
    result = COND #( WHEN sy-subrc = 0 THEN successor ).
  ENDMETHOD.

  METHOD deprecated_with_successor.
    " S5: 카탈로그에서 DEPRECATED 상태 객체를 뽑고, successor 맵에서 후속을 itab 식으로 붙인다.
    " 두 메모리 itab을 한 SQL로 JOIN하지 않아(7.55+ 의존 회피) 7.54에서도 동작한다.
    DATA(catalog) = sample_catalog( ) ##NEEDED.
    SELECT object_name
      FROM @catalog AS api
      WHERE state = 'DEPRECATED'
      ORDER BY object_name
      INTO TABLE @DATA(deprecated).
    DATA(successors) = sample_successors( ).
    result = VALUE #( FOR entry IN deprecated
      ( predecessor = entry-object_name
        successor   = VALUE #( successors[ predecessor = entry-object_name ]-successor OPTIONAL ) ) ).
  ENDMETHOD.

  METHOD sample_catalog.
    " 실 released 클래스(C1·G3)와 가상 객체를 섞는다. NOT_RELEASED·DEPRECATED 상태도 포함해
    " 2단계 체크·deprecated 이행 시나리오를 모두 시연한다.
    result = VALUE #(
      ( object_type = 'CLAS' object_name = 'CL_ABAP_CONTEXT_INFO' state = 'RELEASED'     contract = 'C1' )
      ( object_type = 'CLAS' object_name = 'CL_ABAP_RANDOM_INT'   state = 'RELEASED'     contract = 'C1' )
      ( object_type = 'CLAS' object_name = 'CL_GATEWAY_REMOTE'    state = 'RELEASED'     contract = 'C2' )
      ( object_type = 'INTF' object_name = 'IF_ABAP_PROB_TYPES'   state = 'RELEASED'     contract = 'C1' )
      ( object_type = 'DDLS' object_name = 'I_COMPANYCODE'        state = 'RELEASED'     contract = 'C1' )
      ( object_type = 'CLAS' object_name = 'CL_INTERNAL_HELPER'   state = 'NOT_RELEASED' contract = '' )
      ( object_type = 'CLAS' object_name = 'CL_OLD_THING'         state = 'DEPRECATED'   contract = 'C1' )
      ( object_type = 'CLAS' object_name = 'CL_LEGACY_READER'     state = 'DEPRECATED'   contract = 'C1' ) ).
  ENDMETHOD.

  METHOD sample_successors.
    result = VALUE #(
      ( predecessor = 'CL_OLD_THING'     successor = 'CL_NEW_THING' )
      ( predecessor = 'CL_LEGACY_READER' successor = 'CL_MODERN_READER' ) ).
  ENDMETHOD.
ENDCLASS.
