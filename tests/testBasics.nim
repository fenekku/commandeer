## commandeer test file (it doubles as an example file too!)

import tables
import unittest

import commandeer


proc usage(): string =
  result = "Usage: program [--testing|--int=<int>|--help] <int> <float> <char> <bool> <string>..."

commandline:
  argument integer, int
  argument floatingPoint, float
  argument character, char
  option testing, bool, "testing", "t" #option is placed here for testing purposes.
  argument boolean, bool               #please don't do this for real
  arguments strings, string
  option optionalInteger, int, "int", "i"
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

  #Test all possible argument types
  check integer == 1
  check floatingPoint == 2.0
  check character == '?'
  check strings == @["one", "two", "three"]
  check optionalInteger == 10
  check boolean == false
