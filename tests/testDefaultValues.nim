## commandeer test file (it doubles as an example file too!)

import commandeer

proc usage(): string =
  result = "Usage: testSubCommands [--noop | --version] <COMMAND> [<OPTIONS>]"

commandline:
  option file, string, "file", "f", "foo.txt"
  option silly, bool, "silly", "s", true
  option mode, char, "mode", "m", 'r'
  option number, int, "number", "n", 1
  option rational, float, "rational", "r", 3.6
  option testing, bool, "testing", "t"

echo file
echo silly
echo mode
echo number
echo rational

if testing:
  doAssert(file == "foo.txt")
  doAssert(mode == 'r')
  doAssert(number == 1)
  doAssert(rational == 3.6)
  doAssert(silly == false)

