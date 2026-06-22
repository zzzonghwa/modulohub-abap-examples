CLASS ltcl_cte DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CLASS-DATA environment TYPE REF TO if_osql_test_environment.
    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.

    DATA cut TYPE REF TO zcl_modulo_sql05_cte.
    METHODS setup.
    METHODS cte_high_threshold  FOR TESTING.
    METHODS cte_low_threshold   FOR TESTING.
    METHODS cte_join_master     FOR TESTING.
    METHODS cte_named_columns   FOR TESTING.
    METHODS cte_union_inside    FOR TESTING.
    METHODS scalar_subquery     FOR TESTING.
    METHODS in_subquery         FOR TESTING.
    METHODS exists_subquery     FOR TESTING.
    METHODS not_exists_subquery FOR TESTING.
    METHODS union_all           FOR TESTING.
    METHODS intersect_semantics FOR TESTING.
    METHODS except_semantics    FOR TESTING.
    METHODS itab_join           FOR TESTING.
ENDCLASS.


CLASS ltcl_cte IMPLEMENTATION.
  METHOD class_setup.
    environment = cl_osql_test_environment=>create(
      i_dependency_list = VALUE #( ( 'ZMODULO_FLIGHT' ) ( 'ZMODULO_CARRIER' ) ) ).
  ENDMETHOD.

  METHOD class_teardown.
    environment->destroy( ).
  ENDMETHOD.

  METHOD setup.
    DATA flights  TYPE STANDARD TABLE OF zmodulo_flight WITH EMPTY KEY.
    DATA carriers TYPE STANDARD TABLE OF zmodulo_carrier WITH EMPTY KEY.

    environment->clear_doubles( ).
    cut = NEW #( ).

    " 마스터 AA·LH·UA(3개). XX 마스터는 없음(차집합·NOT EXISTS 데모).
    carriers = VALUE #( ( carrid = 'AA' carrname = 'Alpha Air' )
                        ( carrid = 'LH' carrname = 'Luft Air' )
                        ( carrid = 'UA' carrname = 'Union Air' ) ).

    " AA·LH 각 2편, UA·XX 각 1편. 합계 AA=700, LH=460, UA=240, XX=100.
    " 전체 평균 좌석 = (380+320+280+180+240+100)/6 = 1500/6 = 250.
    flights = VALUE #( ( carrid = 'AA' connid = '0017' seatsmax = 380 )
                       ( carrid = 'AA' connid = '0064' seatsmax = 320 )
                       ( carrid = 'LH' connid = '0400' seatsmax = 280 )
                       ( carrid = 'LH' connid = '2402' seatsmax = 180 )
                       ( carrid = 'UA' connid = '0941' seatsmax = 240 )
                       ( carrid = 'XX' connid = '0001' seatsmax = 100 ) ).

    environment->insert_test_data( i_data = carriers ).
    environment->insert_test_data( i_data = flights ).
  ENDMETHOD.

  METHOD cte_high_threshold.
    " 합계 > 500: AA(700) -> 1.
    cl_abap_unit_assert=>assert_equals( act = cut->cte_carriers_over( 500 ) exp = 1 ).
  ENDMETHOD.

  METHOD cte_low_threshold.
    " 합계 > 400: AA(700)·LH(460) -> 2.
    cl_abap_unit_assert=>assert_equals( act = cut->cte_carriers_over( 400 ) exp = 2 ).
  ENDMETHOD.

  METHOD cte_join_master.
    " 합계 > 400(AA·LH)과 마스터 INNER JOIN: 둘 다 마스터 존재 -> 2.
    cl_abap_unit_assert=>assert_equals( act = cut->cte_join_master( 400 ) exp = 2 ).
  ENDMETHOD.

  METHOD cte_named_columns.
    " carrid별 그룹: AA·LH·UA·XX -> 4.
    cl_abap_unit_assert=>assert_equals( act = cut->cte_named_columns( ) exp = 4 ).
  ENDMETHOD.

  METHOD cte_union_inside.
    " flight 항공사{AA,LH,UA,XX} UNION carrier{AA,LH,UA} = {AA,LH,UA,XX} -> 4.
    cl_abap_unit_assert=>assert_equals( act = cut->cte_union_inside( ) exp = 4 ).
  ENDMETHOD.

  METHOD scalar_subquery.
    " 평균(250) 초과: 380·320·280 -> 3.
    cl_abap_unit_assert=>assert_equals( act = cut->above_average_count( ) exp = 3 ).
  ENDMETHOD.

  METHOD in_subquery.
    " 2편 이상 운항(AA·LH)의 항공편 -> 4.
    cl_abap_unit_assert=>assert_equals( act = cut->busy_carrier_flights( ) exp = 4 ).
  ENDMETHOD.

  METHOD exists_subquery.
    " 마스터 존재 항공편: AA(2)·LH(2)·UA(1) -> 5. XX는 마스터 없음.
    cl_abap_unit_assert=>assert_equals( act = cut->flights_with_master( ) exp = 5 ).
  ENDMETHOD.

  METHOD not_exists_subquery.
    " 마스터 없는 고아 항공편: XX/0001 -> 1.
    cl_abap_unit_assert=>assert_equals( act = cut->orphan_flights( ) exp = 1 ).
  ENDMETHOD.

  METHOD union_all.
    " 좌석 >=300(2편) + <300(4편) = 전체 6편(겹침 없음) -> 6.
    cl_abap_unit_assert=>assert_equals( act = cut->union_all_count( ) exp = 6 ).
  ENDMETHOD.

  METHOD intersect_semantics.
    " 다편 운항{AA,LH} ∩ 평균 초과편 보유{AA,LH} -> 2.
    cl_abap_unit_assert=>assert_equals( act = cut->intersect_count( ) exp = 2 ).
  ENDMETHOD.

  METHOD except_semantics.
    " 항공편 항공사{AA,LH,UA,XX} - 마스터{AA,LH,UA} = {XX} -> 1.
    cl_abap_unit_assert=>assert_equals( act = cut->except_count( ) exp = 1 ).
  ENDMETHOD.

  METHOD itab_join.
    " @itab(AA·LH)과 JOIN: AA·LH 항공편 -> 4.
    cl_abap_unit_assert=>assert_equals(
      act = cut->join_internal_table( VALUE #( ( `AA` ) ( `LH` ) ) )
      exp = 4 ).
  ENDMETHOD.
ENDCLASS.
