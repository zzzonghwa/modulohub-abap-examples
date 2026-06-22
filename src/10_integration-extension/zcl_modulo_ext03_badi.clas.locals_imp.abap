"! 확장점 계약 — 검증 BAdI의 모든 구현이 공유하는 인터페이스(노트 §7 BAdI interface 비유).
"! 실 BAdI에서는 ZIF_* 가 INTERFACES IF_BADI_INTERFACE 태그를 품고, 구현 클래스가 양쪽을
"! 직접 선언한다. 여기서는 태그 없는 LIF_ 로 단순화해 소비 시맨틱만 시연한다.
INTERFACE lif_validation.
  "! @parameter value | 검사할 값
  "! @parameter error | 위반 메시지(통과면 공백)
  METHODS check
    IMPORTING value        TYPE i
    RETURNING VALUE(error) TYPE string.
ENDINTERFACE.


"! single-use BAdI 구현이 0개일 때(노트 §11·§18 CX_BADI_NOT_IMPLEMENTED 비유).
CLASS lcx_badi_not_implemented DEFINITION INHERITING FROM cx_static_check.
ENDCLASS.

CLASS lcx_badi_not_implemented IMPLEMENTATION.
ENDCLASS.


"! single-use BAdI에 구현이 복수일 때(노트 §11·§18 CX_BADI_MULTIPLY_IMPLEMENTED 비유).
CLASS lcx_badi_multiply DEFINITION INHERITING FROM cx_static_check.
ENDCLASS.

CLASS lcx_badi_multiply IMPLEMENTATION.
ENDCLASS.


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


"! fallback 구현(노트 §10·§11) — 구현이 0개일 때 표준 동작을 제공한다.
"! 이 fallback은 항상 통과시킨다(no-op 검증).
CLASS lcl_fallback DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES lif_validation.
ENDCLASS.

CLASS lcl_fallback IMPLEMENTATION.
  METHOD lif_validation~check.
    " fallback: 위반 없음(표준 동작).
    error = ``.
  ENDMETHOD.
ENDCLASS.


"! 인스턴스 모드(노트 §10) — 세션 내 재사용 호출을 카운트해 보여주는 stateful 구현.
"! instance reuse 모드면 동일 인스턴스가 반환돼 호출 횟수가 누적된다.
CLASS lcl_counting DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES lif_validation.
    "! 이 인스턴스가 check를 실행한 누적 횟수.
    METHODS calls RETURNING VALUE(result) TYPE i.
  PRIVATE SECTION.
    DATA call_count TYPE i.
ENDCLASS.

CLASS lcl_counting IMPLEMENTATION.
  METHOD lif_validation~check.
    call_count = call_count + 1.
    error = ``.
  ENDMETHOD.

  METHOD calls.
    result = call_count.
  ENDMETHOD.
ENDCLASS.


"! single-use BAdI 비유(노트 §11·§19) — 정확히 1개 구현만 유효한 BAdI object.
"! GET BADI 시점에 hit list가 0개면 NOT_IMPLEMENTED, 복수면 MULTIPLY를 던진다.
"! fallback class가 등록돼 있으면 0개 구현일 때 fallback으로 폴백한다.
CLASS lcl_single_use_badi DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    "! active 구현을 등록한다(SE19 구현 활성화 비유).
    METHODS add_implementation
      IMPORTING implementation TYPE REF TO lif_validation.
    "! fallback 구현을 등록한다(노트 §11 — 구현 0개 시 대체).
    METHODS set_fallback
      IMPORTING fallback TYPE REF TO lif_validation.
    "! GET BADI 비유 — hit list를 점검하고 실행할 단일 plug-in을 결정한다.
    "! @raising lcx_badi_not_implemented | 구현 0개 + fallback 없음
    "! @raising lcx_badi_multiply        | 구현 복수(single-use 위반)
    METHODS get_badi
      RETURNING VALUE(plugin) TYPE REF TO lif_validation
      RAISING   lcx_badi_not_implemented
                lcx_badi_multiply.
  PRIVATE SECTION.
    DATA implementations TYPE STANDARD TABLE OF REF TO lif_validation WITH EMPTY KEY.
    DATA fallback TYPE REF TO lif_validation.
ENDCLASS.

