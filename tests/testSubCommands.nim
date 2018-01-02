## commandeer test file (it doubles as an example file too!)

import commandeer


proc usage(): string =
  result = "Usage: testSubCommands [--noop | --version] <COMMAND> [<OPTIONS>]"

commandline:
  subcommand add, "add", "a":
    arguments filenames, string
    option force, bool, "force", "f"
    option interactive, bool, "interactive", "i"
    exitoption "help", "h", "add help"
  subcommand clone, "clone":
    argument gitUrl, string
    exitoption "help", "h", "clone help"
  subcommand push, ["push", "p","theoppositeofpull"]:
    exitoption "help", "h", "push help"
  option testing, bool, "testing", "t"
  exitoption "help", "h", "general help"
  errormsg usage()


if add:
  echo("adding ", filenames)

  if force:
    echo " with force"
    if interactive:
      echo " and interaction"
  elif interactive:
    echo " with interaction"

elif clone:
  echo "clone subcommand chosen"
  echo "cloning ", gitUrl, "..."

elif push:
  echo "push subcommand chosen"
  echo "pushin ..."

else:
  echo "no subcommands have been chosen"

if testing:
  if add:
    doAssert(filenames == @["clone", "bar", "baz"])
    doAssert(force == true)
    doAssert(interactive == false)
    doAssert(clone == false)
  else:
    doAssert(push == true)

else:
  doAssert(false)
