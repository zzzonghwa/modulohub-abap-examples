CLASS ltcl_strings DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA cut TYPE REF TO zcl_modulo_df08_strings.
    METHODS setup.
    METHODS shouts_in_uppercase  FOR TESTING.
    METHODS whispers_lowercase   FOR TESTING.
    METHODS counts_digits        FOR TESTING.
    METHODS no_digits_is_zero    FOR TESTING.
    METHODS trims_whitespace     FOR TESTING.
    METHODS replaces_first_only  FOR TESTING.
    METHODS detects_palindrome   FOR TESTING.
    METHODS rejects_non_palindrome FOR TESTING.
    METHODS masks_all_but_last4  FOR TESTING.
    METHODS short_text_unmasked  FOR TESTING.
    METHODS picks_nth_word       FOR TESTING.
    METHODS word_zero_raises     FOR TESTING.
ENDCLASS.


CLASS ltcl_strings IMPLEMENTATION.
  METHOD setup.
    cut = NEW #( ).
  ENDMETHOD.

  METHOD shouts_in_uppercase.
    cl_abap_unit_assert=>assert_equals( act = cut->shout( `abap` ) exp = `ABAP!` ).
  ENDMETHOD.

  METHOD whispers_lowercase.
    cl_abap_unit_assert=>assert_equals( act = cut->whisper( `ABAP` ) exp = `abap` ).
  ENDMETHOD.

  METHOD counts_digits.
    cl_abap_unit_assert=>assert_equals( act = cut->digit_count( `a1b2c3` ) exp = 3 ).
  ENDMETHOD.

  METHOD no_digits_is_zero.
    cl_abap_unit_assert=>assert_equals( act = cut->digit_count( `abap` ) exp = 0 ).
  ENDMETHOD.

  METHOD trims_whitespace.
    cl_abap_unit_assert=>assert_equals(
      act = cut->trim( `  clean   abap  ` ) exp = `clean abap` ).
  ENDMETHOD.

  METHOD replaces_first_only.
    " GIVEN "a-a-a" / WHEN 첫 '-'만 '+'로 / THEN "a+a-a"
    cl_abap_unit_assert=>assert_equals(
      act = cut->replace_first( text = `a-a-a` what = `-` with = `+` )
      exp = `a+a-a` ).
  ENDMETHOD.

  METHOD detects_palindrome.
    cl_abap_unit_assert=>assert_true( cut->is_palindrome( `Level` ) ).
  ENDMETHOD.

  METHOD rejects_non_palindrome.
    cl_abap_unit_assert=>assert_false( cut->is_palindrome( `abap` ) ).
  ENDMETHOD.

  METHOD masks_all_but_last4.
    cl_abap_unit_assert=>assert_equals(
      act = cut->mask_but_last4( `1234567890` ) exp = `******7890` ).
  ENDMETHOD.

  METHOD short_text_unmasked.
    cl_abap_unit_assert=>assert_equals(
      act = cut->mask_but_last4( `12` ) exp = `12` ).
  ENDMETHOD.

  METHOD picks_nth_word.
    cl_abap_unit_assert=>assert_equals(
      act = cut->word_at( text = `clean abap rocks` index = 2 ) exp = `abap` ).
  ENDMETHOD.

  METHOD word_zero_raises.
    TRY.
        cut->word_at( text = `clean abap` index = 0 ).
        cl_abap_unit_assert=>fail( msg = 'index 0은 예외여야 한다' ).
      CATCH cx_parameter_invalid_range.
    ENDTRY.
  ENDMETHOD.
ENDCLASS.
