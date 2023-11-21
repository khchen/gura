#====================================================================
#
#             Gura Configuration Language for Nim
#              Copyright (c) Chen Kai-Hung, Ward
#
#====================================================================

import gura, json, unittest, os

when true:
  suite "Test Suites for Gura for Nim":

    test "Parse and Stringify":
      putEnv("env_var_value", "very")
      putEnv("env_var_value_multiline", "Roses")

      proc check(file: string, result: string) =
        let node = fromGuraFile(file)
        check $node == result
        check $(node.toGura().fromGura()) == result

      check "testing/correct/array_in_object.ura",
        """{"model":{"columns":[["var1","str"],["var2","str"]]}}"""

      check "testing/correct/array_in_object_trailing_comma.ura",
        """{"model":{"columns":[["var1","str"],["var2","str"]]}}"""

      check "testing/correct/basic_string.ura",
        """{"str":"I'm a string. \"You can quote me\". Na\bme\tJosé\nLocation\tSF.","str_2":"I'm a string. \"You can quote me\". Na\bme\tJosé\nLocation\tSF.","with_var":"Gura is cool","escaped_var":"$name is cool","with_env_var":"Gura is very cool"}"""

      check "testing/correct/bug_trailing_comma.ura",
        """{"foo":[{"bar":{"baz":[{"far":"faz"}]}}],"barbaz":"boo"}"""

      check "testing/correct/empty.ura",
        """{}"""

      check "testing/correct/empty_object.ura",
        """{"empty_object":{}}"""

      check "testing/correct/empty_object_2.ura",
        """{"empty_object":{}}"""

      check "testing/correct/empty_object_3.ura",
        """{"empty_object":{}}"""

      check "testing/correct/escape_sentence.ura",
        """{"foo":"\t\\h\\i\\i"}"""

      check "testing/correct/full.ura",
        """{"a_string":"test string","int1":99,"int2":42,"int3":0,"int4":-17,"int5":1000,"int6":5349221,"int7":5349221,"hex1":3735928559,"hex2":3735928559,"hex3":3735928559,"oct1":342391,"oct2":493,"bin1":214,"flt1":1.0,"flt2":3.1415,"flt3":-0.01,"flt4":5e+22,"flt5":1000000.0,"flt6":-0.02,"flt7":6.626e-34,"flt8":224617.445991228,"sf1":inf,"sf2":inf,"sf3":-inf,"null":null,"empty_single":{},"bool1":true,"bool2":false,"1234":"1234","services":{"nginx":{"host":"127.0.0.1","port":80},"apache":{"virtual_host":"10.10.10.4","port":81}},"integers":[1,2,3],"colors":["red","yellow","green"],"nested_arrays_of_ints":[[1,2],[3,4,5]],"nested_mixed_array":[[1,2],["a","b","c"]],"numbers":[0.1,0.2,0.5,1,2,5],"tango_singers":[{"user1":{"name":"Carlos","surname":"Gardel","year_of_birth":1890}},{"user2":{"name":"Aníbal","surname":"Troilo","year_of_birth":1914}}],"integers2":[1,2,3],"integers3":[1,2],"my_server":{"host":"127.0.0.1","empty_nested":{},"port":8080,"native_auth":true},"gura_is_cool":"Gura is cool"}"""

      check "testing/correct/literal_string.ura",
        """{"winpath":"C:\\Users\\nodejs\\templates","winpath2":"\\\\ServerX\\admin$\\system32\\","quoted":"John \"Dog lover\" Wick","regex":"<\\i\\c*\\s*>","with_var":"$no_parsed variable!","escaped_var":"$name is cool"}"""

      check "testing/correct/multiline_basic_string.ura",
        """{"str":"Roses are red\r\nViolets are blue","str_2":"Roses are red\r\nViolets are blue","str_3":"Roses are red\nViolets are blue","with_var":"Roses are red\r\nViolets are blue","with_env_var":"Roses are red\nViolets are blue","str_with_backslash":"The quick brown fox jumps over the lazy dog.","str_with_backslash_2":"The quick brown fox jumps over the lazy dog.","str_4":"Here are two quotation marks: \"\". Simple enough.","str_5":"Here are three quotation marks: \"\"\".","str_6":"Here are fifteen quotation marks: \"\"\"\"\"\"\"\"\"\"\"\"\"\"\".","escaped_var":"$name is cool"}"""

      check "testing/correct/multiline_literal_string.ura",
        """{"regex2":"I [dw]on't need \\d{2} apples","lines":"The first newline is\r\ntrimmed in raw strings.\r\n   All other whitespace\r\n   is preserved.\r\n","with_var":"$no_parsed variable!","escaped_var":"$name is cool"}"""

      check "testing/correct/nan.ura",
        """{"sf4":nan,"sf5":nan,"sf6":nan}"""

      check "testing/correct/normal.ura",
        """{"integers":[1,2,3],"colors":["red","yellow","green"],"nested_arrays_of_ints":[[1,2],[3,4,5]],"nested_mixed_array":[[1,2],["a","b","c"]],"mixed_with_object":[1,{"test":{"genaro":"Camele"}},2,[4,5,6],3],"numbers":[0.1,0.2,0.5,1,2,5],"tango_singers":[{"user1":{"name":"Carlos","surname":"Gardel","year_of_birth":1890,"testing_nested":{"nested_1":1,"nested_2":2}}},{"user2":{"name":"Aníbal","surname":"Troilo","year_of_birth":1914}}],"integers_with_new_line":[1,2,3],"separator":[{"a":1,"b":2},{"a":1},{"b":2}]}"""

      check "testing/correct/normal_object.ura",
        """{"user1":{"name":"Carlos","surname":"Gardel","testing_nested":{"nested_1":1,"nested_2":2},"year_of_birth":1890},"user2":{"name":"Aníbal","surname":"Troilo","year_of_birth":1914}}"""

      check "testing/correct/normal_variable.ura",
        """{"plain":5,"in_array_middle":[1,5,3],"in_array_last":[1,2,5],"in_object":{"name":"Aníbal","surname":"Troilo","year_of_birth":1914}}"""

      check "testing/correct/object_without_useless_line.ura",
        """{"testing":{"test":{"name":"JWARE","surname":"Solutions"},"test_2":2}}"""

      check "testing/correct/object_with_comments.ura",
        """{"user1":{"name":"Carlos","surname":"Gardel","year_of_birth":1890,"testing_nested":{"nested_1":1,"nested_2":2}},"user2":{"name":"Aníbal","surname":"Troilo","year_of_birth":1914}}"""

      check "testing/correct/unused_var.ura",
        """{}"""

      check "testing/correct/useless_line_in_the_middle.ura",
        """{"a_string":"test string","int1":99,"int2":42,"int3":0,"int4":-17,"int5":1000,"int6":5349221,"int7":5349221}"""

      check "testing/correct/useless_line_in_the_middle_object.ura",
        """{"testing":{"test":{"name":"JWARE","surname":"Solutions"},"test_2":2}}"""

      check "testing/correct/useless_line_in_the_middle_object_complex.ura",
        """{"testing":{"test":{"name":"JWARE","surname":"Solutions","skills":{"good_testing":false,"good_programming":false,"good_english":false}},"test_2":2,"test_3":{"key_1":true,"key_2":false,"key_3":55.99}}}"""

      check "testing/correct/useless_line_on_both.ura",
        """{"a_string":"test string","int1":99,"int2":42,"int3":0,"int4":-17,"int5":1000,"int6":5349221,"int7":5349221}"""

      check "testing/correct/useless_line_on_bottom.ura",
        """{"a_string":"test string","int1":99,"int2":42,"int3":0,"int4":-17,"int5":1000,"int6":5349221,"int7":5349221}"""

      check "testing/correct/useless_line_on_top.ura",
        """{"a_string":"test string","int1":99,"int2":42,"int3":0,"int4":-17,"int5":1000,"int6":5349221,"int7":5349221}"""

      check "testing/correct/without_useless_line.ura",
        """{"a_string":"test string","int1":99,"int2":42,"int3":0,"int4":-17,"int5":1000,"int6":5349221,"int7":5349221}"""

      check "testing/correct/with_comments.ura",
        """{"integers":[1,2,3],"colors":["red","yellow","green"],"nested_arrays_of_ints":[[1,2],[3,4,5]],"nested_mixed_array":[[1,2],["a","b","c"]],"mixed_with_object":[1,{"test":{"genaro":"Camele"}},2,[4,5,6],3],"numbers":[0.1,0.2,0.5,1,2,5],"tango_singers":[{"user1":{"name":"Carlos","surname":"Gardel","year_of_birth":1890,"testing_nested":{"nested_1":1,"nested_2":2}}},{"user2":{"name":"Aníbal","surname":"Troilo","year_of_birth":1914}}],"integers_with_new_line":[1,2,3],"separator":[{"a":1,"b":2},{"a":1},{"b":2}]}"""

      check "testing/correct/importing/normal.ura",
        """{"from_file_three":true,"from_file_one":1,"from_file_two":{"name":"Aníbal","surname":"Troilo","year_of_birth":1914},"from_original_1":[1,2,5],"from_original_2":false}"""

      check "testing/correct/importing/one.ura",
        """{"from_file_three":true,"from_file_one":1}"""

      check "testing/correct/importing/two.ura",
        """{"from_file_two":{"name":"Aníbal","surname":"Troilo","year_of_birth":1914}}"""

      check "testing/correct/importing/three.ura",
        """{"from_file_three":true}"""

      check "testing/correct/importing/with_variable.ura",
        """{"from_file_three":true,"from_file_one":1,"from_file_two":{"name":"Aníbal","surname":"Troilo","year_of_birth":1914},"from_original_1":[1,2,5],"from_original_2":false}"""

    test "Differences from the original Gura":

      proc check(setting: string, result: string) =
        let node = fromGura(setting)
        check $node == result
        check $(node.toGura().fromGura()) == result

      # Indentation can use spaces in multiples of 2
      check "a:\n  b:\n    c:\n  empty", """{"a":{"b":{"c":{}}}}"""

      # UTF-8 characters as  key names or variable names.
      check "$變數: 0\n父:\n  子: $變數", """{"父":{"子":0}}"""

      # Commas separating items in an array are optional
      check "a: [1 2 3 'hello' [] empty]", """{"a":[1,2,3,"hello",[],{}]}"""

    test "Error Handling":
      template expect(Error: type, file: string, n = -1) =
        expect Error:
          try:
            discard fromGuraFile(file)
          except Error as e:
            if n >= 1:
              check e.line == n
            raise e

      expect DuplicatedImportError, "testing/DuplicatedImportError/duplicated_imports_simple.ura", 2
      expect DuplicatedKeyError, "testing/DuplicatedKeyError/duplicated_key.ura", 1
      expect DuplicatedVariableError, "testing/DuplicatedVariableError/duplicated_variable.ura", 1
      expect DuplicatedVariableError, "testing/DuplicatedVariableError/duplicated_variable_1.ura", 2
      expect FileNotFoundError, "testing/FileNotFoundError/file_not_found.ura", 1
      expect GuraParseError, "testing/InvalidIndentationError/different_chars.ura", 3
      expect GuraParseError, "testing/InvalidIndentationError/invalid_object_indentation.ura", 7
      # expect GuraError, "testing/InvalidIndentationError/more_than_4_difference.ura"
      expect InvalidIndentationError, "testing/InvalidIndentationError/not_divisible_by_4.ura", 2
      expect GuraParseError, "testing/InvalidIndentationError/with_tabs.ura", 2
      expect InvalidIndentationError, "testing/ParseError/invalid_import_1.ura", 1
      # expect GuraError, "testing/ParseError/invalid_import_2.ura"
      expect GuraParseError, "testing/ParseError/invalid_object_1.ura", 1
      expect GuraParseError, "testing/ParseError/invalid_object_2.ura", 3
      expect VariableNotDefinedError, "testing/ParseError/invalid_variable_definition_1.ura", 1
      expect VariableNotDefinedError, "testing/ParseError/invalid_variable_definition_2.ura", 1
      expect VariableNotDefinedError, "testing/ParseError/invalid_variable_definition_3.ura", 1
      expect VariableNotDefinedError, "testing/ParseError/invalid_variable_definition_4.ura", 1
      expect VariableNotDefinedError, "testing/ParseError/invalid_variable_with_object.ura", 2
      # expect GuraError, "testing/ParseError/with_dashes.ura"
      # expect GuraError, "testing/ParseError/with_dots.ura"
      expect GuraError, "testing/ParseError/with_quotes.ura", 1
      expect VariableNotDefinedError, "testing/VariableNotDefinedError/variable_not_defined_1.ura", 1
      expect VariableNotDefinedError, "testing/VariableNotDefinedError/variable_not_defined_2.ura", 1
      expect DuplicatedKeyError, "testing/error_reporting/duplicated_key_error_1.ura", 2
      expect DuplicatedKeyError, "testing/error_reporting/duplicated_key_error_2.ura", 3
      expect DuplicatedKeyError, "testing/error_reporting/duplicated_key_error_3.ura", 4
      expect DuplicatedVariableError, "testing/error_reporting/duplicated_variable_error_1.ura", 2
      expect DuplicatedVariableError, "testing/error_reporting/duplicated_variable_error_2.ura", 3
      expect DuplicatedVariableError, "testing/error_reporting/duplicated_variable_error_3.ura", 6
      expect FileNotFoundError, "testing/error_reporting/importing_error_1.ura", 1
      expect FileNotFoundError, "testing/error_reporting/importing_error_2.ura", 4
      expect GuraParseError, "testing/error_reporting/indentation_error_1.ura", 3
      expect InvalidIndentationError, "testing/error_reporting/indentation_error_2.ura", 3
      expect GuraParseError, "testing/error_reporting/indentation_error_3.ura", 3
      # expect GuraError, "testing/error_reporting/indentation_error_4.ura"
      expect VariableNotDefinedError, "testing/error_reporting/missing_variable_error_1.ura", 1
      expect VariableNotDefinedError, "testing/error_reporting/missing_variable_error_2.ura", 2
      expect VariableNotDefinedError, "testing/error_reporting/missing_variable_error_3.ura", 7
      expect VariableNotDefinedError, "testing/error_reporting/missing_variable_error_4.ura", 1
      expect VariableNotDefinedError, "testing/error_reporting/missing_variable_error_5.ura", 1
      expect VariableNotDefinedError, "testing/error_reporting/missing_variable_error_6.ura", 1
      expect GuraParseError, "testing/error_reporting/parsing_error_1.ura", 1
      expect GuraParseError, "testing/error_reporting/parsing_error_2.ura", 1
      expect GuraParseError, "testing/error_reporting/parsing_error_3.ura", 2
      expect GuraParseError, "testing/error_reporting/parsing_error_4.ura", 6
