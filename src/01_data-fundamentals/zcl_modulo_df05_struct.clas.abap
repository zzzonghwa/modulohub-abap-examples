"! <p>ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.</p>
CLASS zcl_modulo_df05_struct DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    "! 구조 타입(structured type). 연관된 필드를 한 단위로 묶는 값 객체.
    TYPES:
      BEGIN OF address,
        person_name TYPE string,
        city        TYPE string,
      END OF address.

    "! 다른 구조. address와 person_name 컴포넌트를 공유한다(CORRESPONDING 대상).
    TYPES:
      BEGIN OF contact,
        person_name TYPE string,
        phone       TYPE string,
      END OF contact.

    "! 구조를 한 줄로 포맷한다. 컴포넌트 선택자 `-`로 접근.
    "! @parameter addr  | 주소 구조
    "! @parameter label | "이름, 도시"
    METHODS format_label
      IMPORTING addr         TYPE address
      RETURNING VALUE(label) TYPE string.

    "! 두 컴포넌트가 모두 채워졌는지 판정한다(IS NOT INITIAL).
    "! @parameter addr   | 주소 구조
    "! @parameter result | 둘 다 채워졌으면 abap_true
    METHODS is_complete
      IMPORTING addr          TYPE address
      RETURNING VALUE(result) TYPE abap_bool.

    "! 도시만 교체한 새 구조. VALUE의 BASE로 나머지 컴포넌트는 유지한다.
    "! @parameter addr   | 원본
    "! @parameter city   | 새 도시
    "! @parameter result | city만 바뀐 구조
    METHODS with_city
      IMPORTING addr          TYPE address
                city          TYPE string
      RETURNING VALUE(result) TYPE address.

    "! 도시만 초기화한 구조. BASE 없이 VALUE를 쓰면 지정하지 않은 컴포넌트가
    "! 초기화된다 — 여기서는 BASE로 이름만 남기고 city를 비운다.
    "! @parameter addr   | 원본
    "! @parameter result | city가 빈 구조
    METHODS clear_city
      IMPORTING addr          TYPE address
      RETURNING VALUE(result) TYPE address.

    "! 주소에서 연락처로 이름을 옮긴다. CORRESPONDING은 동명 컴포넌트
    "! (person_name)만 이동하고 나머지(phone)는 건드리지 않는다.
    "! @parameter addr   | 주소
    "! @parameter result | person_name만 채워진 연락처
    METHODS to_contact
      IMPORTING addr          TYPE address
      RETURNING VALUE(result) TYPE contact.
ENDCLASS.


CLASS zcl_modulo_df05_struct IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== DF05 구조 ===` ).
    DATA(addr) = VALUE address( person_name = `Kim` city = `Seoul` ).
    out->write( |format_label   = { format_label( addr ) }| ).
    out->write( |is_complete    = { is_complete( addr ) }| ).
    out->write( |with_city(Busan)| ).
    out->write( with_city( addr = addr city = `Busan` ) ).
    out->write( |to_contact (CORRESPONDING, phone 미이동)| ).
    out->write( to_contact( addr ) ).
  ENDMETHOD.

  METHOD format_label.
    label = |{ addr-person_name }, { addr-city }|.
  ENDMETHOD.

  METHOD is_complete.
    result = xsdbool( addr-person_name IS NOT INITIAL AND addr-city IS NOT INITIAL ).
  ENDMETHOD.

  METHOD with_city.
    result = VALUE #( BASE addr city = city ).
  ENDMETHOD.

  METHOD clear_city.
    result = VALUE #( BASE addr city = `` ).
  ENDMETHOD.

  METHOD to_contact.
    result = CORRESPONDING #( addr ).
  ENDMETHOD.
ENDCLASS.
