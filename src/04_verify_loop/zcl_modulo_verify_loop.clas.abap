CLASS zcl_modulo_verify_loop DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    TYPES amount_value TYPE p LENGTH 13 DECIMALS 2.
    TYPES amount_list  TYPE STANDARD TABLE OF amount_value WITH EMPTY KEY.

    "! Sums a list of amounts. The unit on which the verification loop
    "! (write -> activate -> ABAP Unit -> ATC) is first demonstrated.
    "! @parameter amounts | the amounts to add up
    "! @parameter total   | the sum of all amounts (0 for an empty list)
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
