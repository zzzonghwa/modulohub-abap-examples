"! 모듈화의 단위 = 메서드. 인스턴스/정적/함수형 메서드를 한 클래스에서 대조한다.
CLASS lcl_counter DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS constructor
      IMPORTING start TYPE i DEFAULT 0.

    "! 인스턴스 메서드 — 객체 상태(count)를 바꾼다. 반환값 없음.
    METHODS increment
      IMPORTING by TYPE i DEFAULT 1.

    "! 함수형 메서드 — RETURNING 1개, 표현식 위치에서 호출 가능.
    METHODS value
      RETURNING VALUE(result) TYPE i.

    "! 함수형 메서드 — 입력 없이 현재 값의 2배를 돌려준다(체이닝 시연용).
    METHODS double
      RETURNING VALUE(result) TYPE i.

    "! 정적 유틸리티 메서드 — 인스턴스 상태와 무관, 클래스명=> 로 호출.
    CLASS-METHODS description
      RETURNING VALUE(result) TYPE string.

    "! 정적 생성(팩토리) 메서드 — Clean ABAP가 권하는 정적 메서드의 대표 용례.
    CLASS-METHODS of
      IMPORTING start         TYPE i
      RETURNING VALUE(result) TYPE REF TO lcl_counter.
  PRIVATE SECTION.
    DATA count TYPE i.
ENDCLASS.


CLASS lcl_counter IMPLEMENTATION.
  METHOD constructor.
    count = start.
  ENDMETHOD.

  METHOD increment.
    count = count + by.
  ENDMETHOD.

  METHOD value.
    result = count.
  ENDMETHOD.

  METHOD double.
    result = count * 2.
  ENDMETHOD.

  METHOD description.
    result = `정적 메서드는 클래스명=> , 인스턴스 메서드는 객체-> 로 호출한다`.
  ENDMETHOD.

  METHOD of.
    result = NEW lcl_counter( start ).
  ENDMETHOD.
ENDCLASS.
