"! <p>ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.</p>
"! <p>인터페이스(lif_shape)·추상 클래스·INHERITING FROM·REDEFINITION·super->·FINAL,</p>
"! <p>다형성(인터페이스 ref 컬렉션의 동적 디스패치), 업/다운캐스트(CAST·IS INSTANCE OF·CASE TYPE OF).</p>
CLASS zcl_modulo_oo05_inherit DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
ENDCLASS.


CLASS zcl_modulo_oo05_inherit IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    DATA shapes TYPE STANDARD TABLE OF REF TO lif_shape WITH EMPTY KEY.

    out->write( `=== OO05 상속·다형성·인터페이스 ===` ).

    " 업캐스트: 구현 클래스 참조를 인터페이스 참조로 담는다(= 로 자동).
    " CAST는 명시 업캐스트 — 한쪽은 자동, 한쪽은 명시로 대조한다.
    APPEND NEW lcl_rectangle( width = 3 height = 4 ) TO shapes.
    APPEND NEW lcl_square( side = 5 )                TO shapes.
    APPEND CAST lif_shape( NEW lcl_circle( radius = 2 ) ) TO shapes.

    " 다형성: 같은 호출(describe)이 동적 타입에 따라 다르게 실행된다.
    LOOP AT shapes INTO DATA(shape).
      out->write( shape->describe( ) ).
    ENDLOOP.

    " 다운캐스트: IS INSTANCE OF 로 안전 확인 후 CAST.
    LOOP AT shapes INTO DATA(candidate).
      IF candidate IS INSTANCE OF lcl_circle.
        DATA(circle) = CAST lcl_circle( candidate ).
        out->write( |원 다운캐스트 성공 area = { circle->lif_shape~area( ) }| ).
      ENDIF.
    ENDLOOP.

    " CASE TYPE OF: 동적 타입별 분기(정사각형은 직사각형의 하위 타입 → 먼저 검사).
    LOOP AT shapes INTO DATA(item).
      CASE TYPE OF item.
        WHEN TYPE lcl_square.
          out->write( `분류: 정사각형` ).
        WHEN TYPE lcl_rectangle.
          out->write( `분류: 직사각형` ).
        WHEN OTHERS.
          out->write( `분류: 기타 도형` ).
      ENDCASE.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
