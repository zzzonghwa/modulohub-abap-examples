"! 인메모리 authorization buffer — 커널이 로그온 시 user master record에서 메모리로 로드하는
"! authorization buffer의 비유. 실 시스템은 DB를 직접 읽지 않고 이 버퍼만 검사한다.
"! 여기선 AUTHORITY-CHECK 통과 논리(OR across authorizations · AND across fields),
"! DUMMY, sy-subrc 체계(0/4/12), FOR USER를 로컬 모델로 자체완결 시연한다.
"! 실 코드는 lcl_real_authority가 진짜 AUTHORITY-CHECK 구문을 감싼다(의존성 래핑).

"! 권한 체크 dependency 추상화. 단위 테스트에서 test double로 교체 가능.
INTERFACE lif_authority.
  TYPES:
    "! 체크할 field-value 쌍. value가 비어 있으면 DUMMY로 간주.
    BEGIN OF check_field,
      name  TYPE string,
      value TYPE string,
      dummy TYPE abap_bool,
    END OF check_field.
  TYPES check_fields TYPE STANDARD TABLE OF check_field WITH EMPTY KEY.

  "! AUTHORITY-CHECK 한 번에 대응. sy-subrc 호환 코드를 돌려준다.
  "! @parameter object | authorization object 이름(대문자)
  "! @parameter fields | 체크할 field-value 쌍 목록(최대 10개)
  "! @parameter user   | FOR USER 대상(비우면 현재 사용자)
  "! @parameter result | sy-subrc 호환: 0 통과 · 4 값불일치/필드오류 · 12 권한없음 · 40 유저무효
  METHODS check
    IMPORTING object        TYPE string
              fields        TYPE check_fields
              user          TYPE string OPTIONAL
    RETURNING VALUE(result) TYPE i.
ENDINTERFACE.


"! sy-subrc 호환 상수. 의미를 코드에 명시한다.
INTERFACE lif_subrc.
  CONSTANTS:
    "! 0 — 체크 통과(또는 check indicator가 no check).
    granted        TYPE i VALUE 0,
    "! 4 — authorization은 있으나 값 불일치, 또는 잘못된 필드/필드 수 초과.
    value_mismatch TYPE i VALUE 4,
    "! 12 — 해당 object에 대한 authorization 자체가 없음.
    no_auth        TYPE i VALUE 12,
    "! 40 — FOR USER 사용자명이 유효하지 않음.
    invalid_user   TYPE i VALUE 40.
ENDINTERFACE.


"! ACTVT 활동 코드 상수. CRUD 표준 매핑.
INTERFACE lif_actvt.
  CONSTANTS:
    "! 01 — create(생성).
    create  TYPE string VALUE '01',
    "! 02 — change(변경).
    change  TYPE string VALUE '02',
    "! 03 — display(조회).
    display TYPE string VALUE '03',
    "! 06 — delete(삭제).
    delete  TYPE string VALUE '06'.
ENDINTERFACE.


"! 실 AUTHORITY-CHECK 구문을 감싸는 production 구현. 현재 로그온 사용자에 의존하므로
"! 단위 테스트에서는 lcl_authority_buffer(test double)로 교체한다.
CLASS lcl_real_authority DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES lif_authority.
ENDCLASS.

CLASS lcl_real_authority IMPLEMENTATION.
  METHOD lif_authority~check.
    " 데모를 위해 두 표준 권한객체(S_TCODE·S_CARRID)만 실제 구문으로 분기한다.
    " 실무에서는 object·field를 동적으로 다룰 수 없으므로(리터럴 권장), 케이스별로 쓴다.
    " AUTHORITY-CHECK는 클래식 문이라 FIELD에 생성자식을 못 쓴다 — 값을 데이터 오브젝트로 분리한다.
    DATA tcd    TYPE sy-tcode.
    DATA carrid TYPE c LENGTH 3.
    DATA actvt  TYPE c LENGTH 2.
    CASE object.
      WHEN 'S_TCODE'.
        tcd = VALUE #( fields[ name = `TCD` ]-value OPTIONAL ).
        AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD tcd.
        result = sy-subrc.
      WHEN 'S_CARRID'.
        " CARRID(데이터)와 ACTVT(활동)를 각각 지정.
        carrid = VALUE #( fields[ name = `CARRID` ]-value OPTIONAL ).
        actvt  = VALUE #( fields[ name = `ACTVT` ]-value OPTIONAL ).
        AUTHORITY-CHECK OBJECT 'S_CARRID' ID 'CARRID' FIELD carrid
                                          ID 'ACTVT'  FIELD actvt.
        result = sy-subrc.
      WHEN OTHERS.
        " 알 수 없는 object는 권한 없음으로 취급(보수적 기본값).
        result = lif_subrc=>no_auth.
    ENDCASE.
    " user(FOR USER)는 데모 production 경로에서 다루지 않는다 — 외부 유저명 지정은 보안 위험.
  ENDMETHOD.
ENDCLASS.


