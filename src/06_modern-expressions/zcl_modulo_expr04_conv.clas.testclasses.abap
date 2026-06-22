CLASS ltcl_conv DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_expr04_conv.
    METHODS setup.
    " CONV
    METHODS conv_string_to_int  FOR TESTING.
    METHODS conv_to_amount      FOR TESTING.
    METHODS conv_infer_hash     FOR TESTING.
    METHODS conv_table_kind     FOR TESTING.
    METHODS conv_calc_type      FOR TESTING.
    " CAST
    METHODS cast_downcast       FOR TESTING.
    METHODS cast_guarded_hit    FOR TESTING.
    METHODS cast_guarded_miss   FOR TESTING.
    METHODS cast_deref_write    FOR TESTING.
    METHODS cast_new_combo      FOR TESTING.
    " REF
    METHODS ref_mutates_source  FOR TESTING.
    METHODS ref_table_row_hit   FOR TESTING.
    METHODS ref_table_row_miss  FOR TESTING.
    METHODS ref_object          FOR TESTING.
    " EXACT
    METHODS exact_lossless      FOR TESTING.
    METHODS exact_lossy_guard   FOR TESTING.
    METHODS exact_vs_conv       FOR TESTING.
    METHODS exact_calc_ok       FOR TESTING.
    METHODS exact_calc_rounding FOR TESTING.
ENDCLASS.


CLASS ltcl_conv IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD conv_string_to_int.
    cl_abap_unit_assert=>assert_equals( act = cut->to_integer( `42` ) exp = 42 ).
  ENDMETHOD.

  METHOD conv_to_amount.
    " '3.14' -> p LENGTH 8 DECIMALS 2 = 3.14 (소수 2자리 무손실).
    cl_abap_unit_assert=>assert_equals( act = cut->conv_to_amount( `3.14` ) exp = '3.14' ).
  ENDMETHOD.

  METHOD conv_infer_hash.
    " amount 2.6 -> i는 반올림 -> 3. #는 RETURNING 타입 i를 추론.
    cl_abap_unit_assert=>assert_equals( act = cut->conv_infer_hash( '2.6' ) exp = 3 ).
  ENDMETHOD.

  METHOD conv_table_kind.
    " SORTED 2행 -> STANDARD 변환 후에도 2행.
    cl_abap_unit_assert=>assert_equals( act = cut->conv_table_kind( ) exp = 2 ).
  ENDMETHOD.

  METHOD conv_calc_type.
    " 1/5(정수나눗셈)=0, ×10=0. 1.0/5(소수)=0.2, ×10=2. 합 2.
    cl_abap_unit_assert=>assert_equals( act = cut->conv_calc_type( ) exp = 2 ).
  ENDMETHOD.

  METHOD cast_downcast.
    cl_abap_unit_assert=>assert_equals( act = cut->cast_dog_fetch( ) exp = `fetch!` ).
  ENDMETHOD.

  METHOD cast_guarded_hit.
    " lcl_dog 인스턴스 -> IS INSTANCE OF 통과 -> fetch.
    cl_abap_unit_assert=>assert_equals( act = cut->cast_guarded( abap_true ) exp = `fetch!` ).
  ENDMETHOD.

  METHOD cast_guarded_miss.
    " lcl_animal 인스턴스 -> IS INSTANCE OF 실패 -> 공백(예외 회피).
    cl_abap_unit_assert=>assert_equals( act = cut->cast_guarded( abap_false ) exp = `` ).
  ENDMETHOD.

  METHOD cast_deref_write.
    cl_abap_unit_assert=>assert_equals( act = cut->cast_deref_write( ) exp = `abap` ).
  ENDMETHOD.

  METHOD cast_new_combo.
    " CAST lcl_animal( NEW lcl_dog( ) ) -> 동적 타입은 lcl_dog -> sound = Woof.
    cl_abap_unit_assert=>assert_equals( act = cut->cast_new_combo( ) exp = `Woof` ).
  ENDMETHOD.

  METHOD ref_mutates_source.
    cl_abap_unit_assert=>assert_equals( act = cut->bump_via_ref( ) exp = 15 ).
  ENDMETHOD.

  METHOD ref_table_row_hit.
    " values = (10 20 30), 2번째 = 20.
    cl_abap_unit_assert=>assert_equals( act = cut->ref_table_row( 2 ) exp = 20 ).
  ENDMETHOD.

  METHOD ref_table_row_miss.
    " 9번째 행 없음 -> OPTIONAL null -> 가드로 -1.
    cl_abap_unit_assert=>assert_equals( act = cut->ref_table_row( 9 ) exp = -1 ).
  ENDMETHOD.

  METHOD ref_object.
    " 같은 인스턴스를 가리키는 복사 참조 -> sound = Woof.
    cl_abap_unit_assert=>assert_equals( act = cut->ref_object( ) exp = `Woof` ).
  ENDMETHOD.

  METHOD exact_lossless.
    cl_abap_unit_assert=>assert_equals( act = cut->exact_int( '4' ) exp = 4 ).
  ENDMETHOD.

  METHOD exact_lossy_guard.
    " 4.5는 정수로 무손실 변환 불가 -> EXACT가 예외 -> -1.
    cl_abap_unit_assert=>assert_equals( act = cut->exact_int( '4.5' ) exp = -1 ).
  ENDMETHOD.

  METHOD exact_vs_conv.
    " EXACT는 'abcd' 잘림을 예외 처리 -> '!!!', CONV는 조용히 'abc'. -> '!!!/abc'.
    cl_abap_unit_assert=>assert_equals( act = cut->exact_vs_conv_truncate( ) exp = `!!!/abc` ).
  ENDMETHOD.

  METHOD exact_calc_ok.
    " 1.0/4 = 0.25는 소수 2자리에 정확히 담김 -> 0.25.
    cl_abap_unit_assert=>assert_equals( act = cut->exact_calc( 4 ) exp = '0.25' ).
  ENDMETHOD.

  METHOD exact_calc_rounding.
    " 1.0/3 = 0.333...은 소수 2자리로 반올림 필요 -> ROUNDING 예외 -> -1.
    cl_abap_unit_assert=>assert_equals( act = cut->exact_calc( 3 ) exp = '-1' ).
  ENDMETHOD.
ENDCLASS.
