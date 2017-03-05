## commandeer test file (it doubles as an example file too!)

import commandeer

proc usage(): string =
  result = """
    Usage: testDefaultValues [--file | -f] [--silly | -s] [--mode | -m]
                             [--number | -n] [--rational | -r] [--testing | -t]
  """

commandline:
  option(file, string, "file", "f", default="foo.txt")
  option silly, bool, "silly", "s", true
  option(mode, char, "mode", "m", default='r')
  option(number, int, short="n", long="number", default=1)
  option(rational, float, "rational", "r", default=3.6)
  option testing, bool, "testing", "t"

echo "file ", file
echo "silly ", silly
echo "mode ", mode
echo "number ", number
echo "rational ", rational

if testing:
  doAssert(file == "foo.txt")
  doAssert(mode == 'r')
  doAssert(number == 1)
  doAssert(rational == 3.6)
  doAssert(silly == false)
