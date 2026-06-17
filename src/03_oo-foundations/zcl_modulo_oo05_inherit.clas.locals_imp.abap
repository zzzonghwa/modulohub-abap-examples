"! 공개 계약(contract)을 인터페이스로 분리한다 — 모든 구현 도형이 공유하는 다형 인터페이스.
INTERFACE lif_shape.
  METHODS area     RETURNING VALUE(result) TYPE decfloat34.
  METHODS describe RETURNING VALUE(result) TYPE string.
ENDINTERFACE.


"! 추상 기반 클래스 — 인스턴스화 불가. area는 추상(서브클래스 구현),
"! describe는 공통 구현(템플릿 메서드: 하위 타입의 area·kind를 엮는다).
CLASS lcl_shape DEFINITION ABSTRACT CREATE PUBLIC.
  PUBLIC SECTION.
    " 인터페이스의 area만 추상으로 남기고 describe는 이 클래스에서 구현한다.
    INTERFACES lif_shape ABSTRACT METHODS area.
  PROTECTED SECTION.
    "! 도형 이름 — 서브클래스가 제공한다(추상 메서드).
    METHODS kind ABSTRACT RETURNING VALUE(result) TYPE string.
ENDCLASS.

CLASS lcl_shape IMPLEMENTATION.
  METHOD lif_shape~describe.
    result = |{ kind( ) }: area = { lif_shape~area( ) }|.
  ENDMETHOD.
ENDCLASS.


"! 직사각형 — 추상 기반을 상속하고 area·kind를 재정의(REDEFINITION)한다.
CLASS lcl_rectangle DEFINITION INHERITING FROM lcl_shape CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS constructor
      IMPORTING width  TYPE decfloat34
                height TYPE decfloat34.
    METHODS lif_shape~area REDEFINITION.
  PROTECTED SECTION.
    METHODS kind REDEFINITION.
  PRIVATE SECTION.
    DATA width  TYPE decfloat34.
    DATA height TYPE decfloat34.
ENDCLASS.

CLASS lcl_rectangle IMPLEMENTATION.
  METHOD constructor.
    " 서브클래스 생성자는 super->constructor( )를 먼저 호출해야 한다.
    super->constructor( ).
    me->width  = width.
    me->height = height.
  ENDMETHOD.

  METHOD lif_shape~area.
    result = width * height.
  ENDMETHOD.

  METHOD kind.
    result = `Rectangle`.
  ENDMETHOD.
ENDCLASS.


"! 정사각형 — FINAL(더 이상 상속 불가). 직사각형을 상속해 area 구현을 재사용하고,
"! super->constructor( )로 너비=높이=변 길이를 위임한다.
CLASS lcl_square DEFINITION INHERITING FROM lcl_rectangle FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS constructor
      IMPORTING side TYPE decfloat34.
  PROTECTED SECTION.
    METHODS kind REDEFINITION.
ENDCLASS.

CLASS lcl_square IMPLEMENTATION.
  METHOD constructor.
    super->constructor( width = side height = side ).
  ENDMETHOD.

  METHOD kind.
    result = `Square`.
  ENDMETHOD.
ENDCLASS.


"! 원 — 추상 기반을 직접 상속하는 별도 가지(직사각형과 무관).
CLASS lcl_circle DEFINITION INHERITING FROM lcl_shape FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS constructor
      IMPORTING radius TYPE decfloat34.
    METHODS lif_shape~area REDEFINITION.
  PROTECTED SECTION.
    METHODS kind REDEFINITION.
  PRIVATE SECTION.
    CONSTANTS pi TYPE decfloat34 VALUE '3.14159265358979'.
    DATA radius TYPE decfloat34.
ENDCLASS.

CLASS lcl_circle IMPLEMENTATION.
  METHOD constructor.
    super->constructor( ).
    me->radius = radius.
  ENDMETHOD.

  METHOD lif_shape~area.
    result = pi * radius * radius.
  ENDMETHOD.

  METHOD kind.
    result = `Circle`.
  ENDMETHOD.
ENDCLASS.
