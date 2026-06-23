"! <p>ADT에서 F9(Run As -> ABAP Application)로 바로 실행해 데모 출력을 본다.</p>
CLASS zcl_modulo_df08_strings DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

    "! 문자열 템플릿(|...|, 7.40+)과 내장 함수 to_upper로 대문자 + 느낌표.
    METHODS shout
      IMPORTING text          TYPE string
      RETURNING VALUE(result) TYPE string.

    "! 소문자로(to_lower).
    METHODS whisper
      IMPORTING text          TYPE string
      RETURNING VALUE(result) TYPE string.

    "! 문자열 안의 숫자 개수. 내장 함수 count_any_of로 0-9 문자 수를 센다 —
    "! POSIX REGEX는 7.55+에서 deprecated, PCRE는 7.55+ 전용이라 7.54 호환·
    "! 무경고를 위해 정규식 없이 처리한다(정규식은 7.55+ FIND PCRE).
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
  METHOD if_oo_adt_classrun~main.
    out->write( `=== DF08 문자열 ===` ).
    out->write( |shout( abap )       = { shout( `abap` ) }| ).
    out->write( |whisper( ABAP )     = { whisper( `ABAP` ) }| ).
    out->write( |digit_count( a1b2c3 ) = { digit_count( `a1b2c3` ) }| ).
    out->write( |trim( '  a  b  ' )  = { trim( `  a  b  ` ) }| ).
    out->write( |replace_first(a-a-a)= { replace_first( text = `a-a-a` what = `-` with = `+` ) }| ).
    out->write( |is_palindrome(Level)= { is_palindrome( `Level` ) }| ).
    out->write( |mask_but_last4      = { mask_but_last4( `1234567890` ) }| ).
    TRY.
        out->write( |word_at( 2 )        = { word_at( text = `clean abap rocks` index = 2 ) }| ).
        word_at( text = `clean abap` index = 0 ).
      CATCH cx_parameter_invalid_range.
        out->write( `word_at( index 0 ) -> 가드 예외(정상)` ).
    ENDTRY.
  ENDMETHOD.

  METHOD shout.
    result = |{ to_upper( text ) }!|.
  ENDMETHOD.

  METHOD whisper.
    result = to_lower( text ).
  ENDMETHOD.

  METHOD digit_count.
    count = count_any_of( val = text sub = `0123456789` ).
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
