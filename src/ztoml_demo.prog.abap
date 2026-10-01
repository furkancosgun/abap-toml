REPORT ztoml_demo.

START-OF-SELECTION.
  DATA lo_toml TYPE REF TO zcl_toml.
  DATA lv_nl   TYPE string.
  DATA lv_doc  TYPE string.
  DATA lv_out  TYPE string.
  DATA lx_err  TYPE REF TO zcx_toml_error.

  lv_nl = cl_abap_char_utilities=>newline.
  lv_doc = |[server]{ lv_nl }|
    && |host = 'localhost'{ lv_nl }|
    && |port = 8080{ lv_nl }|
    && |[server.tls]{ lv_nl }|
    && |enabled = false{ lv_nl }|.
  TRY.
      lo_toml = zcl_toml=>parse( lv_doc ).
      WRITE / lo_toml->get_string( '/server/host' ).
      WRITE / lo_toml->get_integer( '/server/port' ).
      lo_toml->set_string( iv_path  = '/server/host'
                           iv_value = 'example.com' ).
      lv_out = lo_toml->stringify( ).
      WRITE / lv_out.
    CATCH zcx_toml_error INTO lx_err.
      WRITE / lx_err->get_message( ).
  ENDTRY.
