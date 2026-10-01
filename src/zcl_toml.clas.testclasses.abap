CLASS ltcl_toml_test DEFINITION
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    METHODS test_scalars                   FOR TESTING RAISING zcx_toml_error.
    METHODS test_multiline_strings         FOR TESTING RAISING zcx_toml_error.
    METHODS test_literal_strings           FOR TESTING RAISING zcx_toml_error.
    METHODS test_string_escapes            FOR TESTING RAISING zcx_toml_error.
    METHODS test_integers_formats          FOR TESTING RAISING zcx_toml_error.
    METHODS test_floats_formats            FOR TESTING RAISING zcx_toml_error.
    METHODS test_booleans                  FOR TESTING RAISING zcx_toml_error.
    METHODS test_datetime_varieties        FOR TESTING RAISING zcx_toml_error.
    METHODS test_keys_varieties            FOR TESTING RAISING zcx_toml_error.
    METHODS test_empty_and_special_keys    FOR TESTING RAISING zcx_toml_error.
    METHODS test_arrays_varieties          FOR TESTING RAISING zcx_toml_error.
    METHODS test_array_trailing_commas     FOR TESTING RAISING zcx_toml_error.
    METHODS test_array_multiline_comments  FOR TESTING RAISING zcx_toml_error.
    METHODS test_array_of_inline_tables    FOR TESTING RAISING zcx_toml_error.
    METHODS test_inline_tables             FOR TESTING RAISING zcx_toml_error.
    METHODS test_nested_inline_tables      FOR TESTING RAISING zcx_toml_error.
    METHODS test_standard_tables           FOR TESTING RAISING zcx_toml_error.
    METHODS test_table_name_with_quotes    FOR TESTING RAISING zcx_toml_error.
    METHODS test_array_of_tables           FOR TESTING RAISING zcx_toml_error.
    METHODS test_deep_array_of_tables      FOR TESTING RAISING zcx_toml_error.
    METHODS test_comments_and_whitespace   FOR TESTING RAISING zcx_toml_error.
    METHODS test_path_crud_api             FOR TESTING RAISING zcx_toml_error.
    METHODS test_path_edge_cases           FOR TESTING RAISING zcx_toml_error.
    METHODS test_serialization_roundtrip   FOR TESTING RAISING zcx_toml_error.
    METHODS test_serial_special_chars      FOR TESTING RAISING zcx_toml_error.
    METHODS test_heterogeneous_arrays      FOR TESTING RAISING zcx_toml_error.
    METHODS test_dotted_key_with_spaces    FOR TESTING RAISING zcx_toml_error.
    METHODS test_table_with_dotted_keys    FOR TESTING RAISING zcx_toml_error.
    METHODS test_integers_signs_and_zeroes FOR TESTING RAISING zcx_toml_error.
    METHODS test_consecutive_aot           FOR TESTING RAISING zcx_toml_error.
    METHODS test_reopen_table_subtable     FOR TESTING RAISING zcx_toml_error.
    METHODS test_multiline_literal_quotes  FOR TESTING RAISING zcx_toml_error.
    METHODS test_syntax_errors             FOR TESTING.
    METHODS test_syntax_errors_extended    FOR TESTING.
    METHODS test_type_and_path_errors      FOR TESTING RAISING zcx_toml_error.
ENDCLASS.


