CLASS zcl_modulo_verify_loop DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES amount_value TYPE p LENGTH 13 DECIMALS 2.
    TYPES amount_list  TYPE STANDARD TABLE OF amount_value WITH EMPTY KEY.

    "! 금액 리스트를 합산한다. 검증 루프(작성 -> 활성화 -> ABAP Unit -> ATC)를
    "! 처음 시연하는 단위다.
    "! @parameter amounts | 합산할 금액들
    "! @parameter total   | 모든 금액의 합(빈 리스트는 0)
    METHODS sum_amounts
      IMPORTING amounts      TYPE amount_list
      RETURNING VALUE(total) TYPE amount_value.
ENDCLASS.


CLASS zcl_modulo_verify_loop IMPLEMENTATION.
  METHOD sum_amounts.
    total = REDUCE amount_value( INIT sum TYPE amount_value
                                 FOR amount IN amounts
                                 NEXT sum = sum + amount ).
  ENDMETHOD.
ENDCLASS.
