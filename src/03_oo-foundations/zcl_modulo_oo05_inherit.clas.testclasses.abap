CLASS ltcl_shapes DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS rectangle_area          FOR TESTING.
    METHODS square_reuses_area      FOR TESTING.
    METHODS circle_area_uses_pi     FOR TESTING.
    METHODS describe_includes_kind  FOR TESTING.
    METHODS polymorphic_dispatch    FOR TESTING.
    METHODS square_is_a_rectangle   FOR TESTING.
    METHODS circle_is_not_rectangle FOR TESTING.
    METHODS downcast_ok             FOR TESTING.
    METHODS downcast_wrong_type     FOR TESTING.
ENDCLASS.


CLASS ltcl_shapes IMPLEMENTATION.
  METHOD rectangle_area.
    DATA(rectangle) = NEW lcl_rectangle( width = 3 height = 4 ).
    cl_abap_unit_assert=>assert_equals(
      act = rectangle->lif_shape~area( )
      exp = CONV decfloat34( 12 ) ).
  ENDMETHOD.

  METHOD square_reuses_area.
    " 정사각형은 직사각형의 area 구현을 상속해 변*변을 계산한다.
    DATA(square) = NEW lcl_square( side = 5 ).
    cl_abap_unit_assert=>assert_equals(
      act = square->lif_shape~area( )
      exp = CONV decfloat34( 25 ) ).
  ENDMETHOD.

  METHOD circle_area_uses_pi.
    DATA(circle) = NEW lcl_circle( radius = 2 ).
    " 반지름 2 -> 약 12.566. 부동 표기 흔들림을 피해 범위로 검증한다.
    cl_abap_unit_assert=>assert_number_between(
      number = circle->lif_shape~area( )
      lower  = CONV decfloat34( '12.56' )
      upper  = CONV decfloat34( '12.57' ) ).
  ENDMETHOD.

  METHOD describe_includes_kind.
    " describe(공통 구현)가 하위 타입의 kind를 엮는다 — 패턴 비교로 표기 무관 검증.
    DATA(square) = NEW lcl_square( side = 1 ).
    cl_abap_unit_assert=>assert_char_cp(
      act = square->lif_shape~describe( )
      exp = `Square*` ).
  ENDMETHOD.

  METHOD polymorphic_dispatch.
    DATA shapes TYPE STANDARD TABLE OF REF TO lif_shape WITH EMPTY KEY.
    APPEND NEW lcl_rectangle( width = 2 height = 2 ) TO shapes.
    APPEND NEW lcl_circle( radius = 1 )             TO shapes.

    " 같은 호출이 동적 타입에 따라 다른 구현으로 디스패치된다.
    DATA(first)  = shapes[ 1 ]->describe( ).
    DATA(second) = shapes[ 2 ]->describe( ).
    cl_abap_unit_assert=>assert_char_cp( act = first  exp = `Rectangle*` ).
    cl_abap_unit_assert=>assert_char_cp( act = second exp = `Circle*` ).
  ENDMETHOD.

  METHOD square_is_a_rectangle.
    DATA(square) = NEW lcl_square( side = 1 ).
    cl_abap_unit_assert=>assert_true( xsdbool( square IS INSTANCE OF lcl_rectangle ) ).
  ENDMETHOD.

  METHOD circle_is_not_rectangle.
    DATA(shape) = CAST lif_shape( NEW lcl_circle( radius = 1 ) ).
    cl_abap_unit_assert=>assert_false( xsdbool( shape IS INSTANCE OF lcl_rectangle ) ).
  ENDMETHOD.

  METHOD downcast_ok.
    DATA(shape) = CAST lif_shape( NEW lcl_circle( radius = 2 ) ).
    DATA(circle) = CAST lcl_circle( shape ).
    cl_abap_unit_assert=>assert_bound( circle ).
  ENDMETHOD.

  METHOD downcast_wrong_type.
    DATA(shape) = CAST lif_shape( NEW lcl_rectangle( width = 1 height = 1 ) ).
    " 직사각형을 원으로 다운캐스트하면 런타임 캐스트 예외.
    TRY.
        DATA(circle) = CAST lcl_circle( shape ).
        cl_abap_unit_assert=>fail( |잘못된 다운캐스트는 예외여야 한다 { circle->lif_shape~area( ) }| ).
      CATCH cx_sy_move_cast_error.
        " 기대대로 예외 발생 — 통과.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
