"! 권한 체크 단위 테스트. 실 AUTHORITY-CHECK는 현재 로그온 사용자에 의존하므로
"! 정확값을 단정할 수 없다 -> zif_modulo_txn03_authority를 인메모리 buffer(test double)로 교체해
"! 통과 논리·sy-subrc 체계·DUMMY·FOR USER를 결정적으로 검증한다.
CLASS ltcl_auth DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA buffer TYPE REF TO lcl_authority_buffer.
    DATA cut TYPE REF TO zcl_modulo_txn03_auth.

    METHODS setup.

    " AND across fields: 같은 인스턴스가 CARRID·ACTVT 모두 충족하면 통과.
    METHODS granted_when_both_fields FOR TESTING.
    " ACTVT value set에 없는 활동 -> subrc=4(value_mismatch).
    METHODS mismatch_when_wrong_actvt FOR TESTING.
    " CARRID value set에 없는 항공사 -> subrc=4.
    METHODS mismatch_when_wrong_carrier FOR TESTING.
    " object에 authorization 인스턴스 자체가 없으면 subrc=12(no_auth).
    METHODS no_auth_when_object_absent FOR TESTING.
    " 권한 분산: CARRID와 ACTVT가 서로 다른 인스턴스에 흩어지면 통과 불가(subrc=4).
    METHODS mismatch_when_split_instance FOR TESTING.
    " OR across authorizations: 두 인스턴스 중 하나만 모두 충족해도 통과.
    METHODS granted_when_one_instance_ok FOR TESTING.
    " DUMMY: CARRID를 dummy로 두면 ACTVT만 보고 통과한다.
    METHODS dummy_skips_data_field FOR TESTING.
    " FOR USER: 미등록 사용자명은 subrc=40(invalid_user).
    METHODS invalid_user_returns_40 FOR TESTING.
    " FOR USER: 등록된 사용자의 권한을 정상 평가한다.
    METHODS for_registered_user_ok FOR TESTING.
    " can_start_tcode: S_TCODE 단일 필드 체크가 buffer 부여 시 abap_true.
    METHODS tcode_granted FOR TESTING.
    " create·delete 활동 분리: 부여된 활동만 통과.
    METHODS activity_codes_are_distinct FOR TESTING.
ENDCLASS.


