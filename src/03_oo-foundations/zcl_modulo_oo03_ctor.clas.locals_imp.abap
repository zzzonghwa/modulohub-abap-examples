"! 일련번호 발급기 — 정적 생성자·인스턴스 생성자·공유 CLASS-DATA를 보인다.
CLASS lcl_sequence DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    "! 정적 생성자 — 파라미터 없음, 내부 세션에서 클래스 최초 사용 전 1회 자동 호출.
    CLASS-METHODS class_constructor.

    "! 모든 인스턴스가 공유하는 클래스 속성(공개 READ-ONLY).
    CLASS-DATA created_count TYPE i READ-ONLY.

    "! 인스턴스 속성 — 객체마다 고유.
    DATA id    TYPE i      READ-ONLY.
    DATA label TYPE string READ-ONLY.

    "! 인스턴스 생성자 — NEW마다 1회 자동 호출. IMPORTING만 허용.
    METHODS constructor
      IMPORTING label TYPE string.
  PRIVATE SECTION.
    "! 다음 발급 번호(공유 상태). 정적 생성자에서 초기화한다.
    CLASS-DATA next_id TYPE i.
ENDCLASS.


CLASS lcl_sequence IMPLEMENTATION.
  METHOD class_constructor.
    " 클래스 최초 사용 전 1회 — 공유 상태 초기화에 적합(SAP 표준의 캐시 초기화 패턴).
    next_id       = 0.
    created_count = 0.
  ENDMETHOD.

  METHOD constructor.
    next_id       = next_id + 1.
    created_count = created_count + 1.
    me->id        = next_id.
    me->label     = label.
  ENDMETHOD.
ENDCLASS.


"! 설정 캐시 — CREATE PRIVATE + 정적 factory 로 싱글톤을 강제한다.
CLASS lcl_config DEFINITION CREATE PRIVATE.
  PUBLIC SECTION.
    "! 정적 factory — 인스턴스가 없으면 만들고, 항상 같은 객체를 돌려준다.
    CLASS-METHODS get_instance
      RETURNING VALUE(result) TYPE REF TO lcl_config.

    METHODS get_value
      RETURNING VALUE(result) TYPE string.

    METHODS set_value
      IMPORTING value TYPE string.
  PRIVATE SECTION.
    "! 유일 인스턴스를 담는 공유 참조.
    CLASS-DATA singleton TYPE REF TO lcl_config.
    DATA value TYPE string.
ENDCLASS.


CLASS lcl_config IMPLEMENTATION.
  METHOD get_instance.
    IF singleton IS NOT BOUND.
      " NEW 는 CREATE PRIVATE 클래스 내부에서만 호출 가능하다.
      singleton = NEW lcl_config( ).
    ENDIF.
    result = singleton.
  ENDMETHOD.

  METHOD get_value.
    result = value.
  ENDMETHOD.

  METHOD set_value.
    me->value = value.
  ENDMETHOD.
ENDCLASS.
