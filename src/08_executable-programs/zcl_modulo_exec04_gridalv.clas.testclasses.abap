CLASS ltcl_gridalv DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_exec04_gridalv.
    METHODS setup.

    "! A 컨테이너 선택.
    METHODS container_custom         FOR TESTING.
    METHODS container_docking        FOR TESTING.
    "! B 필드카탈로그·레이아웃·버퍼.
    METHODS fieldcat_has_three_cols  FOR TESTING.
    METHODS editable_columns_count   FOR TESTING.
    METHODS readonly_no_edit_columns FOR TESTING.
    METHODS i_save_labels            FOR TESTING.
    METHODS buffer_conflict_both     FOR TESTING.
    METHODS buffer_no_conflict       FOR TESTING.
    "! C 편집 이벤트·셀 스타일·LUW.
    METHODS edit_event_enter         FOR TESTING.
    METHODS edit_event_modified      FOR TESTING.
    METHODS style_table_locks_keys   FOR TESTING.
    METHODS commit_not_in_handler    FOR TESTING.
    "! D 이벤트 파라미터·툴바·hotspot.
    METHODS event_params             FOR TESTING.
    METHODS toolbar_three_buttons    FOR TESTING.
    METHODS hotspot_only_connid      FOR TESTING.
    "! E·종합.
    METHODS salv_no_edit_api         FOR TESTING.
    METHODS recommend_by_editable    FOR TESTING.
    METHODS reuse_requires_pf_status FOR TESTING.
    METHODS classic_not_cloud        FOR TESTING.
ENDCLASS.


