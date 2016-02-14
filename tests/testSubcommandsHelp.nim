## commandeer test file (it doubles as an example file too!)

import commandeer

proc usage(): string =
  result = "Usage: testSubCommandsHelp [--help|--testing|--version] <COMMAND> [<COMMAND OPTIONS>]"

commandline:
  subcommand add, "add":
    arguments filenames, string
    option force, bool, "force", "f"
    exitoption "help", "h", "add help"
  subcommand clone, "clone":
    argument gitUrl, string
    exitoption "help", "h", "clone help"
  subcommand clean, "clean":
    exitoption "help", "h", "clean help"
  option testing, bool, "testing", "t"
  exitoption "version", "v", "version 1.9.1"
  exitoption "help", "h", usage()
  errormsg usage()


if add:
  echo "add subcommand chosen"
  write(stdout, "adding", filenames)

  if force:
    write(stdout, " with force")

elif clone:
  echo "clone subcommand chosen"
  echo "cloning ", gitUrl, "..."

elif clean:
  echo "clean subcommand chosen"

else:
  echo "no subcommands have been chosen"
