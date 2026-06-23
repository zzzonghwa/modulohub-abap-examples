"! <p>ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.</p>
"! <p>인증 체크(AUTHORITY-CHECK)·권한 객체 소비 구문·패턴을 자체완결로 시연한다.</p>
"! <ul>
"! <li>AUTHORITY-CHECK는 커널이 로그온 시 user master record에서 메모리로 로드한
"! authorization buffer를 검사한다 — DB를 직접 읽지 않는다.</li>
"! <li>통과 논리: 같은 object의 authorization 인스턴스 중 적어도 하나가, ID로 지정한
"! 모든 field 각각의 value set에 검사값을 포함해야 한다(OR across authorizations · AND across fields).</li>
"! <li>sy-subrc: 0 통과 · 4 값불일치/필드오류 · 12 권한없음 · 40 FOR USER 무효.</li>
"! <li>DUMMY·ACTVT 활동코드·FOR USER 보안경고도 시연한다.</li>
"! <li>테스트 가능성: AUTHORITY-CHECK는 현재 사용자 의존성이므로 lif_authority로
"! 래핑해 단위 테스트에서 test double(인메모리 buffer)로 교체한다.</li>
"! </ul>
"! <p>실 구문 형태(can_start_tcode 참조):</p>
"! <p>AUTHORITY-CHECK OBJECT 'S_CARRID' ID 'CARRID' FIELD carr ID 'ACTVT' FIELD '03'.</p>
"! <p>IF sy-subrc = 0. " 허가 ELSEIF sy-subrc = 4. " 값불일치 ELSEIF sy-subrc = 12. " 권한없음 ENDIF.</p>
CLASS zcl_modulo_txn03_auth DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    "! 권한 체커 의존성을 주입한다. 비우면 실 AUTHORITY-CHECK를 감싼 production 구현 사용.
    "! @parameter authority | 권한 체크 dependency(테스트는 인메모리 buffer 주입)
    METHODS constructor
      IMPORTING authority TYPE REF TO lif_authority OPTIONAL.

    "! S_TCODE: 현재 사용자가 해당 트랜잭션을 실행할 권한이 있는지(가장 단순한 단일 필드 체크).
    "! @parameter tcode  | 트랜잭션 코드(예: 'SE80')
    "! @parameter result | 권한이 있으면 abap_true(sy-subrc = 0)
    METHODS can_start_tcode
      IMPORTING tcode         TYPE sy-tcode
      RETURNING VALUE(result) TYPE abap_bool.

    "! S_CARRID display 체크 — CARRID(데이터)+ACTVT(활동) 동시 지정.
    "! @parameter carrier | 항공사 코드(CARRID 검사값)
    "! @parameter result  | abap_true이면 해당 항공사 조회 권한 보유
    METHODS can_display_carrier
      IMPORTING carrier       TYPE c
      RETURNING VALUE(result) TYPE abap_bool.

    "! sy-subrc 의미 구분: 0/4/12를 사람이 읽는 라벨로 분류한다.
    "! @parameter carrier | 항공사 코드
    "! @parameter actvt   | 활동 코드(lif_actvt=>display 등)
    "! @parameter result  | 'GRANTED'·'VALUE_MISMATCH'·'NO_AUTH'·'INVALID_USER' 중 하나
    METHODS classify_carrier_check
      IMPORTING carrier       TYPE c
                actvt         TYPE string
      RETURNING VALUE(result) TYPE string.

    "! DUMMY 패턴: 데이터 field는 체크하지 않고 ACTVT(활동)만 체크한다.
    "! "어떤 항공사든 이 활동을 할 수 있는가"(global authorization)를 확인.
    "! @parameter actvt  | 활동 코드
    "! @parameter result | 활동 권한이 있으면 abap_true(CARRID는 DUMMY로 무시)
    METHODS can_do_activity
      IMPORTING actvt         TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

    "! FOR USER: 다른 사용자의 권한을 체크한다. 외부 입력 유저명은 보안 위험 —
    "! 데모는 내부 등록 사용자만 허용한다. 무효 사용자는 sy-subrc = 40.
    "! @parameter user    | 체크 대상 사용자명
    "! @parameter carrier | 항공사 코드
    "! @parameter result  | sy-subrc 라벨(분류기와 동일 체계)
    METHODS check_for_user
      IMPORTING user          TYPE string
                carrier       TYPE c
      RETURNING VALUE(result) TYPE string.

  PRIVATE SECTION.
    DATA authority TYPE REF TO lif_authority.

    "! sy-subrc 코드를 사람이 읽는 라벨로 변환(의미 구분).
    METHODS subrc_label
      IMPORTING subrc         TYPE i
      RETURNING VALUE(result) TYPE string.
ENDCLASS.


