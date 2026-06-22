CLASS ltcl_atc DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_tst03_atc.
    METHODS setup.
    METHODS labels_known       FOR TESTING.
    METHODS label_unknown      FOR TESTING.
    METHODS gate_block         FOR TESTING.
    METHODS gate_notify        FOR TESTING.
    METHODS min_seats_count    FOR TESTING.
    METHODS top_connid         FOR TESTING.
    METHODS numeric_true       FOR TESTING.
    METHODS numeric_false      FOR TESTING.
    METHODS baseline_exempt    FOR TESTING.
    METHODS baseline_suppress  FOR TESTING.
    METHODS exemption_reject   FOR TESTING.
    METHODS exemption_accept   FOR TESTING.
    METHODS note_ok            FOR TESTING.
    METHODS note_missing       FOR TESTING.
    METHODS token_count        FOR TESTING.
    METHODS kind_error         FOR TESTING.
    METHODS rank_top           FOR TESTING.
    METHODS rank_middle        FOR TESTING.
ENDCLASS.


CLASS ltcl_atc IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD labels_known.
    cl_abap_unit_assert=>assert_equals( act = cut->severity_label( 1 ) exp = `ERROR` ).
    cl_abap_unit_assert=>assert_equals( act = cut->severity_label( 2 ) exp = `WARNING` ).
    cl_abap_unit_assert=>assert_equals( act = cut->severity_label( 3 ) exp = `INFO` ).
  ENDMETHOD.

  METHOD label_unknown.
    cl_abap_unit_assert=>assert_equals( act = cut->severity_label( 9 ) exp = `UNKNOWN` ).
  ENDMETHOD.

  METHOD gate_block.
    " prio1·2는 운반 차단.
    cl_abap_unit_assert=>assert_equals( act = cut->transport_gate( 1 ) exp = `BLOCK` ).
    cl_abap_unit_assert=>assert_equals( act = cut->transport_gate( 2 ) exp = `BLOCK` ).
  ENDMETHOD.

  METHOD gate_notify.
    " prio3은 알림만.
    cl_abap_unit_assert=>assert_equals( act = cut->transport_gate( 3 ) exp = `NOTIFY` ).
  ENDMETHOD.

  METHOD min_seats_count.
    " 샘플 좌석 380·320·300 >= 300 -> 3건.
    cl_abap_unit_assert=>assert_equals( act = cut->count_min_seats( 300 ) exp = 3 ).
  ENDMETHOD.

  METHOD top_connid.
    " 좌석 최다 380 -> connid 0017.
    cl_abap_unit_assert=>assert_equals( act = cut->top_connid_by_seats( ) exp = '0017' ).
  ENDMETHOD.

  METHOD numeric_true.
    cl_abap_unit_assert=>assert_true( act = cut->is_numeric( `42` ) ).
  ENDMETHOD.

  METHOD numeric_false.
    cl_abap_unit_assert=>assert_false( act = cut->is_numeric( `abc` ) ).
  ENDMETHOD.

  METHOD baseline_exempt.
    cl_abap_unit_assert=>assert_equals( act = cut->baseline_mode( abap_true ) exp = `EXEMPT` ).
  ENDMETHOD.

  METHOD baseline_suppress.
    cl_abap_unit_assert=>assert_equals( act = cut->baseline_mode( abap_false ) exp = `SUPPRESS` ).
  ENDMETHOD.

  METHOD exemption_reject.
    " "복잡/단순해서"는 정당한 사유가 아니다.
    cl_abap_unit_assert=>assert_false( act = cut->exemption_valid( `TOO_COMPLEX` ) ).
    cl_abap_unit_assert=>assert_false( act = cut->exemption_valid( `TOO_SIMPLE` ) ).
  ENDMETHOD.

  METHOD exemption_accept.
    cl_abap_unit_assert=>assert_true( act = cut->exemption_valid( `FALSE_POSITIVE` ) ).
  ENDMETHOD.

  METHOD note_ok.
    cl_abap_unit_assert=>assert_equals(
      act = cut->suppression_note( pragma = `##NO_HANDLER` reason = `숫자 아님` )
      exp = `OK ##NO_HANDLER: 숫자 아님` ).
  ENDMETHOD.

  METHOD note_missing.
    cl_abap_unit_assert=>assert_equals(
      act = cut->suppression_note( pragma = `##NEEDED` reason = `` )
      exp = `REJECT ##NEEDED: missing reason` ).
  ENDMETHOD.

  METHOD token_count.
    " 'SELECT SINGLE FROM T WHERE K = @K' 토큰 중 WHERE 1회.
    cl_abap_unit_assert=>assert_equals(
      act = cut->count_tokens( statement = `SELECT SINGLE FROM t WHERE k = @k` keyword = `WHERE` )
      exp = 1 ).
    " 키워드 대소문자 무시 비교.
    cl_abap_unit_assert=>assert_equals(
      act = cut->count_tokens( statement = `SELECT SINGLE FROM t WHERE k = @k` keyword = `select` )
      exp = 1 ).
  ENDMETHOD.

  METHOD kind_error.
    cl_abap_unit_assert=>assert_equals( act = cut->inform_kind( abap_true ) exp = `ERROR` ).
    cl_abap_unit_assert=>assert_equals( act = cut->inform_kind( abap_false ) exp = `NOTE` ).
  ENDMETHOD.

  METHOD rank_top.
    cl_abap_unit_assert=>assert_equals( act = cut->category_rank( `001` ) exp = `TOP` ).
    cl_abap_unit_assert=>assert_equals( act = cut->category_rank( `999` ) exp = `BOTTOM` ).
  ENDMETHOD.

  METHOD rank_middle.
    cl_abap_unit_assert=>assert_equals( act = cut->category_rank( `500` ) exp = `MIDDLE` ).
  ENDMETHOD.
ENDCLASS.
