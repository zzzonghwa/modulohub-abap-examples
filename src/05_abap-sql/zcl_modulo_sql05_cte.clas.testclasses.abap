CLASS ltcl_cte DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    CLASS-DATA environment TYPE REF TO if_osql_test_environment.
    CLASS-METHODS class_setup.
    CLASS-METHODS class_teardown.

    DATA cut TYPE REF TO zcl_modulo_sql05_cte.
    METHODS setup.
    METHODS cte_high_threshold FOR TESTING.
    METHODS cte_low_threshold  FOR TESTING.
    METHODS scalar_subquery    FOR TESTING.
    METHODS in_subquery        FOR TESTING.
ENDCLASS.


CLASS ltcl_cte IMPLEMENTATION.
  METHOD class_setup.
    environment = cl_osql_test_environment=>create(
      i_dependency_list = VALUE #( ( 'ZMODULO_FLIGHT' ) ) ).
  ENDMETHOD.

  METHOD class_teardown.
    environment->destroy( ).
  ENDMETHOD.

  METHOD setup.
    DATA flights TYPE STANDARD TABLE OF zmodulo_flight WITH EMPTY KEY.

    environment->clear_doubles( ).
    cut = NEW #( ).

    " AA·LH 각 2편, UA 1편. 합계 AA=700, LH=460, UA=240. 평균 좌석=280.
    flights = VALUE #( ( carrid = 'AA' connid = '0017' seatsmax = 380 )
                       ( carrid = 'AA' connid = '0064' seatsmax = 320 )
                       ( carrid = 'LH' connid = '0400' seatsmax = 280 )
                       ( carrid = 'LH' connid = '2402' seatsmax = 180 )
                       ( carrid = 'UA' connid = '0941' seatsmax = 240 ) ).
    environment->insert_test_data( i_data = flights ).
  ENDMETHOD.

  METHOD cte_high_threshold.
    cl_abap_unit_assert=>assert_equals( act = cut->cte_carriers_over( 500 ) exp = 1 ).
  ENDMETHOD.

  METHOD cte_low_threshold.
    cl_abap_unit_assert=>assert_equals( act = cut->cte_carriers_over( 400 ) exp = 2 ).
  ENDMETHOD.

  METHOD scalar_subquery.
    " 평균(280) 초과: 380·320 -> 2.
    cl_abap_unit_assert=>assert_equals( act = cut->above_average_count( ) exp = 2 ).
  ENDMETHOD.

  METHOD in_subquery.
    " 2편 이상 운항(AA·LH)의 항공편 -> 4.
    cl_abap_unit_assert=>assert_equals( act = cut->busy_carrier_flights( ) exp = 4 ).
  ENDMETHOD.
ENDCLASS.
