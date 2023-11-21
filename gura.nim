#====================================================================
#
#             Gura Configuration Language for Nim
#              Copyright (c) Chen Kai-Hung, Ward
#
#====================================================================

##[
  Gura is a file format for configuration files. Gura is as flexible as
  YAML and simple and readable like TOML. Its syntax is clear and powerful,
  yet familiar for YAML/TOML users (from https://github.com/gura-conf/gura).

  This Gura implementation in Nim emphasizes code that is easy to write
  and read (NPeg is used in both lexing and parsing), rather than optimizing
  for execution speed. The differences from the original Gura are as follows:

    1. Indentation can use spaces in multiples of 2 (originally required
       multiples of 4).

    2. The use of Tab (\t) is not allowed in syntax; it should be replaced
       with spaces.

    3. Apart from control characters \x00..\x1f and characters used in syntax,
       such as (' ', ':', '$', '[', ']', ',', '"', ''', '#'), any other ASCII
       or UTF-8 characters can be used as key names or variable names.

    4. Commas separating items in an array are optional regardless of their
       placement (both [1 2 3] and [1, 2, 3,] are acceptable). However,
       a comma after an object always indicates the end of the object definition.

    5. Strings (basic, literal, multi-line, etc.) from any Gura can be used for
       importing.

    6. Imports always use the current file location as the current directory
       (similar to Nim import).
]##


import std/[unicode, strutils, json, tables, os, strformat]
import npeg, npeg/lib/utf8

type
  GuraError* = object of CatchableError
    line*: int
    filename*: string

  GuraParseError* = object of GuraError
  DuplicatedKeyError* = object of GuraError
  DuplicatedVariableError* = object of GuraError
  DuplicatedImportError* = object of GuraError
  VariableNotDefinedError* = object of GuraError
  InvalidIndentationError* = object of GuraError
  FileNotFoundError* = object of GuraError

  GuraTokenKind = enum
    gtKey, gtArrayOpen, gtArrayClose, gtIndent, gtUndent, gtValue

  GuraErrorInfo = object
    line: int
    filename: string

  GuraToken = object
    kind: GuraTokenKind
    node: JsonNode
    info: GuraErrorInfo

  GuraState = object
    depths: seq[seq[int]]
    tokens: seq[GuraToken]
    variables: TableRef[string, GuraToken]
    importFiles: TableRef[string, bool]
    info: GuraErrorInfo

# Npeg uses `==` to check if a subject matches a literal
proc `==`(n: GuraToken, t: GuraTokenKind): bool = n.kind == t

proc initGuraState(filename = "",
    variables = newTable[string, GuraToken](),
    importFiles = newTable[string, bool]()): GuraState =

  result.depths = @[@[-1]]
  result.tokens = @[]
  result.variables = variables
  result.importFiles = importFiles
  result.info.filename = filename
  result.info.line = 0

proc newGuraError(typ: typedesc, info: GuraErrorInfo, ext = ""): ref GuraError =
  var msg = "Line " & $info.line
  if info.filename != "": msg.add " (in " & info.filename
  if ext != "": msg.add ", " & ext
  msg.add ")"
  result = newException(typ, msg)
  result.line = info.line
  result.filename = info.filename

proc lex(state: var GuraState, input: string) =

  let lexer = peg(gura, st: GuraState):
    ws <- *' '
    newline <- "\n" | "\r\n"
    # key_chars <- {'A'..'Z','a'..'z','0'..'9', '-', '_'}
    key_chars <- utf8.any - {'\x00'..'\x1f', ' ', ':', '$', '[', ']', ',', '"', '\'', '#'}
    comment <- '#' * *(utf8.any - newline)

    gura <- *token * ?newline * !1

    token <- indent | import_indent | ignored_indent | imports | variable_def | key | value | array_symbols |
      empty_line | comment

    empty_line <- ?comment * newline * ws * ?comment * &newline:
      st.info.line.inc

    import_indent <- newline * >ws * &"import":
      st.info.line.inc
      if $1 != "": # don't allow spaces before import
        raise newGuraError(InvalidIndentationError, st.info)

    ignored_indent <- newline * ws * &(utf8.any - {' ', '#', '\r', '\n'}):
      st.info.line.inc

    indent <- newline * >ws * &(+key_chars * ':'):
      st.info.line.inc
      let depth = len($1)
      if depth mod 2 != 0:
        raise newGuraError(InvalidIndentationError, st.info)

      if depth == st.depths[^1][^1]:
        discard

      elif depth > st.depths[^1][^1]:
        st.tokens.add GuraToken(kind: gtIndent, info: st.info)
        st.depths[^1].add depth

      else:
        while depth < st.depths[^1][^1]:
          discard st.depths[^1].pop
          st.tokens.add GuraToken(kind: gtUndent, info: st.info)

        if depth != st.depths[^1][^1]:
          raise newGuraError(InvalidIndentationError, st.info)

    imports <- "import" * +' ' * (string | variable) * ws:
      let file = st.tokens.pop
      let filename = file.node.getStr()
      let fullname = absolutePath(filename)

      if fullname in st.importFiles:
        raise newGuraError(DuplicatedImportError, st.info)
      st.importFiles[fullname] = true

      var state = initGuraState(filename, st.variables, st.importFiles)
      try:
        let (dir, _, _) = splitFile(fullname)
        let current = getCurrentDir()
        setCurrentDir(dir)
        defer:
          setCurrentDir(current)

        state.lex(readfile(fullname))

      except IOError, OSError:
        raise newGuraError(FileNotFoundError, st.info)

      if state.tokens.len != 0:
        if state.tokens[0].kind != gtIndent or state.tokens[^1].kind != gtUndent:
          raise newGuraError(GuraParseError, state.tokens[^1].info)

        st.tokens.add state.tokens[1..^2]

    variable_def <- variable_new | variable_copy

    variable_new <- '$' * >(+key_chars) * ':' * ws * (float | integer | string) * ws:
      if $1 in st.variables:
        raise newGuraError(DuplicatedVariableError, st.info)
      else:
        st.variables[$1] = st.tokens.pop

    variable_copy <- '$' * >(+key_chars) * ':' * ws * '$' * >(+key_chars) * ws:
      if $1 in st.variables:
        raise newGuraError(DuplicatedVariableError, st.info)
      elif $2 notin st.variables:
        raise newGuraError(VariableNotDefinedError, st.info)
      else:
        st.variables[$1] = GuraToken(kind: gtValue, node: st.variables[$2].node.copy,
          info: st.info)

    key <- >(+key_chars) * ':' * ws:
      let key = $1
      st.tokens.add GuraToken(kind: gtKey, node: newJString(key), info: st.info)

    array_symbols <- >{'[', ']', ','} * ws:
      case $1
      of "[":
        st.tokens.add GuraToken(kind: gtArrayOpen, info: st.info)
        # start a new depths stack for array
        st.depths.add @[-1]

      of "]":
        # undent all till array start
        while st.depths[^1].len > 1:
          discard st.depths[^1].pop
          st.tokens.add GuraToken(kind: gtUndent, info: st.info)

        # drop the depths stack for this array
        if st.depths.len > 1:
          discard st.depths.pop
        else:
          raise newGuraError(GuraParseError, st.info)

        st.tokens.add GuraToken(kind: gtArrayClose, info: st.info)

      of ",":
        # start a new value also means undent all till array start
        while st.depths[^1].len > 1:
          discard st.depths[^1].pop
          st.tokens.add GuraToken(kind: gtUndent, info: st.info)

      else: discard

    value <- (null | true | false | empty | float | integer | string | variable) * ws

    null <- "null":
      st.tokens.add GuraToken(kind: gtValue, node: newJNull(), info: st.info)

    true <- "true":
      st.tokens.add GuraToken(kind: gtValue, node: newJBool(true), info: st.info)

    false <- "false":
      st.tokens.add GuraToken(kind: gtValue, node: newJBool(false), info: st.info)

    empty <- "empty":
      st.tokens.add GuraToken(kind: gtValue, node: newJObject(), info: st.info)

    integer <- hex_int | oct_int | bin_int | dec_int

    dec_int <- ?{'+', '-'} * {'0'..'9'} * *{'0'..'9', '_'}:
      try:
        st.tokens.add GuraToken(kind: gtValue, node: newJInt(parseBiggestInt($0)), info: st.info)
      except ValueError as e:
        raise newGuraError(GuraParseError, st.info, e.msg)

    hex_int <- "0x" * {'0'..'9', 'A'..'F', 'a'..'f'} * *{'0'..'9', 'A'..'F', 'a'..'f', '_'}:
      try:
        st.tokens.add GuraToken(kind: gtValue, node: newJInt(parseHexInt($0)), info: st.info)
      except ValueError as e:
        raise newGuraError(GuraParseError, st.info, e.msg)

    oct_int <- "0o" * {'0'..'7'} * *{'0'..'7', '_'}:
      try:
        st.tokens.add GuraToken(kind: gtValue, node: newJInt(parseOctInt($0)), info: st.info)
      except ValueError as e:
        raise newGuraError(GuraParseError, st.info, e.msg)

    bin_int <- "0b" * {'0', '1'} * *{'0', '1', '_'}:
      try:
        st.tokens.add GuraToken(kind: gtValue, node: newJInt(parseBinInt($0)), info: st.info)
      except ValueError as e:
        raise newGuraError(GuraParseError, st.info, e.msg)

    float <- float_int_part * (exp | frac * ?exp) | ?{'+', '-'} * ("inf" | "nan"):
      try:
        st.tokens.add GuraToken(kind: gtValue, node: newJFloat(parseFloat($0)), info: st.info)
      except ValueError as e:
        raise newGuraError(GuraParseError, st.info, e.msg)

    float_int_part <- ?{'+', '-'} * {'0'..'9'} * *{'0'..'9', '_'}
    frac <- '.' * {'0'..'9'} * *{'0'..'9', '_'}
    exp <- i"e" * ?{'+', '-'} * {'0'..'9'} * *{'0'..'9', '_'}

    string <- ml_basic_string | ml_literal_string | basic_string | literal_string:
      st.tokens.add GuraToken(kind: gtValue, node: newJString($1), info: st.info)

    basic_string <- '"' * *basic_char * '"':
      var str = newStringOfCap(capture.len)
      for i in 1 ..< capture.len:
        str.add capture[i].s
      push str

    basic_char <- escaped | escaped_unicode | interpolation | >(utf8.any - '"')
    escaped <- '\\' * >{'"', '\\', 'b', 'f', 'n', 'r', 't', '$'}:
      case $1
      of "\"": push "\""
      of "\\": push "\\"
      of "b": push "\b"
      of "f": push "\f"
      of "n": push "\n"
      of "r": push "\r"
      of "t": push "\t"
      of "$": push "$"
      else: doAssert(false, "unreachable")

    interpolation <- '$' * >(+key_chars) * &(utf8.any - key_chars):
      if $1 in st.variables:
        let node = st.variables[$1].node.copy()
        case node.kind
        of JString:
          push node.str
        else:
          push $node
      elif existsEnv($1):
        push getEnv($1)
      else:
        raise newGuraError(VariableNotDefinedError, st.info)

    escaped_unicode <- ("\\u" * >Xdigit[4]) | ("\\U" * >Xdigit[8]):
      push $Rune(parseHexInt($1))

    literal_string <- '\'' * >*(utf8.any - '\'') * '\''

    ml_basic_string <- "\"\"\"" * ?newline * *ml_basic_body * "\"\"\"":
      var str = newStringOfCap(capture.len)
      for i in 1 ..< capture.len:
        str.add capture[i].s
      push str
      st.info.line.inc(count($0, '\n'))

    ml_basic_body <- escaped | escaped_unicode | interpolation | mlb_escaped_nl | >(utf8.any - "\"\"\"")
    mlb_escaped_nl <- '\\' * ws * newline * *(' ' | newline)

    ml_literal_string <- "'''" * ?newline * >*(utf8.any - "'''") * "'''":
      push $1
      st.info.line.inc(count($0, '\n'))

    variable <- '$' * >(+key_chars) * &(utf8.any - key_chars):
      if $1 in st.variables:
        let node = st.variables[$1].node.copy()
        st.tokens.add GuraToken(kind: gtValue, node: node, info: st.info)
      elif existsEnv($1):
        st.tokens.add GuraToken(kind: gtValue, node: newJString(getEnv($1)), info: st.info)
      else:
        raise newGuraError(VariableNotDefinedError, st.info)

  # always assume indent start from 0
  # also means the whole gura should be a object
  state.depths[^1].add 0
  state.tokens.add GuraToken(kind: gtIndent,
    info: GuraErrorInfo(line: 1, filename: state.info.filename))

  if not lexer.match("\n" & input & "\n", state).ok:
    raise newGuraError(GuraParseError, state.info)

  while state.depths[^1].len > 1:
    discard state.depths[^1].pop
    state.tokens.add GuraToken(kind: gtUndent)

proc parse(state: var GuraState): JsonNode =

  let parser = peg(gura, GuraToken, ret: JsonNode):
    gura <- obj * !1:
      ret = ($1).node

    obj <- [gtIndent] * *key_val * [gtUndent]:
      var obj = newJObject()
      var i = 1
      while i < capture.len:
        let key = (capture[i].s).node.str
        let val = (capture[i+1].s).node
        if key in obj:
          raise newGuraError(DuplicatedKeyError, capture[i].s.info)

        obj[key] = val
        i.inc(2)

      push GuraToken(kind: gtValue, node: obj)

    key_val <- >[gtKey] * value:
      push $1
      push $2

    array <- [gtArrayOpen] * *value * [gtArrayClose]:
      var arr = newJArray()
      for i in 1 ..< capture.len:
        let val = (capture[i].s).node
        arr.add val

      push GuraToken(kind: gtValue, node: arr)

    value <- [gtValue] | obj | array:
      let token = $0
      if token.kind == gtValue:
        push token

      else:
        # $1 is object or array here
        push $1

  let match = parser.match(state.tokens, result)
  if not match.ok:
    if state.tokens.len > match.matchMax:
      let errorToken = state.tokens[match.matchMax]
      case errorToken.kind:
      of gtIndent:
        raise newGuraError(GuraParseError, errorToken.info)
      of gtUndent:
        raise newGuraError(GuraParseError, state.tokens[match.matchMax-1].info)
      else:
        raise newGuraError(GuraParseError, errorToken.info)
    else:
      raise newGuraError(GuraParseError, state.tokens[match.matchLen].info)

proc toGura(node: JsonNode, output: var string, indent: int, count = 4) =
  var indent = indent
  case node.kind
  of JInt, JFloat, JBool, JNull:
    output.add fmt"{node}"

  of JString:
    let isLiteral = patt *(utf8.any - {'\x00'..'\x1f', '\''}) * !1
    if isLiteral.match(node.str).ok:
      output.add fmt"'{node.str}'"
    else:
      output.add $node

  of JArray:
    output.add "["
    for i in 0..<node.len:
      let val = node[i]
      if val.kind == JObject:
        toGura(val, output, indent + count, count)
      else:
        toGura(val, output, indent, count)

      if i < node.len - 1:
        output.add ", "

      if val.kind == JObject and val.len != 0:
        output.add "\n" & spaces(indent + count)

    # for val in node:
    output.add "]"

  of JObject:
    if node.len == 0:
      output.add "empty"

    else:
      for key, val in node:
        if output.len != 0: output.add "\n"
        output.add fmt"{spaces(indent)}{key}: "
        if val.kind == JObject:
          toGura(val, output, indent + count, count)
        else:
          toGura(val, output, indent, count)

proc fromGura*(input: string): JsonNode =
  ## Transforms a Gura string into a JsonNode.
  var state = initGuraState()
  state.lex(input)
  return state.parse()

proc toGura*(node: JsonNode, indent: Positive = 4): string =
  ## Transforms a JsonNode into Gura string.
  if node.kind != JObject:
    raise newException(GuraError, "not an object")

  if node.len == 0:
    return ""

  toGura(node, result, 0, indent)

proc fromGuraFile*(path: string): JsonNode =
  ## Transforms a Gura file into a JsonNode.
  let fullname = expandFilename(path)
  return fromGura("import " & escapeJson(fullname))

proc toGuraFile*(node: JsonNode, path: string, indent: Positive = 4) =
  ## Transforms a JsonNode into Gura file.
  writeFile(path, node.toGura(indent))

when isMainModule:

  const guraString = """
    title: "Gura Example"

    person:
      username: "Stephen"
      age: 20

    hosts: [
      "alpha",
      "omega"
    ]
  """.unindent(4)

  # Transforms to json node
  let node = fromGura(guraString)

  # Access a specific field
  echo "Title -> ", node["title"]
  echo "My username is ", node["person"]["username"]
  for host in node["hosts"]:
    echo "Host -> ", host