CLASS ltcl_gridalv IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD container_custom.
    cl_abap_unit_assert=>assert_equals(
      act = cut->choose_container( abap_true ) exp = `CL_GUI_CUSTOM_CONTAINER` ).
  ENDMETHOD.

  METHOD container_docking.
    cl_abap_unit_assert=>assert_equals(
      act = cut->choose_container( abap_false ) exp = `CL_GUI_DOCKING_CONTAINER` ).
  ENDMETHOD.

  METHOD fieldcat_has_three_cols.
    cl_abap_unit_assert=>assert_equals(
      act = lines( cut->build_fieldcat( abap_true ) ) exp = 3 ).
  ENDMETHOD.

  METHOD editable_columns_count.
    " 편집 모드: 비키 컬럼 seatsocc 1개만 edit=X.
    DATA(fieldcat) = cut->build_fieldcat( abap_true ).
    cl_abap_unit_assert=>assert_equals(
      act = cut->count_editable_columns( fieldcat ) exp = 1 ).
  ENDMETHOD.

  METHOD readonly_no_edit_columns.
    DATA(fieldcat) = cut->build_fieldcat( abap_false ).
    cl_abap_unit_assert=>assert_equals(
      act = cut->count_editable_columns( fieldcat ) exp = 0 ).
  ENDMETHOD.

  METHOD i_save_labels.
    cl_abap_unit_assert=>assert_equals(
      act = cut->i_save_meaning( 'A' ) exp = `All (global + user)` ).
    cl_abap_unit_assert=>assert_equals(
      act = cut->i_save_meaning( 'U' ) exp = `User only` ).
    cl_abap_unit_assert=>assert_equals(
      act = cut->i_save_meaning( ' ' ) exp = `No save` ).
    " 'X'는 문서 근거 미확인(노트 B-6).
    cl_abap_unit_assert=>assert_equals(
      act = cut->i_save_meaning( 'X' ) exp = `Undocumented` ).
  ENDMETHOD.

  METHOD buffer_conflict_both.
    cl_abap_unit_assert=>assert_true(
      cut->buffer_conflict( buffer_active = abap_true bypassing_buffer = abap_true ) ).
  ENDMETHOD.

  METHOD buffer_no_conflict.
    cl_abap_unit_assert=>assert_false(
      cut->buffer_conflict( buffer_active = abap_true bypassing_buffer = abap_false ) ).
  ENDMETHOD.

  METHOD edit_event_enter.
    cl_abap_unit_assert=>assert_equals(
      act = cut->edit_event_constant( abap_true ) exp = zcl_modulo_exec04_gridalv=>event_enter ).
  ENDMETHOD.

  METHOD edit_event_modified.
    cl_abap_unit_assert=>assert_equals(
      act = cut->edit_event_constant( abap_false ) exp = zcl_modulo_exec04_gridalv=>event_modified ).
  ENDMETHOD.

  METHOD style_table_locks_keys.
    DATA(fieldcat) = cut->build_fieldcat( abap_true ).
    DATA(styles) = cut->build_style_table( fieldcat ).
    " 3칸: carrid/connid는 키 -> disabled, seatsocc -> enabled.
    cl_abap_unit_assert=>assert_equals( act = lines( styles ) exp = 3 ).
    cl_abap_unit_assert=>assert_equals(
      act = styles[ fieldname = 'CARRID' ]-style
      exp = zcl_modulo_exec04_gridalv=>style_disabled ).
    cl_abap_unit_assert=>assert_equals(
      act = styles[ fieldname = 'SEATSOCC' ]-style
      exp = zcl_modulo_exec04_gridalv=>style_enabled ).
  ENDMETHOD.

  METHOD commit_not_in_handler.
    " data_changed 핸들러 안에서는 COMMIT 금지.
    cl_abap_unit_assert=>assert_false( cut->commit_allowed_here( abap_true ) ).
    cl_abap_unit_assert=>assert_true( cut->commit_allowed_here( abap_false ) ).
  ENDMETHOD.

  METHOD event_params.
    cl_abap_unit_assert=>assert_equals(
      act = cut->event_param( `data_changed` ) exp = `er_data_changed` ).
    cl_abap_unit_assert=>assert_equals(
      act = cut->event_param( `user_command` ) exp = `e_ucomm` ).
    cl_abap_unit_assert=>assert_equals(
      act = cut->event_param( `toolbar` ) exp = `e_object` ).
    cl_abap_unit_assert=>assert_equals(
      act = cut->event_param( `hotspot_click` ) exp = `e_row_id` ).
    " after_refresh는 핵심 IMPORTING 파라미터가 없다.
    cl_abap_unit_assert=>assert_initial( cut->event_param( `after_refresh` ) ).
  ENDMETHOD.

  METHOD toolbar_three_buttons.
    cl_abap_unit_assert=>assert_equals(
      act = lines( cut->build_toolbar( ) ) exp = 3 ).
  ENDMETHOD.

  METHOD hotspot_only_connid.
    DATA(fieldcat) = cut->build_fieldcat( abap_true ).
    DATA(columns) = cut->hotspot_columns( fieldcat ).
    cl_abap_unit_assert=>assert_equals( act = lines( columns ) exp = 1 ).
    cl_abap_unit_assert=>assert_equals( act = columns[ 1 ] exp = `CONNID` ).
  ENDMETHOD.

  METHOD salv_no_edit_api.
    cl_abap_unit_assert=>assert_false( cut->salv_edit_supported( ) ).
  ENDMETHOD.

  METHOD recommend_by_editable.
    cl_abap_unit_assert=>assert_equals(
      act = cut->recommend_alv( abap_true ) exp = `CL_GUI_ALV_GRID` ).
    cl_abap_unit_assert=>assert_equals(
      act = cut->recommend_alv( abap_false ) exp = `CL_SALV_TABLE` ).
  ENDMETHOD.

  METHOD reuse_requires_pf_status.
    cl_abap_unit_assert=>assert_true( cut->reuse_needs_pf_status( ) ).
  ENDMETHOD.

  METHOD classic_not_cloud.
    cl_abap_unit_assert=>assert_false( cut->cloud_available( ) ).
  ENDMETHOD.
ENDCLASS.
