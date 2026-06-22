CLASS zcl_modulo_tst03_atc DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.
    "!
    "! ATC(ABAP Test Cockpit)·정적 품질. ATC는 활성화 코드를 룰 변형(variant)으로 정적 검사한다.
    "! - 우선순위: Priority 1(에러, 운반 차단) / 2(경고) / 3(정보). 1·2는 활성화·운반 게이트.
    "! - 정당한 발견은 억제한다: 프라그마(##NEEDED·##NO_HANDLER·##NO_TEXT)는 컴파일러가,
    "!   의사주석("#EC ...)은 ATC가 인식한다. 무분별 억제 금지 — 근거가 있을 때만.
    "! 이 클래스는 실제 프라그마 사용 + ATC 친화적 디스패치(SWITCH)를 보인다.
    INTERFACES if_oo_adt_classrun.

    "! 기술 라벨(번역 대상 아님) — ##NO_TEXT로 "텍스트 기호로 빼지 않음"을 명시한다.
    CONSTANTS c_unknown TYPE string VALUE 'UNKNOWN' ##NO_TEXT.

    "! 심각도 코드 -> 라벨. 중첩 IF 대신 SWITCH로 분기(ATC "복잡도" 발견 회피).
    "! @parameter code   | 1=error, 2=warning, 3=info
    "! @parameter result | 라벨, 미정의면 c_unknown
    METHODS severity_label
      IMPORTING code          TYPE i
      RETURNING VALUE(result) TYPE string.

    "! 문자열이 정수로 변환 가능한지. 변환 실패는 "숫자 아님"이라 빈 핸들러가 정당하다.
    "! ##NEEDED(변환 결과는 안 쓰고 성공 여부만), ##NO_HANDLER(의도된 빈 CATCH) 시연.
    "! @parameter text   | 검사할 문자열
    "! @parameter result | 숫자면 abap_true
    METHODS is_numeric
      IMPORTING text          TYPE string
      RETURNING VALUE(result) TYPE abap_bool.
ENDCLASS.


CLASS zcl_modulo_tst03_atc IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    out->write( `=== TST03 ATC·정적 품질 ===` ).
    out->write( |severity_label(1)  = { severity_label( 1 ) }| ).
    out->write( |severity_label(9)  = { severity_label( 9 ) }| ).
    out->write( |is_numeric('42')   = { is_numeric( `42` ) }| ).
    out->write( |is_numeric('abc')  = { is_numeric( `abc` ) }| ).
  ENDMETHOD.

  METHOD severity_label.
    result = SWITCH string( code
                            WHEN 1 THEN `ERROR`
                            WHEN 2 THEN `WARNING`
                            WHEN 3 THEN `INFO`
                            ELSE c_unknown ).
  ENDMETHOD.

  METHOD is_numeric.
    TRY.
        DATA(parsed) = CONV i( text ) ##NEEDED.
        result = abap_true.
      CATCH cx_sy_conversion_error ##NO_HANDLER.
        " 변환 실패 = 숫자 아님. result는 초기값(abap_false) 유지 — 빈 핸들러가 정당하다.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
