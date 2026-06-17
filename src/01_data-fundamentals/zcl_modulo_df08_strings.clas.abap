CLASS zcl_modulo_df08_strings DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! 문자열 템플릿(|...|, 7.40+)과 내장 함수 to_upper로 대문자 + 느낌표.
    METHODS shout
      IMPORTING text          TYPE string
      RETURNING VALUE(result) TYPE string.

    "! 소문자로(to_lower).
    METHODS whisper
      IMPORTING text          TYPE string
      RETURNING VALUE(result) TYPE string.

    "! 문자열 안의 숫자 개수. FIND ... REGEX(7.54 호환)로 \d의 전체 매치 수.
    "! 7.55+에서는 REGEX 대신 PCRE 추가어가 표준이다.
    METHODS digit_count
      IMPORTING text         TYPE string
      RETURNING VALUE(count) TYPE i.

    "! 앞뒤·중복 공백을 정리한다(condense).
    METHODS trim
      IMPORTING text          TYPE string
      RETURNING VALUE(result) TYPE string.

    "! 첫 매치를 치환한다(replace ... occurrence 1).
    METHODS replace_first
      IMPORTING text          TYPE string
                what          TYPE string
                with          TYPE string
      RETURNING VALUE(result) TYPE string.

    "! 회문 여부(대소문자 무시). reverse 내장 함수.
    METHODS is_palindrome
      IMPORTING text          TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

    "! 마지막 4자만 남기고 마스킹한다(substring + repeat). 4자 이하는 그대로.
    METHODS mask_but_last4
      IMPORTING text          TYPE string
      RETURNING VALUE(result) TYPE string.

    "! 공백 구분 n번째 단어(segment). 1부터 시작하며 0 이하는 가드 예외.
    "! @parameter text  | 문장
    "! @parameter index | 1-based 단어 위치
    "! @parameter word  | n번째 단어
    "! @raising cx_parameter_invalid_range | index < 1일 때
    METHODS word_at
      IMPORTING text         TYPE string
                index        TYPE i
      RETURNING VALUE(word)  TYPE string
      RAISING   cx_parameter_invalid_range.
ENDCLASS.


CLASS zcl_modulo_df08_strings IMPLEMENTATION.
  METHOD shout.
    result = |{ to_upper( text ) }!|.
  ENDMETHOD.

  METHOD whisper.
    result = to_lower( text ).
  ENDMETHOD.

  METHOD digit_count.
    FIND ALL OCCURRENCES OF REGEX `\d` IN text MATCH COUNT count.
  ENDMETHOD.

  METHOD trim.
    result = condense( text ).
  ENDMETHOD.

  METHOD replace_first.
    result = replace( val = text sub = what with = with occ = 1 ).
  ENDMETHOD.

  METHOD is_palindrome.
    DATA(normalized) = to_lower( text ).
    result = xsdbool( normalized = reverse( normalized ) ).
  ENDMETHOD.

  METHOD mask_but_last4.
    DATA(length) = strlen( text ).
    IF length <= 4.
      result = text.
      RETURN.
    ENDIF.
    DATA(masked) = repeat( val = `*` occ = length - 4 ).
    result = |{ masked }{ substring( val = text off = length - 4 ) }|.
  ENDMETHOD.

  METHOD word_at.
    IF index < 1.
      RAISE EXCEPTION TYPE cx_parameter_invalid_range.
    ENDIF.
    word = segment( val = text index = index sep = ` ` ).
  ENDMETHOD.
ENDCLASS.
