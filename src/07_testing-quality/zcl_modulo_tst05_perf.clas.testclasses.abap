CLASS ltcl_perf DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_tst05_perf.
    METHODS setup.
    METHODS nested_counts      FOR TESTING.
    METHODS hashed_counts      FOR TESTING.
    METHODS sorted_counts      FOR TESTING.
    METHODS three_match_same   FOR TESTING.
    METHODS secondary_key      FOR TESTING.
    METHODS secondary_key_miss FOR TESTING.
    METHODS total_seats_same   FOR TESTING.
    METHODS exists_two_ways    FOR TESTING.
    METHODS exists_negative    FOR TESTING.
    METHODS merge_same         FOR TESTING.
    METHODS clear_vs_free      FOR TESTING.
    METHODS sum_two_ways       FOR TESTING.
    METHODS where_and_or_same  FOR TESTING.
ENDCLASS.


CLASS ltcl_perf IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD nested_counts.
    " 주문 customer_id = 100,100,200,999 중 마스터(100,200,300)에 있는 건 = 3.
    cl_abap_unit_assert=>assert_equals( act = cut->match_nested( ) exp = 3 ).
  ENDMETHOD.

  METHOD hashed_counts.
    cl_abap_unit_assert=>assert_equals( act = cut->match_hashed( ) exp = 3 ).
  ENDMETHOD.

  METHOD sorted_counts.
    cl_abap_unit_assert=>assert_equals( act = cut->match_sorted( ) exp = 3 ).
  ENDMETHOD.

  METHOD three_match_same.
    " 복잡도만 다르고 결과는 같아야 한다 — 측정 후 최적화의 전제.
    DATA(nested) = cut->match_nested( ).
    cl_abap_unit_assert=>assert_equals( act = cut->match_hashed( ) exp = nested ).
    cl_abap_unit_assert=>assert_equals( act = cut->match_sorted( ) exp = nested ).
  ENDMETHOD.

  METHOD secondary_key.
    " Beta = id 200, 주문 중 customer_id = 200 인 건 = 1.
    cl_abap_unit_assert=>assert_equals( act = cut->secondary_key_count( `Beta` ) exp = 1 ).
    " Alpha = id 100, 주문 중 customer_id = 100 인 건 = 2.
    cl_abap_unit_assert=>assert_equals( act = cut->secondary_key_count( `Alpha` ) exp = 2 ).
  ENDMETHOD.

  METHOD secondary_key_miss.
    " 없는 이름 -> 보조 키 READ 실패 -> 0.
    cl_abap_unit_assert=>assert_equals( act = cut->secondary_key_count( `Nobody` ) exp = 0 ).
  ENDMETHOD.

  METHOD total_seats_same.
    " 좌석 380+320+280+180+240+300 = 1700. FS 경로와 WA 경로는 같다.
    cl_abap_unit_assert=>assert_equals( act = cut->assign_total_seats( ) exp = 1700 ).
    cl_abap_unit_assert=>assert_equals( act = cut->into_total_seats( )   exp = 1700 ).
  ENDMETHOD.

  METHOD exists_two_ways.
    " AA 편 존재 -> 두 존재확인 방식 모두 true.
    cl_abap_unit_assert=>assert_true( act = cut->exists_no_fields( 'AA' ) ).
    cl_abap_unit_assert=>assert_true( act = cut->exists_select( 'AA' ) ).
  ENDMETHOD.

  METHOD exists_negative.
    " ZZ 편 없음 -> 두 방식 모두 false.
    cl_abap_unit_assert=>assert_false( act = cut->exists_no_fields( 'ZZ' ) ).
    cl_abap_unit_assert=>assert_false( act = cut->exists_select( 'ZZ' ) ).
  ENDMETHOD.

  METHOD merge_same.
    " 6 + 6 = 12. 블록 병합과 건별 병합 결과 동일.
    cl_abap_unit_assert=>assert_equals( act = cut->block_merge( ) exp = 12 ).
    cl_abap_unit_assert=>assert_equals( act = cut->row_by_row( )  exp = 12 ).
  ENDMETHOD.

  METHOD clear_vs_free.
    " CLEAR와 FREE는 의미가 다르나 비운 뒤 행 수는 둘 다 0.
    cl_abap_unit_assert=>assert_equals( act = cut->clear_then_size( ) exp = 0 ).
    cl_abap_unit_assert=>assert_equals( act = cut->free_then_size( )  exp = 0 ).
  ENDMETHOD.

  METHOD sum_two_ways.
    " pushdown(SELECT SUM)과 ABAP(REDUCE)은 같은 총합 1700.
    cl_abap_unit_assert=>assert_equals( act = cut->sum_pushdown( ) exp = 1700 ).
    cl_abap_unit_assert=>assert_equals( act = cut->sum_in_abap( )  exp = 1700 ).
  ENDMETHOD.

  METHOD where_and_or_same.
    " AA AND seats>=300 = {380,320} = 2. OR 표현도 같은 2.
    cl_abap_unit_assert=>assert_equals( act = cut->and_count( ) exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = cut->or_count( )  exp = 2 ).
  ENDMETHOD.
ENDCLASS.
