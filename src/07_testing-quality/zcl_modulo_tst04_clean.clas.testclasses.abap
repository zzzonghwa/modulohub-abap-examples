CLASS ltcl_clean DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_tst04_clean.
    METHODS setup.
    METHODS weekend_true       FOR TESTING.
    METHODS weekend_false      FOR TESTING.
    METHODS has_content_true   FOR TESTING.
    METHODS has_content_false  FOR TESTING.
    METHODS discount_tiers     FOR TESTING.
    METHODS light_action_cases FOR TESTING.
    METHODS first_word_normal  FOR TESTING.
    METHODS first_word_guard   FOR TESTING.
    METHODS bookable_cases     FOR TESTING.
    METHODS commit_is_stateful FOR TESTING.
    METHODS workdays_value_for FOR TESTING.
    METHODS total_reduce       FOR TESTING.
    METHODS summarize_corr     FOR TESTING.
ENDCLASS.


CLASS ltcl_clean IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD weekend_true.
    cl_abap_unit_assert=>assert_true( act = cut->is_weekend( 6 ) ).
    cl_abap_unit_assert=>assert_true( act = cut->is_weekend( 7 ) ).
  ENDMETHOD.

  METHOD weekend_false.
    cl_abap_unit_assert=>assert_false( act = cut->is_weekend( 3 ) ).
  ENDMETHOD.

  METHOD has_content_true.
    cl_abap_unit_assert=>assert_true( act = cut->has_content( ` abap ` ) ).
  ENDMETHOD.

  METHOD has_content_false.
    " condense가 공백만 있는 입력을 비움 -> abap_false.
    cl_abap_unit_assert=>assert_false( act = cut->has_content( `   ` ) ).
    cl_abap_unit_assert=>assert_false( act = cut->has_content( `` ) ).
  ENDMETHOD.

  METHOD discount_tiers.
    cl_abap_unit_assert=>assert_equals( act = cut->discount_rate( `GOLD` )   exp = 20 ).
    cl_abap_unit_assert=>assert_equals( act = cut->discount_rate( `SILVER` ) exp = 10 ).
    cl_abap_unit_assert=>assert_equals( act = cut->discount_rate( `NONE` )   exp = 0 ).
  ENDMETHOD.

  METHOD light_action_cases.
    cl_abap_unit_assert=>assert_equals( act = cut->light_action( zcl_modulo_tst04_clean=>go )
                                        exp = `DRIVE` ).
    cl_abap_unit_assert=>assert_equals( act = cut->light_action( zcl_modulo_tst04_clean=>caution )
                                        exp = `SLOW` ).
    cl_abap_unit_assert=>assert_equals( act = cut->light_action( zcl_modulo_tst04_clean=>stop )
                                        exp = `HALT` ).
    cl_abap_unit_assert=>assert_initial( act = cut->light_action( zcl_modulo_tst04_clean=>unknown ) ).
  ENDMETHOD.

  METHOD first_word_normal.
    cl_abap_unit_assert=>assert_equals( act = cut->first_word( `hello abap world` ) exp = `hello` ).
    cl_abap_unit_assert=>assert_equals( act = cut->first_word( `single` )           exp = `single` ).
  ENDMETHOD.

  METHOD first_word_guard.
    cl_abap_unit_assert=>assert_initial( act = cut->first_word( `` ) ).
  ENDMETHOD.

  METHOD bookable_cases.
    cl_abap_unit_assert=>assert_true( act = cut->is_bookable( seats = 120 cancelled = abap_false ) ).
    cl_abap_unit_assert=>assert_false( act = cut->is_bookable( seats = 0 cancelled = abap_false ) ).
    cl_abap_unit_assert=>assert_false( act = cut->is_bookable( seats = 120 cancelled = abap_true ) ).
  ENDMETHOD.

  METHOD commit_is_stateful.
    " commit 변형은 누계를 갱신한다: 100 -> 150.
    cl_abap_unit_assert=>assert_equals( act = cut->add_and_commit( 100 ) exp = 100 ).
    cl_abap_unit_assert=>assert_equals( act = cut->add_and_commit( 50 )  exp = 150 ).
    " no-commit 변형은 누계(150)에 amount만 더해 반환하고 상태는 유지한다.
    cl_abap_unit_assert=>assert_equals( act = cut->add_without_commit( 30 ) exp = 180 ).
    cl_abap_unit_assert=>assert_equals( act = cut->add_and_commit( 0 )      exp = 150 ).
  ENDMETHOD.

  METHOD workdays_value_for.
    DATA(days) = cut->workdays( ).
    cl_abap_unit_assert=>assert_equals( act = lines( days ) exp = 5 ).
    DATA(total_hours) = REDUCE i( INIT sum = 0 FOR day IN days NEXT sum = sum + day-hours ).
    cl_abap_unit_assert=>assert_equals( act = total_hours exp = 40 ).
  ENDMETHOD.

  METHOD total_reduce.
    " 2*50 + 3*30 + 1*75 = 265.
    DATA(lines) = VALUE zcl_modulo_tst04_clean=>order_lines(
      ( sku = `A-100` quantity = 2 price = 50 )
      ( sku = `B-200` quantity = 3 price = 30 )
      ( sku = `C-300` quantity = 1 price = 75 ) ).
    cl_abap_unit_assert=>assert_equals( act = cut->total_amount( lines ) exp = 265 ).
  ENDMETHOD.

  METHOD summarize_corr.
    DATA(lines) = VALUE zcl_modulo_tst04_clean=>order_lines(
      ( sku = `A-100` quantity = 2 price = 50 )
      ( sku = `B-200` quantity = 3 price = 30 ) ).
    DATA(summaries) = cut->summarize( lines ).
    cl_abap_unit_assert=>assert_equals( act = lines( summaries ) exp = 2 ).
    cl_abap_unit_assert=>assert_equals( act = summaries[ 1 ]-sku    exp = `A-100` ).
    cl_abap_unit_assert=>assert_equals( act = summaries[ 1 ]-amount exp = 100 ).
    cl_abap_unit_assert=>assert_equals( act = summaries[ 2 ]-amount exp = 90 ).
  ENDMETHOD.
ENDCLASS.
