## A simple example of a program using commandeer

import commandeer

commandLine:
  argument number, int
  argument squareIt, bool
  option help, bool, "help", "h"
  option times, int, "times", "t"

if help:
  echo "Usage: testCommandeer <number> <square it or not> [-h|--times=<other number>]"

echo("number + 1 from testCommandeer = ", number + 1)
echo("squareIt = ", squareIt)

if squareIt:
  number = number * number
  echo("number^2 = ", number)

if times != 0:
  number = number * times
  echo("number * ", times, " = ", number)

