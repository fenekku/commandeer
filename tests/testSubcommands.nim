## commandeer test file (it doubles as an example file too!)

import commandeer

proc usage(): string =
  result = "Usage: testSubCommands [--noop | --version] <COMMAND> [<OPTIONS>]"

commandline:
  subcommand add, "add":
    arguments filenames, string
    option force, bool, "force", "f"
    option interactive, bool, "interactive", "i"
    exitoption "help", "h", "add help"
  subcommand clone, "clone":
    argument gitUrl, string
    exitoption "help", "h", "clone help"
  subcommand clean, "clean":
    option excludePattern, string, "exclude", "e"
    exitoption "help", "h", "clean help"
  option noOperation, bool, "noop", "n"
  option testing, bool, "testing", "t"
  exitoption "version", "v", "version 1.9.1"
  exitoption "help", "h", "general help"
  errormsg usage()


if add:
  echo("add subcommand chosen")
  if not noOperation:
    echo("adding ", filenames)
  else:
    echo("noOperation selected so not adding ", filenames)

  if force:
    echo " with force"
    if interactive:
      echo " and interaction"
  elif interactive:
    echo " with interaction"

elif clone:
  echo "clone subcommand chosen"
  echo "cloning ", gitUrl, "..."

elif clean:
  echo "clean subcommand chosen"

else:
  echo "no subcommands have been chosen"

if testing:
  doAssert(add == true)
  doAssert(filenames == @["foo", "bar", "baz"])
  doAssert(force == true)
  doAssert(interactive == false)
  doAssert(clone == false)
  doAssert(clean == false)

