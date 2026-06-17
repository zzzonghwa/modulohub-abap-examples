"! 테스트 클래스명은 무엇을 테스트하는지로(Clean ABAP). 골격은 FOR TESTING +
"! RISK LEVEL HARMLESS(시스템·영속 데이터 변경 없음) + DURATION SHORT(수 초).
CLASS ltcl_stack DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO lcl_stack.   "CUT = code under test
    METHODS setup.
    METHODS new_stack_is_empty   FOR TESTING.
    METHODS push_increases_size  FOR TESTING.
    METHODS pop_returns_last_in  FOR TESTING.
    METHODS pop_reduces_size     FOR TESTING.
    METHODS pop_empty_raises     FOR TESTING.
ENDCLASS.


CLASS ltcl_stack IMPLEMENTATION.
  " 각 테스트 직전 깨끗한 CUT을 만든다. 단순 초기화는 setup이 덮어쓰므로 teardown 불필요.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD new_stack_is_empty.
    " THEN 새 스택은 비어 있고 크기는 0.
    cl_abap_unit_assert=>assert_bound( cut ).
    cl_abap_unit_assert=>assert_true( cut->is_empty( ) ).
    cl_abap_unit_assert=>assert_initial( cut->size( ) ).
  ENDMETHOD.

  METHOD push_increases_size.
    " GIVEN 빈 스택 / WHEN 한 개 push / THEN 크기 1, 더 이상 비어있지 않음.
    cut->push( 10 ).

    cl_abap_unit_assert=>assert_equals( act = cut->size( ) exp = 1 ).
    cl_abap_unit_assert=>assert_false( cut->is_empty( ) ).
  ENDMETHOD.

  METHOD pop_returns_last_in.
    " GIVEN 1,2,3을 쌓고 / WHEN 한 번 pop / THEN 마지막에 넣은 3(LIFO).
    cut->push( 1 ).
    cut->push( 2 ).
    cut->push( 3 ).

    DATA(popped) = cut->pop( ).

    cl_abap_unit_assert=>assert_equals( act = popped exp = 3 ).
  ENDMETHOD.

  METHOD pop_reduces_size.
    cut->push( 1 ).
    cut->push( 2 ).

    cut->pop( ).

    cl_abap_unit_assert=>assert_equals( act = cut->size( ) exp = 1 ).
  ENDMETHOD.

  METHOD pop_empty_raises.
    " 기대 예외 검증의 표준 패턴: 호출 -> fail( ) -> 기대 예외 CATCH.
    TRY.
        cut->pop( ).
        cl_abap_unit_assert=>fail( `빈 스택 pop은 예외여야 한다` ).
      CATCH lcx_empty_stack.
        " 기대대로 예외 발생 — 통과.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
