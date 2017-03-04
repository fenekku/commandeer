## commandeer test file (it doubles as an example file too!)
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
  exitoption "version", "v", "1.0.0"
  errormsg usage()

echo("integer = ", integer)
echo("floatingPoint = ", floatingPoint)
echo("character = ", character)
echo("strings (one or more) = ", strings)

if optionalInteger != 0:
  echo "optionalInteger = ", optionalInteger

if testing:
  #Test all possible argument types
  #use doAssert b/c of bug in unittest
  doAssert(integer == 1)
  doAssert(floatingPoint == 2.0)
  doAssert(character == '?')
  doAssert(strings == @["one", "two", "three"])
  doAssert(optionalInteger == 10)
  doAssert(boolean == false)
