## commandeer test file (it doubles as an example file too!)
import commandeer


commandline:
  arguments(expendables, int, false)
  option testing, bool, "testing", "t"  # option is placed here for testing purposes.

if testing:
  doAssert(len(expendables) == 0)
