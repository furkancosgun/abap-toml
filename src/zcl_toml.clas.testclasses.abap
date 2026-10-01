CLASS ltcl_toml_test DEFINITION
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    METHODS test_scalars      FOR TESTING RAISING zcx_toml_error.
    METHODS test_table        FOR TESTING RAISING zcx_toml_error.
    METHODS test_dotted_keys  FOR TESTING RAISING zcx_toml_error.
    METHODS test_array        FOR TESTING RAISING zcx_toml_error.
    METHODS test_inline_table FOR TESTING RAISING zcx_toml_error.
    METHODS test_array_table  FOR TESTING RAISING zcx_toml_error.
    METHODS test_strings      FOR TESTING RAISING zcx_toml_error.
    METHODS test_numbers      FOR TESTING RAISING zcx_toml_error.
    METHODS test_datetime     FOR TESTING RAISING zcx_toml_error.
    METHODS test_write_api    FOR TESTING RAISING zcx_toml_error.
    METHODS test_roundtrip    FOR TESTING RAISING zcx_toml_error.
    METHODS test_errors       FOR TESTING.
ENDCLASS.


CLASS ltcl_toml_test IMPLEMENTATION.
  METHOD test_scalars.
    DATA lo_toml TYPE REF TO zcl_toml.
    DATA lv_nl   TYPE string.
    DATA lv_doc  TYPE string.

    lv_nl = cl_abap_char_utilities=>newline.
    lv_doc = |title = 'TOML Example'{ lv_nl }|
      && |count = 42{ lv_nl }|
      && |ratio = 3.5{ lv_nl }|
      && |active = true{ lv_nl }|.
    lo_toml = zcl_toml=>parse( lv_doc ).
    cl_abap_unit_assert=>assert_equals( exp = 'TOML Example'
                                        act = lo_toml->get_string( '/title' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 42
                                        act = lo_toml->get_integer( '/count' ) ).
    cl_abap_unit_assert=>assert_true( lo_toml->get_boolean( '/active' ) ).
  ENDMETHOD.

  METHOD test_table.
    DATA lo_toml TYPE REF TO zcl_toml.
    DATA lv_nl   TYPE string.
    DATA lv_doc  TYPE string.

    lv_nl = cl_abap_char_utilities=>newline.
    lv_doc = |[server]{ lv_nl }|
      && |host = 'localhost'{ lv_nl }|
      && |port = 8080{ lv_nl }|
      && |[server.tls]{ lv_nl }|
      && |enabled = false{ lv_nl }|.
    lo_toml = zcl_toml=>parse( lv_doc ).
    cl_abap_unit_assert=>assert_equals( exp = 'localhost'
                                        act = lo_toml->get_string( '/server/host' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 8080
                                        act = lo_toml->get_integer( '/server/port' ) ).
    cl_abap_unit_assert=>assert_false( lo_toml->get_boolean( '/server/tls/enabled' ) ).
  ENDMETHOD.

  METHOD test_dotted_keys.
    DATA lo_toml TYPE REF TO zcl_toml.

    lo_toml = zcl_toml=>parse( 'a.b.c = 1' ).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lo_toml->get_integer( '/a/b/c' ) ).
  ENDMETHOD.

  METHOD test_array.
    DATA lo_toml TYPE REF TO zcl_toml.
    DATA lv_nl   TYPE string.
    DATA lv_doc  TYPE string.

    lv_nl = cl_abap_char_utilities=>newline.
    lv_doc = |ports = [ 8000, 8001, 8002 ]{ lv_nl }names = [ 'a', 'b' ]{ lv_nl }|.
    lo_toml = zcl_toml=>parse( lv_doc ).
    cl_abap_unit_assert=>assert_equals( exp = 3
                                        act = lo_toml->array_length( '/ports' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 8000
                                        act = lo_toml->get_integer( '/ports/0' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'b'
                                        act = lo_toml->get_string( '/names/1' ) ).
  ENDMETHOD.

  METHOD test_inline_table.
    DATA lo_toml TYPE REF TO zcl_toml.

    lo_toml = zcl_toml=>parse( 'point = { x = 1, y = 2 }' ).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lo_toml->get_integer( '/point/x' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lo_toml->get_integer( '/point/y' ) ).
  ENDMETHOD.

  METHOD test_array_table.
    DATA lo_toml TYPE REF TO zcl_toml.
    DATA lv_nl   TYPE string.
    DATA lv_doc  TYPE string.

    lv_nl = cl_abap_char_utilities=>newline.
    lv_doc = |[[products]]{ lv_nl }|
      && |name = 'Hammer'{ lv_nl }|
      && |[[products]]{ lv_nl }|
      && |name = 'Nail'{ lv_nl }|.
    lo_toml = zcl_toml=>parse( lv_doc ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lo_toml->array_length( '/products' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'Hammer'
                                        act = lo_toml->get_string( '/products/0/name' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'Nail'
                                        act = lo_toml->get_string( '/products/1/name' ) ).
  ENDMETHOD.

  METHOD test_strings.
    DATA lo_toml TYPE REF TO zcl_toml.
    DATA lv_nl   TYPE string.
    DATA lv_doc  TYPE string.

    lv_nl = cl_abap_char_utilities=>newline.
    lv_doc = |a = 'C:\\tmp'{ lv_nl }b = 'plain'{ lv_nl }|.
    lo_toml = zcl_toml=>parse( lv_doc ).
    cl_abap_unit_assert=>assert_equals( exp = 'C:\tmp'
                                        act = lo_toml->get_string( '/a' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'plain'
                                        act = lo_toml->get_string( '/b' ) ).
  ENDMETHOD.

  METHOD test_numbers.
    DATA lo_toml TYPE REF TO zcl_toml.
    DATA lv_nl   TYPE string.
    DATA lv_doc  TYPE string.

    lv_nl = cl_abap_char_utilities=>newline.
    lv_doc = |a = 1_000{ lv_nl }b = 0xFF{ lv_nl }c = 1e6{ lv_nl }|.
    lo_toml = zcl_toml=>parse( lv_doc ).
    cl_abap_unit_assert=>assert_equals( exp = 1000
                                        act = lo_toml->get_integer( '/a' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'integer'
                                        act = lo_toml->get_kind( '/b' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'float'
                                        act = lo_toml->get_kind( '/c' ) ).
  ENDMETHOD.

  METHOD test_datetime.
    DATA lo_toml TYPE REF TO zcl_toml.
    DATA lv_nl   TYPE string.
    DATA lv_doc  TYPE string.

    lv_nl = cl_abap_char_utilities=>newline.
    lv_doc = |d = 1979-05-27T07:32:00Z{ lv_nl }day = 1979-05-27{ lv_nl }|.
    lo_toml = zcl_toml=>parse( lv_doc ).
    cl_abap_unit_assert=>assert_equals( exp = 'datetime'
                                        act = lo_toml->get_kind( '/d' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'date'
                                        act = lo_toml->get_kind( '/day' ) ).
  ENDMETHOD.

  METHOD test_write_api.
    DATA lo_toml TYPE REF TO zcl_toml.

    lo_toml = zcl_toml=>create_empty( ).
    lo_toml->set_string( iv_path  = '/server/host'
                         iv_value = 'example.com' ).
    lo_toml->set_integer( iv_path  = '/server/port'
                          iv_value = 8080 ).
    lo_toml->set_boolean( iv_path  = '/server/on'
                          iv_value = abap_true ).
    lo_toml->touch_array( '/ports' ).
    lo_toml->array_append_integer( iv_path  = '/ports'
                                   iv_value = 1 ).
    lo_toml->array_append_integer( iv_path  = '/ports'
                                   iv_value = 2 ).
    cl_abap_unit_assert=>assert_equals( exp = 'example.com'
                                        act = lo_toml->get_string( '/server/host' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lo_toml->array_length( '/ports' ) ).
    cl_abap_unit_assert=>assert_false( lo_toml->exists( '/server/missing' ) ).
    lo_toml->delete_node( '/server/on' ).
    cl_abap_unit_assert=>assert_false( lo_toml->exists( '/server/on' ) ).
  ENDMETHOD.

  METHOD test_roundtrip.
    DATA lo_toml TYPE REF TO zcl_toml.
    DATA lo_back TYPE REF TO zcl_toml.
    DATA lv_nl   TYPE string.
    DATA lv_doc  TYPE string.
    DATA lv_toml TYPE string.

    lv_nl = cl_abap_char_utilities=>newline.
    lv_doc = |title = 'x'{ lv_nl }[srv]{ lv_nl }port = 1{ lv_nl }|.
    lo_toml = zcl_toml=>parse( lv_doc ).
    lv_toml = lo_toml->stringify( ).
    lo_back = zcl_toml=>parse( lv_toml ).
    cl_abap_unit_assert=>assert_equals( exp = 'x'
                                        act = lo_back->get_string( '/title' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lo_back->get_integer( '/srv/port' ) ).
  ENDMETHOD.

  METHOD test_errors.
    " TODO: variable is assigned but never used (ABAP cleaner)
    DATA lo_toml   TYPE REF TO zcl_toml.
    DATA lv_nl     TYPE string.
    DATA lv_doc    TYPE string.
    DATA lv_failed TYPE abap_bool.

    lv_nl = cl_abap_char_utilities=>newline.
    TRY.
        lv_doc = |a = 1{ lv_nl }a = 2{ lv_nl }|.
        lo_toml = zcl_toml=>parse( lv_doc ).
        lv_failed = abap_false.
      CATCH zcx_toml_error.
        lv_failed = abap_true.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( lv_failed ).
    TRY.
        lv_doc = |no equals here{ lv_nl }|.
        lo_toml = zcl_toml=>parse( lv_doc ).
        lv_failed = abap_false.
      CATCH zcx_toml_error.
        lv_failed = abap_true.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( lv_failed ).
  ENDMETHOD.
ENDCLASS.