CLASS ltcl_toml_test IMPLEMENTATION.
  METHOD test_scalars.
    DATA lo_toml TYPE REF TO zcl_toml.
    DATA lv_nl   TYPE string.
    DATA lv_doc  TYPE string.

    lv_nl = cl_abap_char_utilities=>newline.
    lv_doc = |title = "TOML Example"{ lv_nl }|
          && |count = 42{ lv_nl }|
          && |ratio = 3.5{ lv_nl }|
          && |active = true{ lv_nl }|.
    lo_toml = zcl_toml=>parse( lv_doc ).
    cl_abap_unit_assert=>assert_equals( exp = 'TOML Example'
                                        act = lo_toml->get_string( '/title' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 42
                                        act = lo_toml->get_integer( '/count' ) ).
    cl_abap_unit_assert=>assert_true( lo_toml->get_boolean( '/active' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'float'
                                        act = lo_toml->get_kind( '/ratio' ) ).
  ENDMETHOD.

  METHOD test_multiline_strings.
    DATA lo_toml TYPE REF TO zcl_toml.
    DATA lv_nl   TYPE string.
    DATA lv_doc  TYPE string.

    lv_nl = cl_abap_char_utilities=>newline.
    lv_doc = |multi = """{ lv_nl }The quick brown{ lv_nl }fox jumps over{ lv_nl }the lazy dog."""{ lv_nl }|.
    lo_toml = zcl_toml=>parse( lv_doc ).
    cl_abap_unit_assert=>assert_equals( exp = |The quick brown{ lv_nl }fox jumps over{ lv_nl }the lazy dog.|
                                        act = lo_toml->get_string( '/multi' ) ).
  ENDMETHOD.

  METHOD test_literal_strings.
    DATA lo_toml TYPE REF TO zcl_toml.
    DATA lv_nl   TYPE string.
    DATA lv_doc  TYPE string.

    lv_nl = cl_abap_char_utilities=>newline.
    lv_doc = |winpath  = 'C:\\Users\\nodejs\\templates'{ lv_nl }|
          && |winpath2 = '\\\\ServerX\\admin$\\system32'{ lv_nl }|
          && |quoted   = 'Tom "Dubs" Preston-Werner'{ lv_nl }|
          && |regex    = '<\\i\\c*\\s*>'{ lv_nl }|
          && |litmulti = '''{ lv_nl }first line{ lv_nl }second line\\not\\escaped'''{ lv_nl }|.
    lo_toml = zcl_toml=>parse( lv_doc ).
    cl_abap_unit_assert=>assert_equals( exp = 'C:\Users\nodejs\templates'
                                        act = lo_toml->get_string( '/winpath' ) ).
    cl_abap_unit_assert=>assert_equals( exp = '\\ServerX\admin$\system32'
                                        act = lo_toml->get_string( '/winpath2' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'Tom "Dubs" Preston-Werner'
                                        act = lo_toml->get_string( '/quoted' ) ).
    cl_abap_unit_assert=>assert_equals( exp = '<\i\c*\s*>'
                                        act = lo_toml->get_string( '/regex' ) ).
    cl_abap_unit_assert=>assert_equals( exp = |first line{ lv_nl }second line\\not\\escaped|
                                        act = lo_toml->get_string( '/litmulti' ) ).
  ENDMETHOD.

  METHOD test_string_escapes.
    DATA lo_toml TYPE REF TO zcl_toml.
    DATA lv_nl   TYPE string.
    DATA lv_tab  TYPE string.
    DATA lv_doc  TYPE string.

    lv_nl = cl_abap_char_utilities=>newline.
    lv_tab = cl_abap_char_utilities=>horizontal_tab.
    lv_doc = |tab = "A\\tB"{ lv_nl }|
          && |newline = "Line1\\nLine2"{ lv_nl }|
          && |quotes = "He said \\"Hello\\""{ lv_nl }|
          && |backslash = "C:\\\\Windows"{ lv_nl }|
          && |unicode = "\\u0041\\u0042"{ lv_nl }|.
    lo_toml = zcl_toml=>parse( lv_doc ).
    cl_abap_unit_assert=>assert_equals( exp = |A{ lv_tab }B|
                                        act = lo_toml->get_string( '/tab' ) ).
    cl_abap_unit_assert=>assert_equals( exp = |Line1{ lv_nl }Line2|
                                        act = lo_toml->get_string( '/newline' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'He said "Hello"'
                                        act = lo_toml->get_string( '/quotes' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'C:\Windows'
                                        act = lo_toml->get_string( '/backslash' ) ).
    cl_abap_unit_assert=>assert_equals( exp = '00410042'
                                        act = lo_toml->get_string( '/unicode' ) ).
  ENDMETHOD.

  METHOD test_integers_formats.
    DATA lo_toml TYPE REF TO zcl_toml.
    DATA lv_nl   TYPE string.
    DATA lv_doc  TYPE string.

    lv_nl = cl_abap_char_utilities=>newline.
    lv_doc = |int1 = +99{ lv_nl }|
          && |int2 = 42{ lv_nl }|
          && |int3 = 0{ lv_nl }|
          && |int4 = -17{ lv_nl }|
          && |int5 = 1_000{ lv_nl }|
          && |int6 = 5_349_221{ lv_nl }|
          && |hex1 = 0xDEADBEEF{ lv_nl }|
          && |hex2 = 0xdeadbeef{ lv_nl }|
          && |oct1 = 0o755{ lv_nl }|
          && |bin1 = 0b11010110{ lv_nl }|.
    lo_toml = zcl_toml=>parse( lv_doc ).
    cl_abap_unit_assert=>assert_equals( exp = 99
                                        act = lo_toml->get_integer( '/int1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 42
                                        act = lo_toml->get_integer( '/int2' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = lo_toml->get_integer( '/int3' ) ).
    cl_abap_unit_assert=>assert_equals( exp = -17
                                        act = lo_toml->get_integer( '/int4' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 1000
                                        act = lo_toml->get_integer( '/int5' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 5349221
                                        act = lo_toml->get_integer( '/int6' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'integer'
                                        act = lo_toml->get_kind( '/hex1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'integer'
                                        act = lo_toml->get_kind( '/oct1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'integer'
                                        act = lo_toml->get_kind( '/bin1' ) ).
  ENDMETHOD.

  METHOD test_floats_formats.
    DATA lo_toml TYPE REF TO zcl_toml.
    DATA lv_nl   TYPE string.
    DATA lv_doc  TYPE string.

    lv_nl = cl_abap_char_utilities=>newline.
    lv_doc = |flt1 = +1.0{ lv_nl }|
          && |flt2 = 3.1415{ lv_nl }|
          && |flt3 = -0.01{ lv_nl }|
          && |flt4 = 5e+22{ lv_nl }|
          && |flt5 = 1e06{ lv_nl }|
          && |flt6 = -2E-2{ lv_nl }|
          && |flt7 = 224_617.445_991_228{ lv_nl }|
          && |inf1 = inf{ lv_nl }|
          && |inf2 = +inf{ lv_nl }|
          && |inf3 = -inf{ lv_nl }|
          && |nan1 = nan{ lv_nl }|.
    lo_toml = zcl_toml=>parse( lv_doc ).
    cl_abap_unit_assert=>assert_equals( exp = 'float'
                                        act = lo_toml->get_kind( '/flt1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'float'
                                        act = lo_toml->get_kind( '/flt2' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'float'
                                        act = lo_toml->get_kind( '/flt4' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'float'
                                        act = lo_toml->get_kind( '/flt7' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'float'
                                        act = lo_toml->get_kind( '/inf1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'float'
                                        act = lo_toml->get_kind( '/nan1' ) ).
  ENDMETHOD.

  METHOD test_booleans.
    DATA lo_toml TYPE REF TO zcl_toml.
    DATA lv_nl   TYPE string.
    DATA lv_doc  TYPE string.

    lv_nl = cl_abap_char_utilities=>newline.
    lv_doc = |bool1 = true{ lv_nl }bool2 = false{ lv_nl }|.
    lo_toml = zcl_toml=>parse( lv_doc ).
    cl_abap_unit_assert=>assert_true( lo_toml->get_boolean( '/bool1' ) ).
    cl_abap_unit_assert=>assert_false( lo_toml->get_boolean( '/bool2' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'boolean'
                                        act = lo_toml->get_kind( '/bool1' ) ).
  ENDMETHOD.

  METHOD test_datetime_varieties.
    DATA lo_toml TYPE REF TO zcl_toml.
    DATA lv_nl   TYPE string.
    DATA lv_doc  TYPE string.

    lv_nl = cl_abap_char_utilities=>newline.
    lv_doc = |odt1 = 1979-05-27T07:32:00Z{ lv_nl }|
          && |odt2 = 1979-05-27T00:32:00-07:00{ lv_nl }|
          && |odt3 = 1979-05-27T00:32:00.999999-07:00{ lv_nl }|
          && |ldt1 = 1979-05-27T07:32:00{ lv_nl }|
          && |ld1  = 1979-05-27{ lv_nl }|
          && |lt1  = 07:32:00{ lv_nl }|.
    lo_toml = zcl_toml=>parse( lv_doc ).
    cl_abap_unit_assert=>assert_equals( exp = 'datetime'
                                        act = lo_toml->get_kind( '/odt1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'datetime'
                                        act = lo_toml->get_kind( '/odt2' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'datetime'
                                        act = lo_toml->get_kind( '/ldt1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'date'
                                        act = lo_toml->get_kind( '/ld1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'time'
                                        act = lo_toml->get_kind( '/lt1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = '1979-05-27'
                                        act = lo_toml->get_string( '/ld1' ) ).
  ENDMETHOD.

  METHOD test_keys_varieties.
    DATA lo_toml TYPE REF TO zcl_toml.
    DATA lv_nl   TYPE string.
    DATA lv_doc  TYPE string.

    lv_nl = cl_abap_char_utilities=>newline.
    lv_doc = |key = "value"{ lv_nl }|
          && |bare_key = "value"{ lv_nl }|
          && |bare-key = "value"{ lv_nl }|
          && |1234 = "value"{ lv_nl }|
          && |"127.0.0.1" = "value"{ lv_nl }|
          && |'character encoding' = "value"{ lv_nl }|
          && |physical.color = "orange"{ lv_nl }|
          && |physical.shape = "round"{ lv_nl }|
          && |site."google.com" = true{ lv_nl }|.
    lo_toml = zcl_toml=>parse( lv_doc ).
    cl_abap_unit_assert=>assert_equals( exp = 'value'
                                        act = lo_toml->get_string( '/key' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'value'
                                        act = lo_toml->get_string( '/bare_key' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'value'
                                        act = lo_toml->get_string( '/127.0.0.1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'value'
                                        act = lo_toml->get_string( '/character encoding' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'orange'
                                        act = lo_toml->get_string( '/physical/color' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'round'
                                        act = lo_toml->get_string( '/physical/shape' ) ).
    cl_abap_unit_assert=>assert_true( lo_toml->get_boolean( '/site/google.com' ) ).
  ENDMETHOD.

  METHOD test_empty_and_special_keys.
    DATA lo_toml TYPE REF TO zcl_toml.
    DATA lv_nl   TYPE string.
    DATA lv_doc  TYPE string.

    lv_nl = cl_abap_char_utilities=>newline.
    lv_doc = |_ = "underscore"{ lv_nl }|
          && |- = "dash"{ lv_nl }|
          && |"a.b.c" = "quoted dots"{ lv_nl }|
          && |"127.0.0.1" = "ip address"{ lv_nl }|
          && |"key with spaces" = "spaced key"{ lv_nl }|.
    lo_toml = zcl_toml=>parse( lv_doc ).
    cl_abap_unit_assert=>assert_equals( exp = 'underscore'
                                        act = lo_toml->get_string( '/_' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'dash'
                                        act = lo_toml->get_string( '/-' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'quoted dots'
                                        act = lo_toml->get_string( '/a.b.c' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'ip address'
                                        act = lo_toml->get_string( '/127.0.0.1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'spaced key'
                                        act = lo_toml->get_string( '/key with spaces' ) ).
  ENDMETHOD.

  METHOD test_arrays_varieties.
    DATA lo_toml TYPE REF TO zcl_toml.
    DATA lv_nl   TYPE string.
    DATA lv_doc  TYPE string.

    lv_nl = cl_abap_char_utilities=>newline.
    lv_doc = |empty_arr = []{ lv_nl }|
          && |integers = [ 1, 2, 3 ]{ lv_nl }|
          && |colors = [ "red", "yellow", "green" ]{ lv_nl }|
          && |nested_arrays = [ [ 1, 2 ], [ 3, 4, 5 ] ]{ lv_nl }|
          && |multiline_arr = [{ lv_nl }|
          && |  1,{ lv_nl }|
          && |  2,{ lv_nl }|
          && |  # comment inside array{ lv_nl }|
          && |  3{ lv_nl }|
          && |]{ lv_nl }|.
    lo_toml = zcl_toml=>parse( lv_doc ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = lo_toml->array_length( '/empty_arr' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 3
                                        act = lo_toml->array_length( '/integers' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lo_toml->get_integer( '/integers/1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'yellow'
                                        act = lo_toml->get_string( '/colors/1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 3
                                        act = lo_toml->array_length( '/multiline_arr' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lo_toml->array_length( '/nested_arrays' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 4
                                        act = lo_toml->get_integer( '/nested_arrays/1/1' ) ).
  ENDMETHOD.

  METHOD test_array_trailing_commas.
    DATA lo_toml TYPE REF TO zcl_toml.
    DATA lv_nl   TYPE string.
    DATA lv_doc  TYPE string.

    lv_nl = cl_abap_char_utilities=>newline.
    lv_doc = |single_trailing = [ 10, 20, 30, ]{ lv_nl }|
          && |nested_trailing = [ [ "a", "b", ], [ "c", ], ]{ lv_nl }|.
    lo_toml = zcl_toml=>parse( lv_doc ).
    cl_abap_unit_assert=>assert_equals( exp = 3
                                        act = lo_toml->array_length( '/single_trailing' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 30
                                        act = lo_toml->get_integer( '/single_trailing/2' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lo_toml->array_length( '/nested_trailing' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'b'
                                        act = lo_toml->get_string( '/nested_trailing/0/1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'c'
                                        act = lo_toml->get_string( '/nested_trailing/1/0' ) ).
  ENDMETHOD.

  METHOD test_array_multiline_comments.
    DATA lo_toml TYPE REF TO zcl_toml.
    DATA lv_nl   TYPE string.
    DATA lv_doc  TYPE string.

    lv_nl = cl_abap_char_utilities=>newline.
    lv_doc = |items = [{ lv_nl }|
          && |  # first header comment{ lv_nl }|
          && |  "alpha", # inline comment 1{ lv_nl }|
          && |  # middle comment{ lv_nl }|
          && |  "beta",  # inline comment 2{ lv_nl }|
          && |  # footer comment{ lv_nl }|
          && |  "gamma",{ lv_nl }|
          && |  # trailing comment{ lv_nl }|
          && |]{ lv_nl }|.
    lo_toml = zcl_toml=>parse( lv_doc ).
    cl_abap_unit_assert=>assert_equals( exp = 3
                                        act = lo_toml->array_length( '/items' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'alpha'
                                        act = lo_toml->get_string( '/items/0' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'beta'
                                        act = lo_toml->get_string( '/items/1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'gamma'
                                        act = lo_toml->get_string( '/items/2' ) ).
  ENDMETHOD.

  METHOD test_array_of_inline_tables.
    DATA lo_toml TYPE REF TO zcl_toml.
    DATA lv_nl   TYPE string.
    DATA lv_doc  TYPE string.

    lv_nl = cl_abap_char_utilities=>newline.
    lv_doc = |points = [ \{ x = 1, y = 2 \}, \{ x = 3, y = 4 \}, \{ x = 5, y = 6 \} ]{ lv_nl }|.
    lo_toml = zcl_toml=>parse( lv_doc ).
    cl_abap_unit_assert=>assert_equals( exp = 3
                                        act = lo_toml->array_length( '/points' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lo_toml->get_integer( '/points/0/x' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lo_toml->get_integer( '/points/0/y' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 3
                                        act = lo_toml->get_integer( '/points/1/x' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 6
                                        act = lo_toml->get_integer( '/points/2/y' ) ).
  ENDMETHOD.

  METHOD test_inline_tables.
    DATA lo_toml TYPE REF TO zcl_toml.
    DATA lv_nl   TYPE string.
    DATA lv_doc  TYPE string.

    lv_nl = cl_abap_char_utilities=>newline.
    lv_doc = |empty_tbl = \{\}{ lv_nl }|
          && |name = \{ first = "Tom", last = "Preston-Werner" \}{ lv_nl }|
          && |point = \{ x = 1, y = 2 \}{ lv_nl }|
          && |animal = \{ type.name = "pug" \}{ lv_nl }|.
    lo_toml = zcl_toml=>parse( lv_doc ).
    cl_abap_unit_assert=>assert_true( lo_toml->exists( '/empty_tbl' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'Tom'
                                        act = lo_toml->get_string( '/name/first' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'Preston-Werner'
                                        act = lo_toml->get_string( '/name/last' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lo_toml->get_integer( '/point/x' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lo_toml->get_integer( '/point/y' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'pug'
                                        act = lo_toml->get_string( '/animal/type/name' ) ).
  ENDMETHOD.

  METHOD test_nested_inline_tables.
    DATA lo_toml TYPE REF TO zcl_toml.
    DATA lv_nl   TYPE string.
    DATA lv_doc  TYPE string.

    lv_nl = cl_abap_char_utilities=>newline.
    lv_doc = |box = \{ meta = \{ name = "gift", size = 10 \}, item = \{ id = 99 \} \}{ lv_nl }|.
    lo_toml = zcl_toml=>parse( lv_doc ).
    cl_abap_unit_assert=>assert_equals( exp = 'gift'
                                        act = lo_toml->get_string( '/box/meta/name' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 10
                                        act = lo_toml->get_integer( '/box/meta/size' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 99
                                        act = lo_toml->get_integer( '/box/item/id' ) ).
  ENDMETHOD.

  METHOD test_standard_tables.
    DATA lo_toml TYPE REF TO zcl_toml.
    DATA lv_nl   TYPE string.
    DATA lv_doc  TYPE string.

    lv_nl = cl_abap_char_utilities=>newline.
    lv_doc = |[table-1]{ lv_nl }|
          && |key1 = "some string"{ lv_nl }|
          && |key2 = 123{ lv_nl }|
          && |[table-2]{ lv_nl }|
          && |key1 = "another string"{ lv_nl }|
          && |[a.b.c]{ lv_nl }|
          && |leaf = true{ lv_nl }|
          && |[dog."tater.man"]{ lv_nl }|
          && |type.name = "pug"{ lv_nl }|.
    lo_toml = zcl_toml=>parse( lv_doc ).
    cl_abap_unit_assert=>assert_equals( exp = 'some string'
                                        act = lo_toml->get_string( '/table-1/key1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 123
                                        act = lo_toml->get_integer( '/table-1/key2' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'another string'
                                        act = lo_toml->get_string( '/table-2/key1' ) ).
    cl_abap_unit_assert=>assert_true( lo_toml->get_boolean( '/a/b/c/leaf' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'pug'
                                        act = lo_toml->get_string( '/dog/tater.man/type/name' ) ).
  ENDMETHOD.

  METHOD test_table_name_with_quotes.
    DATA lo_toml TYPE REF TO zcl_toml.
    DATA lv_nl   TYPE string.
    DATA lv_doc  TYPE string.

    lv_nl = cl_abap_char_utilities=>newline.
    lv_doc = |["site.google.com"]{ lv_nl }|
          && |status = 200{ lv_nl }|
          && |[servers."192.168.1.1"]{ lv_nl }|
          && |active = true{ lv_nl }|.
    lo_toml = zcl_toml=>parse( lv_doc ).
    cl_abap_unit_assert=>assert_equals( exp = 200
                                        act = lo_toml->get_integer( '/site.google.com/status' ) ).
    cl_abap_unit_assert=>assert_true( lo_toml->get_boolean( '/servers/192.168.1.1/active' ) ).
  ENDMETHOD.

  METHOD test_array_of_tables.
    DATA lo_toml TYPE REF TO zcl_toml.
    DATA lv_nl   TYPE string.
    DATA lv_doc  TYPE string.

    lv_nl = cl_abap_char_utilities=>newline.
    lv_doc = |[[products]]{ lv_nl }|
          && |name = "Hammer"{ lv_nl }|
          && |sku = 738594937{ lv_nl }|
          && |[[products]]{ lv_nl }|
          && |name = "Nail"{ lv_nl }|
          && |sku = 284758393{ lv_nl }|
          && |color = "gray"{ lv_nl }|
          && |[[fruit]]{ lv_nl }|
          && |name = "apple"{ lv_nl }|
          && |[fruit.physical]{ lv_nl }|
          && |color = "red"{ lv_nl }|
          && |[[fruit]]{ lv_nl }|
          && |name = "banana"{ lv_nl }|
          && |[fruit.physical]{ lv_nl }|
          && |color = "yellow"{ lv_nl }|.
    lo_toml = zcl_toml=>parse( lv_doc ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lo_toml->array_length( '/products' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'Hammer'
                                        act = lo_toml->get_string( '/products/0/name' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 738594937
                                        act = lo_toml->get_integer( '/products/0/sku' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'Nail'
                                        act = lo_toml->get_string( '/products/1/name' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'gray'
                                        act = lo_toml->get_string( '/products/1/color' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lo_toml->array_length( '/fruit' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'red'
                                        act = lo_toml->get_string( '/fruit/0/physical/color' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'yellow'
                                        act = lo_toml->get_string( '/fruit/1/physical/color' ) ).
  ENDMETHOD.

  METHOD test_deep_array_of_tables.
    DATA lo_toml TYPE REF TO zcl_toml.
    DATA lv_nl   TYPE string.
    DATA lv_doc  TYPE string.

    lv_nl = cl_abap_char_utilities=>newline.
    lv_doc = |[[fruit]]{ lv_nl }|
          && |name = "apple"{ lv_nl }|
          && |[[fruit.variety]]{ lv_nl }|
          && |name = "red delicious"{ lv_nl }|
          && |[[fruit.variety]]{ lv_nl }|
          && |name = "granny smith"{ lv_nl }|
          && |[[fruit]]{ lv_nl }|
          && |name = "banana"{ lv_nl }|
          && |[[fruit.variety]]{ lv_nl }|
          && |name = "plantain"{ lv_nl }|.
    lo_toml = zcl_toml=>parse( lv_doc ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lo_toml->array_length( '/fruit' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'apple'
                                        act = lo_toml->get_string( '/fruit/0/name' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lo_toml->array_length( '/fruit/0/variety' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'red delicious'
                                        act = lo_toml->get_string( '/fruit/0/variety/0/name' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'granny smith'
                                        act = lo_toml->get_string( '/fruit/0/variety/1/name' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'banana'
                                        act = lo_toml->get_string( '/fruit/1/name' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lo_toml->array_length( '/fruit/1/variety' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'plantain'
                                        act = lo_toml->get_string( '/fruit/1/variety/0/name' ) ).
  ENDMETHOD.

  METHOD test_comments_and_whitespace.
    DATA lo_toml TYPE REF TO zcl_toml.
    DATA lv_nl   TYPE string.
    DATA lv_doc  TYPE string.

    lv_nl = cl_abap_char_utilities=>newline.
    lv_doc = |# Document comment{ lv_nl }|
          && |   { lv_nl }|
          && |key1 = "value1" # End of line comment{ lv_nl }|
          && |# Whole line comment{ lv_nl }|
          && |key2 = 100   { lv_nl }|
          && |[section] # Section comment{ lv_nl }|
          && |inner = "hello"   { lv_nl }|.
    lo_toml = zcl_toml=>parse( lv_doc ).
    cl_abap_unit_assert=>assert_equals( exp = 'value1'
                                        act = lo_toml->get_string( '/key1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 100
                                        act = lo_toml->get_integer( '/key2' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'hello'
                                        act = lo_toml->get_string( '/section/inner' ) ).
  ENDMETHOD.

  METHOD test_path_crud_api.
    DATA lo_toml TYPE REF TO zcl_toml.

    lo_toml = zcl_toml=>create_empty( ).
    cl_abap_unit_assert=>assert_true( lo_toml->exists( '/' ) ).
    cl_abap_unit_assert=>assert_false( lo_toml->exists( '/config' ) ).

    " Set scalar values (automatic table hierarchy creation)
    lo_toml->set_string( iv_path  = '/app/network/host'
                         iv_value = '127.0.0.1' ).
    lo_toml->set_integer( iv_path  = '/app/network/port'
                          iv_value = 8080 ).
    lo_toml->set_float( iv_path  = '/app/performance/timeout'
                        iv_value = '2.5' ).
    lo_toml->set_boolean( iv_path  = '/app/debug'
                          iv_value = abap_true ).
    lo_toml->set_datetime( iv_path  = '/app/release_date'
                           iv_value = '2026-10-01' ).

    cl_abap_unit_assert=>assert_true( lo_toml->exists( '/app/network/host' ) ).
    cl_abap_unit_assert=>assert_equals( exp = '127.0.0.1'
                                        act = lo_toml->get_string( '/app/network/host' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 8080
                                        act = lo_toml->get_integer( '/app/network/port' ) ).
    cl_abap_unit_assert=>assert_true( lo_toml->get_boolean( '/app/debug' ) ).
    cl_abap_unit_assert=>assert_equals( exp = '2026-10-01'
                                        act = lo_toml->get_string( '/app/release_date' ) ).

    " Overwrite existing scalar value
    lo_toml->set_integer( iv_path  = '/app/network/port'
                          iv_value = 9090 ).
    cl_abap_unit_assert=>assert_equals( exp = 9090
                                        act = lo_toml->get_integer( '/app/network/port' ) ).

    " Array operations
    lo_toml->touch_array( '/services' ).
    lo_toml->array_append_string( iv_path  = '/services'
                                  iv_value = 'auth' ).
    lo_toml->array_append_string( iv_path  = '/services'
                                  iv_value = 'payment' ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lo_toml->array_length( '/services' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'auth'
                                        act = lo_toml->get_string( '/services/0' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'payment'
                                        act = lo_toml->get_string( '/services/1' ) ).

    " Deletion
    lo_toml->delete_node( '/app/network/port' ).
    cl_abap_unit_assert=>assert_false( lo_toml->exists( '/app/network/port' ) ).
    cl_abap_unit_assert=>assert_true( lo_toml->exists( '/app/network/host' ) ).

    lo_toml->delete_node( '/app/network' ).
    cl_abap_unit_assert=>assert_false( lo_toml->exists( '/app/network' ) ).
    cl_abap_unit_assert=>assert_false( lo_toml->exists( '/app/network/host' ) ).

    " Clear document
    lo_toml->clear( ).
    cl_abap_unit_assert=>assert_true( lo_toml->exists( '/' ) ).
    cl_abap_unit_assert=>assert_false( lo_toml->exists( '/services' ) ).
    cl_abap_unit_assert=>assert_false( lo_toml->exists( '/app' ) ).
  ENDMETHOD.

  METHOD test_path_edge_cases.
    DATA lo_toml   TYPE REF TO zcl_toml.
    DATA lv_failed TYPE abap_bool.

    lo_toml = zcl_toml=>create_empty( ).
    lo_toml->set_string( iv_path  = '/deep/nested/path/to/value'
                         iv_value = 'treasure' ).
    cl_abap_unit_assert=>assert_equals( exp = 'treasure'
                                        act = lo_toml->get_string( '/deep/nested/path/to/value' ) ).

    " Append to non-array should raise error
    TRY.
        lo_toml->array_append_string( iv_path  = '/deep/nested/path/to/value'
                                      iv_value = 'fail' ).
        lv_failed = abap_false.
      CATCH zcx_toml_error.
        lv_failed = abap_true.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( lv_failed ).

    " Out of bounds array index access
    lo_toml->touch_array( '/list' ).
    lo_toml->array_append_integer( iv_path  = '/list'
                                   iv_value = 10 ).
    TRY.
        lo_toml->get_integer( '/list/5' ).
        lv_failed = abap_false.
      CATCH zcx_toml_error.
        lv_failed = abap_true.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( lv_failed ).
  ENDMETHOD.

  METHOD test_serialization_roundtrip.
    DATA lo_toml TYPE REF TO zcl_toml.
    DATA lo_back TYPE REF TO zcl_toml.
    DATA lv_nl   TYPE string.
    DATA lv_doc  TYPE string.
    DATA lv_out  TYPE string.

    lv_nl = cl_abap_char_utilities=>newline.
    lv_doc = |title = "Complex Roundtrip"{ lv_nl }|
          && |count = 100{ lv_nl }|
          && |enabled = true{ lv_nl }|
          && |tags = [ "abap", "toml", "parser" ]{ lv_nl }|
          && |[database]{ lv_nl }|
          && |server = "192.168.1.1"{ lv_nl }|
          && |port = 5432{ lv_nl }|
          && |[database.credentials]{ lv_nl }|
          && |user = "admin"{ lv_nl }|
          && |[[clients]]{ lv_nl }|
          && |name = "Client A"{ lv_nl }|
          && |[[clients]]{ lv_nl }|
          && |name = "Client B"{ lv_nl }|.

    lo_toml = zcl_toml=>parse( lv_doc ).
    lv_out = lo_toml->stringify( ).
    lo_back = zcl_toml=>parse( lv_out ).

    cl_abap_unit_assert=>assert_equals( exp = 'Complex Roundtrip'
                                        act = lo_back->get_string( '/title' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 100
                                        act = lo_back->get_integer( '/count' ) ).
    cl_abap_unit_assert=>assert_true( lo_back->get_boolean( '/enabled' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 3
                                        act = lo_back->array_length( '/tags' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'toml'
                                        act = lo_back->get_string( '/tags/1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = '192.168.1.1'
                                        act = lo_back->get_string( '/database/server' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 5432
                                        act = lo_back->get_integer( '/database/port' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'admin'
                                        act = lo_back->get_string( '/database/credentials/user' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lo_back->array_length( '/clients' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'Client A'
                                        act = lo_back->get_string( '/clients/0/name' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'Client B'
                                        act = lo_back->get_string( '/clients/1/name' ) ).
  ENDMETHOD.

  METHOD test_serial_special_chars.
    DATA lo_toml TYPE REF TO zcl_toml.
    DATA lo_back TYPE REF TO zcl_toml.
    DATA lv_nl   TYPE string.
    DATA lv_tab  TYPE string.
    DATA lv_doc  TYPE string.
    DATA lv_out  TYPE string.

    lv_nl = cl_abap_char_utilities=>newline.
    lv_tab = cl_abap_char_utilities=>horizontal_tab.
    lv_doc = |escaped = "Hello \\"World\\" with \\\\ backslash and \\n newline and \\t tab"{ lv_nl }|.
    lo_toml = zcl_toml=>parse( lv_doc ).
    lv_out = lo_toml->stringify( ).
    lo_back = zcl_toml=>parse( lv_out ).

    cl_abap_unit_assert=>assert_equals( exp = |Hello "World" with \\ backslash and { lv_nl } newline and { lv_tab } tab|
                                        act = lo_back->get_string( '/escaped' ) ).
  ENDMETHOD.

  METHOD test_syntax_errors.
    " TODO: variable is assigned but never used (ABAP cleaner)
    DATA lo_toml   TYPE REF TO zcl_toml.
    DATA lv_nl     TYPE string.
    DATA lv_doc    TYPE string.
    DATA lv_failed TYPE abap_bool.

    lv_nl = cl_abap_char_utilities=>newline.

    " Duplicate key in same table
    TRY.
        lv_doc = |a = 1{ lv_nl }a = 2{ lv_nl }|.
        lo_toml = zcl_toml=>parse( lv_doc ).
        lv_failed = abap_false.
      CATCH zcx_toml_error.
        lv_failed = abap_true.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( lv_failed ).

    " Missing equals sign
    TRY.
        lv_doc = |invalid key line without equal{ lv_nl }|.
        lo_toml = zcl_toml=>parse( lv_doc ).
        lv_failed = abap_false.
      CATCH zcx_toml_error.
        lv_failed = abap_true.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( lv_failed ).

    " Unterminated basic string
    TRY.
        lv_doc = |str = "unterminated string{ lv_nl }|.
        lo_toml = zcl_toml=>parse( lv_doc ).
        lv_failed = abap_false.
      CATCH zcx_toml_error.
        lv_failed = abap_true.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( lv_failed ).

    " Unterminated literal string
    TRY.
        lv_doc = |str = 'unterminated literal{ lv_nl }|.
        lo_toml = zcl_toml=>parse( lv_doc ).
        lv_failed = abap_false.
      CATCH zcx_toml_error.
        lv_failed = abap_true.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( lv_failed ).

    " Unterminated multiline basic string
    TRY.
        lv_doc = |str = """unterminated multiline{ lv_nl }|.
        lo_toml = zcl_toml=>parse( lv_doc ).
        lv_failed = abap_false.
      CATCH zcx_toml_error.
        lv_failed = abap_true.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( lv_failed ).

    " Unterminated array
    TRY.
        lv_doc = |arr = [ 1, 2, 3{ lv_nl }|.
        lo_toml = zcl_toml=>parse( lv_doc ).
        lv_failed = abap_false.
      CATCH zcx_toml_error.
        lv_failed = abap_true.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( lv_failed ).

    " Unterminated inline table
    TRY.
        lv_doc = |tbl = \{ a = 1, b = 2{ lv_nl }|.
        lo_toml = zcl_toml=>parse( lv_doc ).
        lv_failed = abap_false.
      CATCH zcx_toml_error.
        lv_failed = abap_true.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( lv_failed ).

    " Malformed table header
    TRY.
        lv_doc = |[unclosed_table{ lv_nl }|.
        lo_toml = zcl_toml=>parse( lv_doc ).
        lv_failed = abap_false.
      CATCH zcx_toml_error.
        lv_failed = abap_true.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( lv_failed ).

    " Duplicate table definition
    TRY.
        lv_doc = |[servers]{ lv_nl }alpha = 1{ lv_nl }[servers]{ lv_nl }beta = 2{ lv_nl }|.
        lo_toml = zcl_toml=>parse( lv_doc ).
        lv_failed = abap_false.
      CATCH zcx_toml_error.
        lv_failed = abap_true.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( lv_failed ).
  ENDMETHOD.

  METHOD test_syntax_errors_extended.
    " TODO: variable is assigned but never used (ABAP cleaner)
    DATA lo_toml   TYPE REF TO zcl_toml.
    DATA lv_nl     TYPE string.
    DATA lv_doc    TYPE string.
    DATA lv_failed TYPE abap_bool.

    lv_nl = cl_abap_char_utilities=>newline.

    " Missing value after equals
    TRY.
        lv_doc = |key ={ lv_nl }|.
        lo_toml = zcl_toml=>parse( lv_doc ).
        lv_failed = abap_false.
      CATCH zcx_toml_error.
        lv_failed = abap_true.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( lv_failed ).

    " Empty key segment
    TRY.
        lv_doc = |a..b = 1{ lv_nl }|.
        lo_toml = zcl_toml=>parse( lv_doc ).
        lv_failed = abap_false.
      CATCH zcx_toml_error.
        lv_failed = abap_true.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( lv_failed ).

    " Trailing backslash in string
    TRY.
        lv_doc = |str = "abc\\"{ lv_nl }|.
        lo_toml = zcl_toml=>parse( lv_doc ).
        lv_failed = abap_false.
      CATCH zcx_toml_error.
        lv_failed = abap_true.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( lv_failed ).

    " Unknown escape sequence
    TRY.
        lv_doc = |str = "\\q"{ lv_nl }|.
        lo_toml = zcl_toml=>parse( lv_doc ).
        lv_failed = abap_false.
      CATCH zcx_toml_error.
        lv_failed = abap_true.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( lv_failed ).

    " Incomplete 4-digit unicode escape
    TRY.
        lv_doc = |str = "\\u123"{ lv_nl }|.
        lo_toml = zcl_toml=>parse( lv_doc ).
        lv_failed = abap_false.
      CATCH zcx_toml_error.
        lv_failed = abap_true.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( lv_failed ).

    " Invalid array table header (unclosed double bracket)
    TRY.
        lv_doc = |[[array_table]{ lv_nl }|.
        lo_toml = zcl_toml=>parse( lv_doc ).
        lv_failed = abap_false.
      CATCH zcx_toml_error.
        lv_failed = abap_true.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( lv_failed ).
  ENDMETHOD.

  METHOD test_type_and_path_errors.
    DATA lo_toml   TYPE REF TO zcl_toml.
    DATA lv_failed TYPE abap_bool.
    DATA lv_nl     TYPE string.
    DATA lv_doc    TYPE string.

    lv_nl = cl_abap_char_utilities=>newline.
    lv_doc = |val_str = "hello"{ lv_nl }val_int = 42{ lv_nl }val_bool = true{ lv_nl }|.
    lo_toml = zcl_toml=>parse( lv_doc ).

    " Non-existing path
    TRY.
        lo_toml->get_string( '/non_existent' ).
        lv_failed = abap_false.
      CATCH zcx_toml_error.
        lv_failed = abap_true.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( lv_failed ).

    " Type mismatch: get_integer on string
    TRY.
        lo_toml->get_integer( '/val_str' ).
        lv_failed = abap_false.
      CATCH zcx_toml_error.
        lv_failed = abap_true.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( lv_failed ).

    " Type mismatch: get_boolean on integer
    TRY.
        lo_toml->get_boolean( '/val_int' ).
        lv_failed = abap_false.
      CATCH zcx_toml_error.
        lv_failed = abap_true.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( lv_failed ).

    " Cannot delete root node
    TRY.
        lo_toml->delete_node( '/' ).
        lv_failed = abap_false.
      CATCH zcx_toml_error.
        lv_failed = abap_true.
    ENDTRY.
    cl_abap_unit_assert=>assert_true( lv_failed ).
  ENDMETHOD.

  METHOD test_heterogeneous_arrays.
    DATA lo_toml TYPE REF TO zcl_toml.
    DATA lv_nl   TYPE string.
    DATA lv_doc  TYPE string.

    lv_nl = cl_abap_char_utilities=>newline.
    lv_doc = |mixed = [ 1, "two", 3.5, true ]{ lv_nl }|.
    lo_toml = zcl_toml=>parse( lv_doc ).
    cl_abap_unit_assert=>assert_equals( exp = 4
                                        act = lo_toml->array_length( '/mixed' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lo_toml->get_integer( '/mixed/0' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'two'
                                        act = lo_toml->get_string( '/mixed/1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'float'
                                        act = lo_toml->get_kind( '/mixed/2' ) ).
    cl_abap_unit_assert=>assert_true( lo_toml->get_boolean( '/mixed/3' ) ).
  ENDMETHOD.

  METHOD test_dotted_key_with_spaces.
    DATA lo_toml TYPE REF TO zcl_toml.
    DATA lv_nl   TYPE string.
    DATA lv_doc  TYPE string.

    lv_nl = cl_abap_char_utilities=>newline.
    lv_doc = |a . b . c = 123{ lv_nl }|
          && |site . "sub domain" . val = true{ lv_nl }|.
    lo_toml = zcl_toml=>parse( lv_doc ).
    cl_abap_unit_assert=>assert_equals( exp = 123
                                        act = lo_toml->get_integer( '/a/b/c' ) ).
    cl_abap_unit_assert=>assert_true( lo_toml->get_boolean( '/site/sub domain/val' ) ).
  ENDMETHOD.

  METHOD test_table_with_dotted_keys.
    DATA lo_toml TYPE REF TO zcl_toml.
    DATA lv_nl   TYPE string.
    DATA lv_doc  TYPE string.

    lv_nl = cl_abap_char_utilities=>newline.
    lv_doc = |[fruit]{ lv_nl }|
          && |apple.color = "red"{ lv_nl }|
          && |apple.taste.sweet = true{ lv_nl }|.
    lo_toml = zcl_toml=>parse( lv_doc ).
    cl_abap_unit_assert=>assert_equals( exp = 'red'
                                        act = lo_toml->get_string( '/fruit/apple/color' ) ).
    cl_abap_unit_assert=>assert_true( lo_toml->get_boolean( '/fruit/apple/taste/sweet' ) ).
  ENDMETHOD.

  METHOD test_integers_signs_and_zeroes.
    DATA lo_toml TYPE REF TO zcl_toml.
    DATA lv_nl   TYPE string.
    DATA lv_doc  TYPE string.

    lv_nl = cl_abap_char_utilities=>newline.
    lv_doc = |z1 = 0{ lv_nl }|
          && |z2 = +0{ lv_nl }|
          && |z3 = -0{ lv_nl }|
          && |pos = +12345{ lv_nl }|
          && |neg = -12345{ lv_nl }|.
    lo_toml = zcl_toml=>parse( lv_doc ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = lo_toml->get_integer( '/z1' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = lo_toml->get_integer( '/z2' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 0
                                        act = lo_toml->get_integer( '/z3' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 12345
                                        act = lo_toml->get_integer( '/pos' ) ).
    cl_abap_unit_assert=>assert_equals( exp = -12345
                                        act = lo_toml->get_integer( '/neg' ) ).
  ENDMETHOD.

  METHOD test_consecutive_aot.
    DATA lo_toml TYPE REF TO zcl_toml.
    DATA lv_nl   TYPE string.
    DATA lv_doc  TYPE string.

    lv_nl = cl_abap_char_utilities=>newline.
    lv_doc = |[[alpha]]{ lv_nl }|
          && |id = 1{ lv_nl }|
          && |[[beta]]{ lv_nl }|
          && |id = 2{ lv_nl }|
          && |[[alpha]]{ lv_nl }|
          && |id = 3{ lv_nl }|.
    lo_toml = zcl_toml=>parse( lv_doc ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lo_toml->array_length( '/alpha' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lo_toml->get_integer( '/alpha/0/id' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 3
                                        act = lo_toml->get_integer( '/alpha/1/id' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lo_toml->array_length( '/beta' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lo_toml->get_integer( '/beta/0/id' ) ).
  ENDMETHOD.

  METHOD test_reopen_table_subtable.
    DATA lo_toml TYPE REF TO zcl_toml.
    DATA lv_nl   TYPE string.
    DATA lv_doc  TYPE string.

    lv_nl = cl_abap_char_utilities=>newline.
    lv_doc = |[parent]{ lv_nl }|
          && |x = 1{ lv_nl }|
          && |[parent.child]{ lv_nl }|
          && |y = 2{ lv_nl }|
          && |[parent.sibling]{ lv_nl }|
          && |z = 3{ lv_nl }|.
    lo_toml = zcl_toml=>parse( lv_doc ).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lo_toml->get_integer( '/parent/x' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lo_toml->get_integer( '/parent/child/y' ) ).
    cl_abap_unit_assert=>assert_equals( exp = 3
                                        act = lo_toml->get_integer( '/parent/sibling/z' ) ).
  ENDMETHOD.

  METHOD test_multiline_literal_quotes.
    DATA lo_toml TYPE REF TO zcl_toml.
    DATA lv_nl   TYPE string.
    DATA lv_doc  TYPE string.

    lv_nl = cl_abap_char_utilities=>newline.
    lv_doc = |content = '''Here are single ' and double " quotes without escape.'''{ lv_nl }|.
    lo_toml = zcl_toml=>parse( lv_doc ).
    cl_abap_unit_assert=>assert_equals( exp = |Here are single ' and double " quotes without escape.|
                                        act = lo_toml->get_string( '/content' ) ).
  ENDMETHOD.
ENDCLASS.