"! 단위 테스트용 authorization buffer 모델(test double). 한 사용자의 user master record에
"! 부여된 authorization 인스턴스 집합을 보관하고 AUTHORITY-CHECK 통과 논리를 재현한다.
"! 통과 조건: 같은 object의 authorization 인스턴스 중 적어도 하나가, 지정된 모든
"! field 각각의 value set에 검사값을 포함해야 한다(OR across authorizations · AND across fields).
CLASS lcl_authority_buffer DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES lif_authority.

    "! 한 authorization 인스턴스의 한 field에 대한 value set 한 항목.
    TYPES:
      BEGIN OF grant,
        user      TYPE string,
        object    TYPE string,
        instance  TYPE i,
        field     TYPE string,
        value_set TYPE string_table,
      END OF grant.
    TYPES grants TYPE STANDARD TABLE OF grant WITH EMPTY KEY.

    "! authorization 인스턴스 하나의 한 field value set을 버퍼에 부여한다(PFCG 부여 비유).
    "! @parameter user      | 대상 사용자(비우면 현재 사용자 sy-uname)
    "! @parameter object    | authorization object 이름
    "! @parameter instance  | authorization 인스턴스 번호(같은 번호 = 같은 인스턴스)
    "! @parameter field     | authorization field 이름(예: 'CARRID'·'ACTVT')
    "! @parameter value_set | 허용값 집합(이 목록에 검사값이 있으면 해당 field 통과)
    METHODS grant_field
      IMPORTING user      TYPE string OPTIONAL
                object    TYPE string
                instance  TYPE i DEFAULT 1
                field     TYPE string
                value_set TYPE string_table.

    "! 유효 사용자 등록(FOR USER 데모). 미등록 사용자를 FOR USER로 지정하면 subrc=40.
    METHODS register_user
      IMPORTING user TYPE string.

  PRIVATE SECTION.
    DATA granted_fields TYPE grants.
    DATA known_users TYPE string_table.

    "! 한 authorization 인스턴스가 지정된 모든 field 검사값을 포함하는지(AND across fields).
    METHODS instance_covers_all
      IMPORTING user          TYPE string
                object        TYPE string
                instance      TYPE i
                fields        TYPE lif_authority=>check_fields
      RETURNING VALUE(result) TYPE abap_bool.

    "! object에 대해 사용자에게 부여된 서로 다른 인스턴스 번호 목록.
    METHODS instances_of
      IMPORTING user          TYPE string
                object        TYPE string
      RETURNING VALUE(result) TYPE int4_table.
ENDCLASS.

CLASS lcl_authority_buffer IMPLEMENTATION.
  METHOD grant_field.
    INSERT VALUE #( user      = COND #( WHEN user IS INITIAL THEN CONV string( sy-uname ) ELSE user )
                    object    = object
                    instance  = instance
                    field     = field
                    value_set = value_set ) INTO TABLE granted_fields.
  ENDMETHOD.

  METHOD register_user.
    INSERT user INTO TABLE known_users.
  ENDMETHOD.

  METHOD lif_authority~check.
    DATA(effective_user) = COND string( WHEN user IS INITIAL THEN CONV string( sy-uname ) ELSE user ).

    " FOR USER 지정 사용자가 유효하지 않으면 subrc=40. 현재 사용자(user 비움)는 항상 유효.
    IF user IS NOT INITIAL AND NOT line_exists( known_users[ table_line = user ] ).
      result = lif_subrc=>invalid_user.
      RETURN.
    ENDIF.

    " object에 대한 authorization 인스턴스가 하나도 없으면 subrc=12.
    DATA(instances) = instances_of( user = effective_user object = object ).
    IF instances IS INITIAL.
      result = lif_subrc=>no_auth.
      RETURN.
    ENDIF.

    " OR across authorizations: 적어도 한 인스턴스가 모든 field를 커버하면 통과.
    LOOP AT instances INTO DATA(instance).
      IF instance_covers_all( user     = effective_user
                              object   = object
                              instance = instance
                              fields   = fields ) = abap_true.
        result = lif_subrc=>granted.
        RETURN.
      ENDIF.
    ENDLOOP.

    " 인스턴스는 있으나 어느 것도 모든 field 검사값을 포함하지 못함 -> subrc=4.
    result = lif_subrc=>value_mismatch.
  ENDMETHOD.

  METHOD instances_of.
    LOOP AT granted_fields INTO DATA(line) WHERE user = user AND object = object.
      IF NOT line_exists( result[ table_line = line-instance ] ).
        INSERT line-instance INTO TABLE result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD instance_covers_all.
    " AND across fields: 지정된 모든 field 각각이 통과해야 한다. DUMMY/빈 값은 체크 생략.
    LOOP AT fields INTO DATA(field).
      IF field-dummy = abap_true.
        " DUMMY field는 value set 무관하게 통과로 간주.
        CONTINUE.
      ENDIF.
      READ TABLE granted_fields INTO DATA(granted) WITH KEY user     = user
                                                            object   = object
                                                            instance = instance
                                                            field    = field-name.
      IF sy-subrc <> 0.
        " 이 인스턴스에 해당 field 부여가 없음 -> 이 인스턴스로는 통과 불가.
        result = abap_false.
        RETURN.
      ENDIF.
      IF NOT line_exists( granted-value_set[ table_line = field-value ] ).
        " value set이 검사값을 포함하지 않음 -> 이 인스턴스로는 통과 불가.
        result = abap_false.
        RETURN.
      ENDIF.
    ENDLOOP.
    result = abap_true.
  ENDMETHOD.
ENDCLASS.
