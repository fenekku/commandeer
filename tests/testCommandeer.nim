## commandeer test file (it doubles as an example file too!)
## When testing commandeer run it as follows on the command line:
## ./testCommandeer 1 2.0 '?' --testing one two three -i:10

import tables
import unittest

import commandeer


proc usage(): string =
  result = "Usage: program [--testing|--int=<int>|--help] <int> <float> <char> <string>..."

commandline:
  argument integer, int
  argument floatingPoint, float
  argument character, char
  arguments strings, string
  option optionalInteger, int, "int", "i"
  option testing, bool, "testing", "t"
  exitoption "help", "h", usage()
  errormsg usage()

echo("integer = ", integer)
echo("floatingPoint = ", floatingPoint)
echo("character = ", character)
echo("strings (one or more) = ", strings)

if optionalInteger != 0:
  echo("optionalInteger = ", optionalInteger)

if testing:
  echo("Testing testCommandeer...")

  #Test that tables is not overwritten
  var a = tables.initTable[string, int]()
  a["boo"] = 1
  check a["boo"] == 1

  check integer == 1
  check floatingPoint == 2.0
  check character == '?'
  check strings == @["one", "two", "three"]
  check optionalInteger == 10

  echo "Tests pass!"