CLASS lcl_single_use_badi IMPLEMENTATION.
  METHOD add_implementation.
    APPEND implementation TO implementations.
  ENDMETHOD.

  METHOD set_fallback.
    me->fallback = fallback.
  ENDMETHOD.

  METHOD get_badi.
    " 탐색 순서(노트 §10 규칙4): ① active 구현 → ② fallback.
    DATA(hits) = lines( implementations ).
    IF hits > 1.
      RAISE EXCEPTION NEW lcx_badi_multiply( ).
    ENDIF.
    IF hits = 1.
      plugin = implementations[ 1 ].
      RETURN.
    ENDIF.
    " 구현 0개: fallback이 있으면 폴백, 없으면 예외(노트 §11).
    IF fallback IS BOUND.
      plugin = fallback.
      RETURN.
    ENDIF.
    RAISE EXCEPTION NEW lcx_badi_not_implemented( ).
  ENDMETHOD.
ENDCLASS.


"! multiple-use BAdI 비유(노트 §15·§19) — 0~N개 구현을 모두 실행하는 BAdI object.
"! 각 구현은 active/inactive 상태를 가진다(노트 §9 — inactive면 실행 제외).
"! 구현 0개여도 예외 없이 no-op(노트 §11·§19 single/multiple 차이).
CLASS lcl_multi_use_badi DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    "! active 구현을 등록한다.
    METHODS add_implementation
      IMPORTING implementation TYPE REF TO lif_validation
                is_active      TYPE abap_bool DEFAULT abap_true.
    "! CALL BADI 멀티캐스트 비유 — active 구현을 모두 호출해 위반 건수를 센다.
    "! inactive 구현은 Switch/filter 무관하게 건너뛴다(노트 §9 active/inactive override).
    METHODS call_badi
      IMPORTING value         TYPE i
      RETURNING VALUE(errors) TYPE i.
  PRIVATE SECTION.
    TYPES:
      BEGIN OF plug_in,
        instance TYPE REF TO lif_validation,
        active   TYPE abap_bool,
      END OF plug_in.
    DATA plug_ins TYPE STANDARD TABLE OF plug_in WITH EMPTY KEY.
ENDCLASS.

CLASS lcl_multi_use_badi IMPLEMENTATION.
  METHOD add_implementation.
    APPEND VALUE #( instance = implementation active = is_active ) TO plug_ins.
  ENDMETHOD.

  METHOD call_badi.
    errors = REDUCE i(
      INIT count = 0
      FOR plug_in IN plug_ins
      WHERE ( active = abap_true )
      NEXT count = count
        + COND i( WHEN plug_in-instance->check( value ) <> `` THEN 1 ELSE 0 ) ).
  ENDMETHOD.
ENDCLASS.


"! filter BAdI 라우팅 비유(노트 §13·§14·§20) — filter 값으로 단일 구현을 선택한다.
"! filter name은 대문자로 정규화(노트 §13 규칙2·§14 — 대문자 필수)해 매칭한다.
CLASS lcl_filter_badi DEFINITION CREATE PUBLIC.
  PUBLIC SECTION.
    "! filter 값 → 구현 매핑을 등록한다(BAdI implementation의 filter combination 비유).
    METHODS register
      IMPORTING filter_value   TYPE string
                implementation TYPE REF TO lif_validation.
    "! GET BADI ... FILTERS 비유 — filter 값에 매칭되는 구현을 반환한다(노트 §20 Step3).
    "! @raising lcx_badi_not_implemented | 매칭 구현 없음
    METHODS get_badi_filtered
      IMPORTING filter_value  TYPE string
      RETURNING VALUE(plugin) TYPE REF TO lif_validation
      RAISING   lcx_badi_not_implemented.
  PRIVATE SECTION.
    TYPES:
      BEGIN OF routing,
        filter   TYPE string,
        instance TYPE REF TO lif_validation,
      END OF routing.
    DATA routings TYPE SORTED TABLE OF routing WITH UNIQUE KEY filter.
ENDCLASS.

CLASS lcl_filter_badi IMPLEMENTATION.
  METHOD register.
    INSERT VALUE #( filter = to_upper( filter_value ) instance = implementation ) INTO TABLE routings.
  ENDMETHOD.

  METHOD get_badi_filtered.
    " filter name 대문자 정규화 후 매칭(노트 §14 대문자 필수).
    DATA(key) = to_upper( filter_value ).
    READ TABLE routings INTO DATA(hit) WITH KEY filter = key.
    IF sy-subrc <> 0.
      RAISE EXCEPTION NEW lcx_badi_not_implemented( ).
    ENDIF.
    plugin = hit-instance.
  ENDMETHOD.
ENDCLASS.
