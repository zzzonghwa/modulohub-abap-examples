CLASS zcl_modulo_oo06_aunit DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! ADT에서 F9(Run As -> ABAP Application)로 데모를, Ctrl+Shift+F10으로 테스트를 실행한다.
    "! ABAP Unit 최소 골격: FOR TESTING/RISK LEVEL HARMLESS/DURATION SHORT,
    "! setup, GIVEN/WHEN/THEN, cl_abap_unit_assert 단언, 예외는 FAIL 패턴으로 검증.
    "! 테스트 본체는 zcl_modulo_oo06_aunit.clas.testclasses.abap 참고.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.


CLASS zcl_modulo_oo06_aunit IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== OO06 ABAP Unit 최소 사용법 ===` ).
    out->write( `CUT(lcl_stack)은 LTCL_STACK 테스트로 검증한다.` ).
    out->write( `ADT에서 Ctrl+Shift+F10(Run As -> ABAP Unit Test)으로 실행하세요.` ).

    DATA(stack) = NEW lcl_stack( ).
    stack->push( 10 ).
    stack->push( 20 ).
    stack->push( 30 ).
    out->write( |push 10,20,30 -> size={ stack->size( ) } is_empty={ stack->is_empty( ) }| ).

    TRY.
        out->write( |pop = { stack->pop( ) }| ).   " 30 (LIFO)
        out->write( |pop = { stack->pop( ) }| ).   " 20
      CATCH lcx_empty_stack.
        out->write( `예상치 못한 빈 스택` ).
    ENDTRY.
    out->write( |남은 size = { stack->size( ) }| ).

    " 빈 스택 pop은 예외 — 테스트는 이 동작을 FAIL 패턴으로 검증한다.
    DATA(empty_stack) = NEW lcl_stack( ).
    TRY.
        empty_stack->pop( ).
        out->write( `(예상과 다름) 예외가 발생하지 않음` ).
      CATCH lcx_empty_stack.
        out->write( `빈 스택 pop -> lcx_empty_stack 발생` ).
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
