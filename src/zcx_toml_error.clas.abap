CLASS zcx_toml_error DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING iv_text TYPE string
                iv_line TYPE i OPTIONAL.

    METHODS get_message
      RETURNING VALUE(rv_text) TYPE string.

    METHODS get_line
      RETURNING VALUE(rv_line) TYPE i.

  PROTECTED SECTION.

  PRIVATE SECTION.
    DATA mv_message TYPE string.
    DATA mv_line    TYPE i.
ENDCLASS.


CLASS zcx_toml_error IMPLEMENTATION.
  METHOD constructor.
    super->constructor( ).
    mv_message = iv_text.
    mv_line = iv_line.
  ENDMETHOD.

  METHOD get_message.
    rv_text = mv_message.
  ENDMETHOD.

  METHOD get_line.
    rv_line = mv_line.
  ENDMETHOD.
ENDCLASS.
