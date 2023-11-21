[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://paypal.me/khchen0915?country.x=TW&locale.x=zh_TW)

# Gura Configuration Language for Nim
Gura is a file format for configuration files. Gura is as flexible as YAML and simple and readable like TOML. Its syntax is clear and powerful, yet familiar for YAML/TOML users (from https://github.com/gura-conf/gura).

To learn more about Gura, you can read the [Official Gura Documentation](https://gura.netlify.app/docs/gura).

## Examples
```nim
import gura, json, strutils

const guraString = """
  # This is a comment in a Gura configuration file.
  # Define a variable named `title` with string value "Gura Example"
  title: "Gura Example"

  # Define an object with fields `username` and `age`
  # with string and integer values, respectively
  # Indentation is used to indicate nesting
  person:
    username: "Stephen"
    age: 20

  # Define a list of values
  # Line breaks are OK when inside arrays
  hosts: [
    "alpha",
    "omega"
  ]

  # Variables can be defined and referenced to avoid repetition
  $foreground: "#FFAH84"
  color_scheme:
    editor: $foreground
    ui:     $foreground

""".unindent(2)

# Transforms to json node
let node = fromGura(guraString)

# Access a specific field
echo "Title -> ", node["title"]
echo "My username is ", node["person"]["username"]
for host in node["hosts"]:
  echo "Host -> ", host
```

## Differences from the original Gura
* Indentation can use spaces in multiples of 2 (originally required
  multiples of 4).

* The use of Tab (\t) is not allowed in syntax; it should be replaced
  with spaces.

* Apart from control characters \x00..\x1f and characters used in syntax,
  such as (' ', ':', '$', '[', ']', ',', '"', ''', '#'), any other ASCII
  or UTF-8 characters can be used as key names or variable names.

* Commas separating items in an array are optional regardless of their
  placement (both [1 2 3] and [1, 2, 3,] are acceptable). However,
  a comma after an object always indicates the end of the object definition.

* Strings (basic, literal, multi-line, etc.) from any Gura can be used for
  importing.

* Imports always use the current file location as the current directory
  (similar to Nim import).


## License
Copyright (c) Chen Kai-Hung, Ward. All rights reserved.

## Donate
If this project help you reduce time to develop, you can give me a cup of coffee :)

[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://paypal.me/khchen0915?country.x=TW&locale.x=zh_TW)
