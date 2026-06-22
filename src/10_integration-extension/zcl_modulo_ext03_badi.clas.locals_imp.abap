"! 확장점 계약 — 검증 BAdI의 모든 구현이 공유하는 인터페이스.
INTERFACE lif_validation.
  "! @parameter value | 검사할 값
  "! @parameter error | 위반 메시지(통과면 공백)
  METHODS check
    IMPORTING value        TYPE i
    RETURNING VALUE(error) TYPE string.
ENDINTERFACE.


"! 구현 1 — 음수 금지.
CLASS lcl_non_negative DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES lif_validation.
ENDCLASS.

CLASS lcl_non_negative IMPLEMENTATION.
  METHOD lif_validation~check.
    error = COND #( WHEN value < 0 THEN `negative not allowed` ).
  ENDMETHOD.
ENDCLASS.


"! 구현 2 — 짝수만 허용.
CLASS lcl_even_only DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES lif_validation.
ENDCLASS.

CLASS lcl_even_only IMPLEMENTATION.
  METHOD lif_validation~check.
    error = COND #( WHEN value MOD 2 <> 0 THEN `must be even` ).
  ENDMETHOD.
ENDCLASS.


"! BAdI 레지스트리 — 활성 구현을 모두 보유하고, 호출 시 전부 실행한다(멀티캐스트).
"! 실 BAdI의 "여러 활성 구현이 모두 호출됨"을 인메모리로 비유한다.
CLASS lcl_badi_registry DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    "! 활성 구현을 등록한다(SE19 구현 활성화 비유).
    METHODS add IMPORTING implementation TYPE REF TO lif_validation.
    "! 모든 활성 구현을 호출해 위반 건수를 센다(CALL BADI 멀티캐스트 비유).
    METHODS run_all
      IMPORTING value         TYPE i
      RETURNING VALUE(errors) TYPE i.
  PRIVATE SECTION.
    DATA implementations TYPE STANDARD TABLE OF REF TO lif_validation WITH EMPTY KEY.
ENDCLASS.

CLASS lcl_badi_registry IMPLEMENTATION.
  METHOD add.
    APPEND implementation TO implementations.
  ENDMETHOD.

  METHOD run_all.
    LOOP AT implementations INTO DATA(implementation).
      IF implementation->check( value ) IS NOT INITIAL.
        errors = errors + 1.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
