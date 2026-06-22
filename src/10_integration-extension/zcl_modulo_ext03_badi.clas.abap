CLASS zcl_modulo_ext03_badi DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
    "!
    "! BAdI·Enhancement — released 확장점 소비(개념).
    "! - BAdI는 SAP 표준을 수정하지 않고 확장하는 공식 메커니즘(플러그인). 한 BAdI에
    "!   여러 활성 구현을 둘 수 있고 CALL BADI가 그 구현을 전부 호출한다(멀티캐스트).
    "! - 소비: GET BADI handle( ) -> CALL BADI handle->method( ). filter BAdI는 필터로 선택,
    "!   fallback은 구현 부재 시 기본 동작을 준다.
    "! 이 예제는 그 멀티캐스트 패턴을 로컬 레지스트리(locals_imp)로 시연한다 —
    "!   실 BAdI 정의·구현·활성화는 SE18/SE19·Enhancement Spot(시스템 의존, 10.4 안내).
    "! EXPR05(단일 전략 주입)와 달리, 여기선 여러 구현이 모두 실행된다.
    INTERFACES if_oo_adt_classrun.

    "! 등록된 모든 검증 구현을 값에 적용해 위반 건수를 돌려준다.
    "! @parameter value  | 검사할 값
    "! @parameter result | 위반한 검증 구현 수(0이면 모두 통과)
    METHODS validate
      IMPORTING value         TYPE i
      RETURNING VALUE(result) TYPE i.
ENDCLASS.


CLASS zcl_modulo_ext03_badi IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== EXT03 BAdI·Enhancement 소비 (개념) ===` ).
    out->write( |validate(4)  = { validate( 4 ) }| ).
    out->write( |validate(3)  = { validate( 3 ) }| ).
    out->write( |validate(-4) = { validate( -4 ) }| ).
    out->write( |validate(-3) = { validate( -3 ) }| ).
    out->write( `여러 활성 구현이 모두 호출된다(멀티캐스트) — 위반한 구현 수를 센다.` ).
  ENDMETHOD.

  METHOD validate.
    " GET BADI 비유: 활성 구현을 레지스트리에 모은다.
    DATA(registry) = NEW lcl_badi_registry( ).
    registry->add( NEW lcl_non_negative( ) ).
    registry->add( NEW lcl_even_only( ) ).
    " CALL BADI 비유: 모든 구현 실행.
    result = registry->run_all( value ).
  ENDMETHOD.
ENDCLASS.
