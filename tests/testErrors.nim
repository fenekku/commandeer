## commandeer test file (it doubles as an example file too!)

import commandeer


commandline:
  arguments numbers, int
  option fraction, float, "fraction", "f"
  option testing, bool, "testing", "t"
  errormsg "Usage: <numbers: int...> [--fraction|-f: float] [--testing]"

echo "numbers ", numbers
echo "fraction ", fraction
echo "testing ", testing

# if testing:
#   doAssert(file == "foo.txt")
#   doAssert(mode == 'r')
#   doAssert(number == 1)
#   doAssert(rational == 3.6)
#   doAssert(silly == false)

# nothing on the commandline: Missing command line arguments\nUsage...
# 1.0: Couldn't convert '1.0' to int
#