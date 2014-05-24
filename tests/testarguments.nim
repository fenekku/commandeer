## When testing commandeer run it as follows on the command line:
## ./testarguments 2.0 1 1 2 1 a

import unittest

import commandeer

commandLine:
  argument floatNumber, float
  arguments intNumbers, int
  argument character, char
  option testing, bool, "testing", "t"

echo("floatNumber = ", floatNumber)
echo("intNumbers = ", intNumbers)
echo("character = ", character)

if testing:

  check floatNumber == 2.0
  check intNumbers[0] == 1
  check intNumbers[1] == 1
  check intNumbers[2] == 2
  check intNumbers[3] == 1
  check character == 'a'

  echo "Tests Pass"