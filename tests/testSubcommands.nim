## commandeer test file (it doubles as an example file too!)

import commandeer


proc usage(): string =
  result = "Usage: testSubCommands [--noop | --version] <COMMAND> [<OPTIONS>]"

commandline:
  subcommand add, "add":
    arguments filenames, string
    option force, bool, "force", "f"
    option interactive, bool, "interactive", "i"
  subcommand clone, "clone":
    argument gitUrl, string
  subcommand clean, "clean":
    option excludePattern, string, "exclude", "e"
  option noOperation, bool, "noop", "n"
  option testing, bool, "testing", "t"
  exitoption "version", "v", "version 1.9.1"
  errormsg usage()

if add:
  echo("add subcommand chosen")
  if not noOperation:
    echo("adding ", filenames)
  else:
    echo("noOperation selected so not adding ", filenames)

  if force:
    write(stdout, " with force")
    if interactive:
      write(stdout, " and interaction")
      echo ""
  elif interactive:
    write(stdout, " with interaction")

elif clone:
  echo("clone subcommand chosen")
  echo("cloning ", gitUrl, "...")

elif clean:
  echo("clean subcommand chosen")

else:
  echo("no subcommands have been chosen")

if testing:
  doassert(add == true)
  doassert(filenames == @["foo", "bar", "baz"])
  doassert(force == true)
  doassert(interactive == false)
  doassert(clone == false)
  doassert(clean == false)
