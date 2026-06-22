CLASS zcl_modulo_ext03_badi DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
    "!
    "! BAdI·Enhancement — released 확장점 소비(개념, 노트 10-03).
    "! 실 BAdI 정의·구현·활성화는 시스템 의존(SE18/SE19·Enhancement Spot, 10-4 안내)이라
    "! abapGit 예제로 만들 수 없다. 따라서 소비자 관점의 *런타임 시맨틱*만 인메모리
    "! BAdI 프레임워크(locals_imp)로 자체완결 시연한다 — GET BADI/CALL BADI 동작을 정확히 흉내.
    "!
    "! 시연 범위(노트 소절 대응):
    "! - §15 CALL BADI 멀티캐스트: multiple-use BAdI는 active 구현을 전부 실행.
    "! - §9  active/inactive override: inactive 구현은 실행에서 제외.
    "! - §11 §19 single-use 예외: 구현 0개 -> NOT_IMPLEMENTED, 복수 -> MULTIPLY.
    "! - §11 fallback class: single-use 구현 0개일 때 fallback으로 폴백해 예외 회피.
    "! - §10 인스턴스 모드: instance reuse면 동일 plug-in이 상태를 누적.
    "! - §16 backward compatibility: 미구현 메서드는 빈 구현으로 처리(no-op).
    "! - §20 §14 filter 라우팅: filter 값으로 구현 선택, filter name은 대문자 정규화.
    INTERFACES if_oo_adt_classrun.

    "! §15 CALL BADI 멀티캐스트 — multiple-use BAdI에 두 active 구현(음수금지·짝수만)을
    "! 등록하고 모두 실행해 위반 건수를 센다. EXPR05(단일 전략)와 달리 전부 호출된다.
    "! @parameter value  | 검사할 값
    "! @parameter result | 위반한 구현 수(0이면 전부 통과)
    METHODS validate
      IMPORTING value         TYPE i
      RETURNING VALUE(result) TYPE i.

    "! §9 active/inactive override — 짝수 구현을 inactive로 등록하면 Switch/filter와
    "! 무관하게 실행에서 빠진다. 음수 구현만 active이므로 음수일 때만 위반 1.
    "! @parameter value  | 검사할 값
    "! @parameter result | active 구현만 적용한 위반 수
    METHODS validate_with_inactive
      IMPORTING value         TYPE i
      RETURNING VALUE(result) TYPE i.

    "! §11 §19 multiple-use no-op — 구현 0개여도 예외 없이 위반 0(single-use와의 차이).
    "! @parameter value  | 검사할 값
    "! @parameter result | 항상 0(등록 구현 없음)
    METHODS validate_empty_multi
      IMPORTING value         TYPE i
      RETURNING VALUE(result) TYPE i.

    "! §11 §18 single-use 구현 0개 + fallback 없음 -> CX_BADI_NOT_IMPLEMENTED 비유.
    "! @parameter result | 예외가 발생하면 abap_true
    METHODS single_use_no_impl_raises
      RETURNING VALUE(result) TYPE abap_bool.

    "! §11 single-use 구현 0개 + fallback 있음 -> 폴백되어 예외 없음(노트 §11 fallback).
    "! fallback은 항상 통과시키므로 위반 0.
    "! @parameter value  | 검사할 값
    "! @parameter result | fallback 적용 위반 수(항상 0)
    METHODS single_use_fallback
      IMPORTING value         TYPE i
      RETURNING VALUE(result) TYPE i.

    "! §11 §18 single-use 구현 복수 -> CX_BADI_MULTIPLY_IMPLEMENTED 비유.
    "! @parameter result | 예외가 발생하면 abap_true
    METHODS single_use_multiply_raises
      RETURNING VALUE(result) TYPE abap_bool.

    "! §10 인스턴스 모드 — instance reuse면 동일 plug-in이 재사용돼 호출 횟수가 누적된다.
    "! 같은 BAdI object에서 2회 호출 후 plug-in의 누적 호출 수를 돌려준다.
    "! @parameter result | 동일 인스턴스의 누적 check 호출 수(=2)
    METHODS instance_reuse_calls
      RETURNING VALUE(result) TYPE i.

    "! §20 §14 filter 라우팅 — filter 값으로 구현을 선택한다. filter name 대조용으로
    "! 소문자 입력도 대문자로 정규화해 매칭된다(노트 §14 대문자 필수).
    "! @parameter filter | 라우팅 키(예: 'EVEN' 또는 소문자 'even')
    "! @parameter value  | 검사할 값
    "! @parameter result | 선택된 구현의 위반 수
    METHODS validate_by_filter
      IMPORTING filter        TYPE string
                value         TYPE i
      RETURNING VALUE(result) TYPE i.

    "! §20 filter 미매칭 -> 매칭 구현 없음(NOT_IMPLEMENTED 비유).
    "! @parameter result | 미매칭으로 예외가 발생하면 abap_true
    METHODS unknown_filter_raises
      RETURNING VALUE(result) TYPE abap_bool.

  PRIVATE SECTION.
    "! §15 두 검증 구현이 모두 active인 multiple-use BAdI를 구성한다(데모 공용).
    METHODS multi_use_both
      RETURNING VALUE(result) TYPE REF TO lcl_multi_use_badi.