CLASS zcl_modulo_txn03_auth IMPLEMENTATION.
  METHOD constructor.
    " 의존성 주입: 미지정 시 실 AUTHORITY-CHECK를 감싼 production 구현을 쓴다.
    me->authority = COND #( WHEN authority IS BOUND THEN authority ELSE NEW lcl_real_authority( ) ).
  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.
    out->write( `=== TXN03 인증 체크 (AUTHORITY-CHECK) ===` ).

    " 실 권한은 실행 사용자 역할에 의존하므로(시스템 의존) production 경로는 스모크 출력만.
    out->write( |can_start_tcode('SE80')          = { can_start_tcode( 'SE80' ) } (실행 사용자 권한 의존)| ).
    out->write( |can_display_carrier('AA')        = { can_display_carrier( 'AA' ) } (실행 사용자 권한 의존)| ).
    out->write( `` ).

    " 인메모리 buffer를 주입해 권한 시나리오를 결정적으로 시연한다(test double 동일 모델).
    DATA(buffer) = NEW lcl_authority_buffer( ).
    " 한 authorization 인스턴스에 CARRID={AA,LH}·ACTVT={03} 부여(같은 인스턴스 = AND 만족).
    buffer->grant_field( object = 'S_CARRID' field = 'CARRID' value_set = VALUE #( ( `AA` ) ( `LH` ) ) ).
    buffer->grant_field( object = 'S_CARRID' field = 'ACTVT'  value_set = VALUE #( ( lif_actvt=>display ) ) ).
    DATA(demo) = NEW zcl_modulo_txn03_auth( buffer ).

    out->write( `--- 인메모리 buffer 주입(결정적 시연) ---` ).
    out->write( |can_display_carrier('AA')        = { demo->can_display_carrier( 'AA' ) } (CARRID·ACTVT 모두 충족)| ).
    out->write( |classify('LH', display)          = { demo->classify_carrier_check(
                                                         carrier = 'LH' actvt = lif_actvt=>display ) }| ).
    out->write( |classify('LH', change)           = { demo->classify_carrier_check(
                                                         carrier = 'LH' actvt = lif_actvt=>change ) } (ACTVT 불일치)| ).
    out->write( |classify('ZZ', display)          = { demo->classify_carrier_check(
                                                         carrier = 'ZZ' actvt = lif_actvt=>display ) } (CARRID 불일치)| ).
    out->write( |can_do_activity(display) DUMMY   = { demo->can_do_activity( lif_actvt=>display ) } (CARRID DUMMY)| ).
    out->write( `결과는 OR(인스턴스) · AND(필드) 논리와 sy-subrc 체계를 따른다.` ).
  ENDMETHOD.

  METHOD can_start_tcode.
    " S_TCODE 단일 필드 체크: ID 'TCD' FIELD tcode.
    DATA(subrc) = authority->check(
      object = 'S_TCODE'
      fields = VALUE #( ( name = `TCD` value = CONV string( tcode ) ) ) ).
    result = xsdbool( subrc = lif_subrc=>granted ).
  ENDMETHOD.

  METHOD can_display_carrier.
    " CARRID(데이터)+ACTVT='03'(display) 동시 지정 — 둘 다 충족해야 통과(AND).
    DATA(subrc) = authority->check(
      object = 'S_CARRID'
      fields = VALUE #( ( name = `CARRID` value = CONV string( carrier ) )
                        ( name = `ACTVT`  value = lif_actvt=>display ) ) ).
    result = xsdbool( subrc = lif_subrc=>granted ).
  ENDMETHOD.

  METHOD classify_carrier_check.
    DATA(subrc) = authority->check(
      object = 'S_CARRID'
      fields = VALUE #( ( name = `CARRID` value = CONV string( carrier ) )
                        ( name = `ACTVT`  value = actvt ) ) ).
    result = subrc_label( subrc ).
  ENDMETHOD.

  METHOD can_do_activity.
    " DUMMY: CARRID는 dummy=abap_true로 체크 생략 -> ACTVT만 본다(global authorization).
    DATA(subrc) = authority->check(
      object = 'S_CARRID'
      fields = VALUE #( ( name = `CARRID` dummy = abap_true )
                        ( name = `ACTVT`  value = actvt ) ) ).
    result = xsdbool( subrc = lif_subrc=>granted ).
  ENDMETHOD.

  METHOD check_for_user.
    " FOR USER: 지정 사용자의 권한을 체크. 무효 사용자명은 sy-subrc = 40.
    DATA(subrc) = authority->check(
      object = 'S_CARRID'
      fields = VALUE #( ( name = `CARRID` value = CONV string( carrier ) )
                        ( name = `ACTVT`  value = lif_actvt=>display ) )
      user   = user ).
    result = subrc_label( subrc ).
  ENDMETHOD.

  METHOD subrc_label.
    result = SWITCH #( subrc
                       WHEN lif_subrc=>granted        THEN `GRANTED`
                       WHEN lif_subrc=>value_mismatch THEN `VALUE_MISMATCH`
                       WHEN lif_subrc=>no_auth        THEN `NO_AUTH`
                       WHEN lif_subrc=>invalid_user   THEN `INVALID_USER`
                       ELSE `UNKNOWN` ).
  ENDMETHOD.
ENDCLASS.
