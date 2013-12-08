Commandeer
==========

Take command of your command line.

Commandeer easily deals with getting data from the command line to variables.
Period. It does this little thing well and it lets *you* deal with the rest.


Usage
-----

**In code**

```nimrod
## myCLApp.nim

import commandeer

commandLine:
  argument number, int
  argument squareIt, bool
  option times, int, "times", "t"
  exitoption "help", "h", "Usage: program [--help|--times=<int>] <int> <bool>"

echo("Number = ", number)

if squareIt:
  number = number*number
  echo("Squared = ", number)

if times != 0:
  echo("Times ", times, " = ", number*times)

```

**On the command line**

```
$ myCLApp 3 yes --times=5
Number = 3
Squared = 9
Times 5 = 45
$ myCLApp 3 yes --times=5 --help
Usage: program [--help|--times=<int>] <int> <bool>
```

See testCommandeer.nim for a bigger example.

That's all. It's not much and it doesn't pretend to be a magical experience.
Although it would be much cooler if it was. It should Just Work.


Installation
------------

For now, you can just copy the commandeer.nim file to your project and
import it.

It will eventually be added to Babel.


Documentation
-------------

**commandLine**

`commandLine` is used to delimit the space where you define the command line
arguments you expect. All other commandeer constructs are to be placed under it.

**argument `identifier` `type`**

It declares a variable named `identifier` of type `type` initialized with
the appropriately converted value of the corresponding command line argument.
The first occurrence of `argument` corresponds to the first argument, the second
to the second argument and so on.

**option `identifier` `type` `long option` `short option`**

It declares a variable named `identifier` of type `type` initialized with
the appropriately converted value of the corresponding command line option
if it is present. Otherwise `identifier` is initialized to its default value.

Command line option syntax follows Nimrod's one e.g., `--times=3`, `-t=3`, `-t:3` and `--times:3` are all valid.

**exitoption `long option` `short option` `exit message`**

It declares a long and short option pattern for which the application
will immediately output `exit message` and exit.

This is mostly used for printing the version or the help message.


Design
------

This formulation of command line arguments correspondence was formulated
following some design principles.

- Keep as much logic out of the module as possible and into the hands of
  the developer
- No magical variables should be made implicitly available. All created
  variables should be explicitly chosen by the developer.
- Command line parsers can do a lot for you, but I prefer to
  be in full control. Keep it simple and streamlined.

TODO and Contribution
---------------------

- Add to Babel package repository
- Default values