CLASS ltcl_auth IMPLEMENTATION.
  METHOD setup.
    buffer = NEW #( ).
    cut = NEW #( buffer ).
  ENDMETHOD.

  METHOD granted_when_both_fields.
    " 인스턴스 1에 CARRID={AA} · ACTVT={03} 부여 -> AA display 통과.
    buffer->grant_field( object = 'S_CARRID' field = 'CARRID' value_set = VALUE #( ( `AA` ) ) ).
    buffer->grant_field( object = 'S_CARRID' field = 'ACTVT'  value_set = VALUE #( ( lif_actvt=>display ) ) ).
    cl_abap_unit_assert=>assert_true( cut->can_display_carrier( 'AA' ) ).
  ENDMETHOD.

  METHOD mismatch_when_wrong_actvt.
    buffer->grant_field( object = 'S_CARRID' field = 'CARRID' value_set = VALUE #( ( `AA` ) ) ).
    buffer->grant_field( object = 'S_CARRID' field = 'ACTVT'  value_set = VALUE #( ( lif_actvt=>display ) ) ).
    " change(02) 권한은 부여되지 않음 -> VALUE_MISMATCH(subrc=4).
    cl_abap_unit_assert=>assert_equals(
      exp = `VALUE_MISMATCH`
      act = cut->classify_carrier_check( carrier = 'AA' actvt = lif_actvt=>change ) ).
  ENDMETHOD.

  METHOD mismatch_when_wrong_carrier.
    buffer->grant_field( object = 'S_CARRID' field = 'CARRID' value_set = VALUE #( ( `AA` ) ) ).
    buffer->grant_field( object = 'S_CARRID' field = 'ACTVT'  value_set = VALUE #( ( lif_actvt=>display ) ) ).
    " ZZ는 CARRID value set에 없음 -> VALUE_MISMATCH(subrc=4).
    cl_abap_unit_assert=>assert_equals(
      exp = `VALUE_MISMATCH`
      act = cut->classify_carrier_check( carrier = 'ZZ' actvt = lif_actvt=>display ) ).
  ENDMETHOD.

  METHOD no_auth_when_object_absent.
    " S_CARRID에 아무 부여도 없음 -> NO_AUTH(subrc=12).
    cl_abap_unit_assert=>assert_equals(
      exp = `NO_AUTH`
      act = cut->classify_carrier_check( carrier = 'AA' actvt = lif_actvt=>display ) ).
  ENDMETHOD.

  METHOD mismatch_when_split_instance.
    " 권한 분산: 인스턴스 1에 CARRID만, 인스턴스 2에 ACTVT만 -> 어느 인스턴스도 둘 다 못 채움.
    buffer->grant_field( object = 'S_CARRID' instance = 1 field = 'CARRID' value_set = VALUE #( ( `AA` ) ) ).
    buffer->grant_field( object = 'S_CARRID' instance = 2 field = 'ACTVT'
                         value_set = VALUE #( ( lif_actvt=>display ) ) ).
    " 인스턴스는 존재(subrc<>12)하나 어느 것도 AND 충족 못 함 -> VALUE_MISMATCH(subrc=4).
    cl_abap_unit_assert=>assert_equals(
      exp = `VALUE_MISMATCH`
      act = cut->classify_carrier_check( carrier = 'AA' actvt = lif_actvt=>display ) ).
  ENDMETHOD.

  METHOD granted_when_one_instance_ok.
    " 인스턴스 1: 불완전(CARRID만). 인스턴스 2: 완전(CARRID+ACTVT). OR로 통과.
    buffer->grant_field( object = 'S_CARRID' instance = 1 field = 'CARRID' value_set = VALUE #( ( `LH` ) ) ).
    buffer->grant_field( object = 'S_CARRID' instance = 2 field = 'CARRID' value_set = VALUE #( ( `AA` ) ) ).
    buffer->grant_field( object = 'S_CARRID' instance = 2 field = 'ACTVT'
                         value_set = VALUE #( ( lif_actvt=>display ) ) ).
    cl_abap_unit_assert=>assert_true( cut->can_display_carrier( 'AA' ) ).
  ENDMETHOD.

  METHOD dummy_skips_data_field.
    " CARRID 부여 없이 ACTVT={03}만 부여. can_do_activity는 CARRID를 DUMMY로 두므로 통과.
    buffer->grant_field( object = 'S_CARRID' field = 'ACTVT' value_set = VALUE #( ( lif_actvt=>display ) ) ).
    cl_abap_unit_assert=>assert_true( cut->can_do_activity( lif_actvt=>display ) ).
  ENDMETHOD.

  METHOD invalid_user_returns_40.
    " OTHER_USER는 register_user로 등록되지 않음 -> INVALID_USER(subrc=40).
    cl_abap_unit_assert=>assert_equals(
      exp = `INVALID_USER`
      act = cut->check_for_user( user = `OTHER_USER` carrier = 'AA' ) ).
  ENDMETHOD.

  METHOD for_registered_user_ok.
    buffer->register_user( `OTHER_USER` ).
    buffer->grant_field( user = `OTHER_USER` object = 'S_CARRID' field = 'CARRID' value_set = VALUE #( ( `AA` ) ) ).
    buffer->grant_field( user = `OTHER_USER` object = 'S_CARRID' field = 'ACTVT'
                         value_set = VALUE #( ( lif_actvt=>display ) ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = `GRANTED`
      act = cut->check_for_user( user = `OTHER_USER` carrier = 'AA' ) ).
  ENDMETHOD.

  METHOD tcode_granted.
    buffer->grant_field( object = 'S_TCODE' field = 'TCD' value_set = VALUE #( ( `SE80` ) ) ).
    cl_abap_unit_assert=>assert_true( cut->can_start_tcode( 'SE80' ) ).
  ENDMETHOD.

  METHOD activity_codes_are_distinct.
    " create(01)만 부여 -> create는 통과, delete(06)는 VALUE_MISMATCH(서로 다른 활동 코드).
    buffer->grant_field( object = 'S_CARRID' field = 'CARRID' value_set = VALUE #( ( `AA` ) ) ).
    buffer->grant_field( object = 'S_CARRID' field = 'ACTVT'  value_set = VALUE #( ( lif_actvt=>create ) ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = `GRANTED`
      act = cut->classify_carrier_check( carrier = 'AA' actvt = lif_actvt=>create ) ).
    cl_abap_unit_assert=>assert_equals(
      exp = `VALUE_MISMATCH`
      act = cut->classify_carrier_check( carrier = 'AA' actvt = lif_actvt=>delete ) ).
  ENDMETHOD.
ENDCLASS.
