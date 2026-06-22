"! 기반 클래스 — CAST 데모용 작은 상속 계층.
CLASS lcl_animal DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS sound RETURNING VALUE(result) TYPE string.
ENDCLASS.

CLASS lcl_animal IMPLEMENTATION.
  METHOD sound.
    result = `...`.
  ENDMETHOD.
ENDCLASS.


"! 하위 클래스 — sound 재정의 + 고유 메서드 fetch. CAST로만 fetch에 접근한다.
CLASS lcl_dog DEFINITION INHERITING FROM lcl_animal CREATE PUBLIC.
  PUBLIC SECTION.
    METHODS sound REDEFINITION.
    METHODS fetch RETURNING VALUE(result) TYPE string.
ENDCLASS.

CLASS lcl_dog IMPLEMENTATION.
  METHOD sound.
    result = `Woof`.
  ENDMETHOD.

  METHOD fetch.
    result = `fetch!`.
  ENDMETHOD.
ENDCLASS.