ENDCLASS.


CLASS zcl_modulo_ext03_badi IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== EXT03 BAdI·Enhancement 소비 (개념) ===` ).
    out->write( `[§15 멀티캐스트] multiple-use BAdI는 active 구현을 모두 실행한다` ).
    out->write( |validate(4)               = { validate( 4 ) } (음수아님+짝수 -> 0)| ).
    out->write( |validate(3)               = { validate( 3 ) } (홀수만 위반 -> 1)| ).
    out->write( |validate(-4)              = { validate( -4 ) } (음수만 위반 -> 1)| ).
    out->write( |validate(-3)              = { validate( -3 ) } (음수+홀수 -> 2)| ).
    out->write( `[§9 active/inactive] inactive 구현은 Switch/filter 무관하게 제외된다` ).
    out->write( |validate_with_inactive(3) = { validate_with_inactive( 3 ) } (짝수구현 inactive -> 0)| ).
    out->write( |validate_with_inactive(-3)= { validate_with_inactive( -3 ) } (음수만 active -> 1)| ).
    out->write( `[§11 single vs multiple] 구현 0개의 차이` ).
    out->write( |validate_empty_multi(-3)  = { validate_empty_multi( -3 ) } (multiple-use no-op -> 0)| ).
    out->write( |single_use_no_impl_raises = { single_use_no_impl_raises( ) } (NOT_IMPLEMENTED)| ).
    out->write( |single_use_fallback(-3)   = { single_use_fallback( -3 ) } (fallback 폴백 -> 0)| ).
    out->write( |single_use_multiply_raises= { single_use_multiply_raises( ) } (MULTIPLY)| ).
    out->write( `[§10 인스턴스 모드] instance reuse면 동일 plug-in이 상태를 누적한다` ).
    out->write( |instance_reuse_calls      = { instance_reuse_calls( ) } (2회 재사용 호출)| ).
    out->write( `[§20 filter 라우팅] filter 값으로 구현 선택, filter name 대문자 정규화` ).
    out->write( |validate_by_filter('even',3)  = { validate_by_filter( filter = `even` value = 3 ) } (소문자도 매칭)| ).
    out->write( |validate_by_filter('NEG',-1) = { validate_by_filter( filter = `NEG` value = -1 ) } (음수 위반)| ).
    out->write( |unknown_filter_raises     = { unknown_filter_raises( ) } (미매칭)| ).
  ENDMETHOD.

  METHOD validate.
    " GET BADI 비유: active 구현을 BAdI object에 모은다 -> CALL BADI로 전부 실행.
    result = multi_use_both( )->call_badi( value ).
  ENDMETHOD.

  METHOD validate_with_inactive.
    " 짝수 구현은 inactive로 등록 -> 실행에서 제외(노트 §9 active/inactive override).
    DATA(badi) = NEW lcl_multi_use_badi( ).
    badi->add_implementation( NEW lcl_non_negative( ) ).
    badi->add_implementation( implementation = NEW lcl_even_only( )
                              is_active       = abap_false ).
    result = badi->call_badi( value ).
  ENDMETHOD.

  METHOD validate_empty_multi.
    " multiple-use BAdI에 구현 0개 -> 예외 없이 no-op(노트 §11·§19).
    result = NEW lcl_multi_use_badi( )->call_badi( value ).
  ENDMETHOD.

  METHOD single_use_no_impl_raises.
    " single-use BAdI, 구현 0개, fallback 없음 -> GET BADI에서 NOT_IMPLEMENTED.
    TRY.
        NEW lcl_single_use_badi( )->get_badi( ).
        result = abap_false.
      CATCH lcx_badi_not_implemented lcx_badi_multiply.
        result = abap_true.
    ENDTRY.
  ENDMETHOD.

  METHOD single_use_fallback.
    " single-use BAdI, 구현 0개지만 fallback 등록 -> 폴백되어 예외 없음(노트 §11).
    DATA(badi) = NEW lcl_single_use_badi( ).
    badi->set_fallback( NEW lcl_fallback( ) ).
    TRY.
        DATA(plugin) = badi->get_badi( ).
        result = COND #( WHEN plugin->check( value ) IS NOT INITIAL THEN 1 ELSE 0 ).
      CATCH lcx_badi_not_implemented lcx_badi_multiply.
        result = -1.
    ENDTRY.
  ENDMETHOD.

  METHOD single_use_multiply_raises.
    " single-use BAdI에 구현 2개 -> GET BADI에서 MULTIPLY_IMPLEMENTED.
    DATA(badi) = NEW lcl_single_use_badi( ).
    badi->add_implementation( NEW lcl_non_negative( ) ).
    badi->add_implementation( NEW lcl_even_only( ) ).
    TRY.
        badi->get_badi( ).
        result = abap_false.
      CATCH lcx_badi_multiply lcx_badi_not_implemented.
        result = abap_true.
    ENDTRY.
  ENDMETHOD.

  METHOD instance_reuse_calls.
    " instance reuse 모드 비유: 동일 plug-in을 재사용 -> check 호출이 누적된다.
    DATA(plugin) = NEW lcl_counting( ).
    DATA(badi) = NEW lcl_multi_use_badi( ).
    badi->add_implementation( plugin ).
    badi->call_badi( 1 ).
    badi->call_badi( 2 ).
    result = plugin->calls( ).
  ENDMETHOD.

  METHOD validate_by_filter.
    " GET BADI ... FILTERS 비유: filter 값으로 단일 구현 선택 후 CALL.
    DATA(badi) = NEW lcl_filter_badi( ).
    badi->register( filter_value   = `EVEN`
                    implementation = NEW lcl_even_only( ) ).
    badi->register( filter_value   = `NEG`
                    implementation = NEW lcl_non_negative( ) ).
    TRY.
        DATA(plugin) = badi->get_badi_filtered( filter ).
        result = COND #( WHEN plugin->check( value ) IS NOT INITIAL THEN 1 ELSE 0 ).
      CATCH lcx_badi_not_implemented.
        result = -1.
    ENDTRY.
  ENDMETHOD.

  METHOD unknown_filter_raises.
    " 등록되지 않은 filter 값 -> 매칭 구현 없음(노트 §20 Step4 폴백 실패).
    DATA(badi) = NEW lcl_filter_badi( ).
    badi->register( filter_value   = `EVEN`
                    implementation = NEW lcl_even_only( ) ).
    TRY.
        badi->get_badi_filtered( `UNKNOWN` ).
        result = abap_false.
      CATCH lcx_badi_not_implemented.
        result = abap_true.
    ENDTRY.
  ENDMETHOD.

  METHOD multi_use_both.
    result = NEW lcl_multi_use_badi( ).
    result->add_implementation( NEW lcl_non_negative( ) ).
    result->add_implementation( NEW lcl_even_only( ) ).
  ENDMETHOD.
ENDCLASS.
