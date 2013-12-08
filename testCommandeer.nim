## A simple example of a program using commandeer

import commandeer

proc usage(): string =
  return "Usage: testCommandeer <number> <square it or not> [-h|--times=<other number>]"

commandLine:
  argument number, int
  argument squareIt, bool
  option times, int, "times", "t"

  exitoption "help", "h", usage()
  exitoption "version", "v", "Version 0.1.0"


echo("number + 1 from testCommandeer = ", number + 1)
echo("squareIt = ", squareIt)

if squareIt:
  number = number * number
  echo("number^2 = ", number)

if times != 0:
  number = number * times
  echo("number * ", times, " = ", number)

