## commandeer test file (it doubles as an example file too!)

import commandeer

proc usage(): string =
  result = "Usage: myprog fname kolnum"

commandline:
  argument fname, string
  arguments kolnum, string, false
  exitoption "help", "h", usage()
  errormsg "You made a mistake!"

# echo file
# echo silly
# echo mode
# echo number
# echo rational

# if testing:
#   doAssert(file == "foo.txt")
#   doAssert(mode == 'r')
#   doAssert(number == 1)
#   doAssert(rational == 3.6)
#   doAssert(silly == false)

