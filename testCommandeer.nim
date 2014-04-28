## commandeer example file (it doubles as a test file too!)
## When testing commandeer run it as follows on the command line:
## ./testCommandeer 2 on --outside -a:2

from strutils import join
import tables

import commandeer


proc usage(): string =
  var options = newSeq[string]()
  options.add("--[a]lpha=a\tAdd <a> to <number>")
  options.add("--[h]elp\tShow this help message")
  options.add("--[o]utside\tIf --alpha option used, add a after squaring")
  options.add("--[t]esting\tTurn on unittests")
  options.add("--[v]ersion\tShow the version number")
  return "Usage: testCommandeer <number> <squareIt> [OPTIONS]\n" &
         join(options, "\n")

commandLine:
  argument number, int
  argument squareIt, bool
  option alpha, int, "alpha", "a"
  option outside, bool, "outside", "o"
  option testing, bool, "testing", "t"

  exitoption "help", "h", usage()
  exitoption "version", "v", "Version 0.1.0"


let s = number + 1
if squareIt:
  if alpha != 0:
    if outside:
      echo("(number + 1)^2 + alpha = ", s*s + alpha)
    else:
      echo("(number + 1 + alpha)^2 = ", (s + alpha)*(s + alpha))
  else:
    echo("(number + 1)^2 = ", s*s)
else:
  echo("number + 1 = ", s)

if testing:
  #Test that tables is not overwritten
  var a = tables.initTable[string, int]()
  a["boo"] = 1
  echo a["boo"]