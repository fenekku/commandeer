Commandeer
==========

[![Build Status](https://circleci.com/gh/fenekku/commandeer/tree/master.png?style=shield&circle-token=7697da2b7caad879ca17ab6ea7acf8729163a06b)](https://circleci.com/gh/fenekku/commandeer)

Take command of your command line.

Commandeer gets data from the command line to your variables and exits
gracefully if there is any issue.

It does this little thing well and lets *you* deal with the rest.


Usage
-----

**In code**

```nim
## myCLApp.nim

import commandeer

commandline:
  argument integer, int
  argument floatingPoint, float
  argument character, char
  arguments strings, string
  option optionalInteger, int, "int", "i", -1
  option testing, bool, "testing", "t"
  exitoption "help", "h",
             "Usage: myCLApp [--testing|--int=<int>|--help] " &
             "<int> <float> <char> <string>..."
  errormsg "You made a mistake!"

echo("integer = ", integer)
echo("floatingPoint = ", floatingPoint)
echo("character = ", character)
echo("strings (one or more) = ", strings)

if optionalInteger != 0:
  echo("optionalInteger = ", optionalInteger)

if testing:
  echo("Testing enabled")

```

**On the command line**

```
$ myCLApp --testing 4 8.0 a one two -i:100
integer = 4
floatingPoint = 8.0
character = a
strings (one or more) = @[one, two]
optionalInteger = 100
Testing enabled
$ myCLApp 10 --help
Usage: myCLApp [--testing|--int=<int>|--help] <int> <float> <char> <string>...
```

When you have commandeer installed, try passing an incorrect set of
command line arguments for fun!

See the `tests` folder for other examples.

It doesn't seek to do too much; it just does what's needed.


Installation
------------

There are 2 ways to install commandeer:

**nimble**

Install [nimble](https://github.com/nim-lang/nimble). Then do:

    $ nimble install commandeer

This will install the latest tagged version of commandeer.

**raw**

Copy the commandeer.nim file to your project and import it.

When I go this way for Nim libraries, I like to create a `libs/`
folder in my project and put third-party files in it. I then add the
line `path = "libs"` to my `nim.cfg` file so that the `libs/`
directory is looked into at compile time.


Documentation
-------------

**commandline**

`commandline` is used to delimit the space where you define the command line
arguments and options you expect. All other commandeer constructs (described below)
are placed under it. They are all optional - although you probably want to use
at least one, right?

**subcommand `identifier`, `name`[, `alias1`, `alias2`...]**

`subcommand` declares `identifier` to be a variable of type `bool` that is `true`
if the first command line argument passed is `name` or one of the aliases (`alias1`, `alias2`, etc.) and is `false` otherwise.
Under it, you define the subcommand arguments and options you expect.
All other commandeer constructs (described below) *can be* placed under it.

For example:

```nim
commandline:
  subcommand add, "add", "a":
    arguments filenames, string
    option force, bool, "force", "f"
  option globalOption, bool, "global", "g"

if add:
  echo "Adding", filenames
if globalOption:
  echo "Global option activated"
```

See `tests/testSubcommands.nim` for a larger example.

**argument `identifier`, `type`**

`argument` declares a variable named `identifier` of type `type` initialized with
the value of the corresponding command line argument converted to type `type`.

Correspondence works as follows: the first occurrence of `argument` corresponds
to the first argument, the second to the second argument and so on. Note that
if a `subcommand` is declared then 1) any top-level occurrence of `argument` is
ignored, 2) the first subcommand `argument` corresponds to the first command line argument
after the subcommand, the second to the second argument after the subcommand and so on.


**arguments `identifier`, `type` [, `atLeast1`]**

`arguments` declares a variable named `identifier` of type `seq[type]` initialized with
the value of the sequential command line arguments that can be converted to type `type`.
By default `atLeast1` is `true` which means there must be at least one argument of type
`type` or else an error is thrown. Passing `false` there allows for 0 or more arguments of the
same type to be stored at `identifier`.

*Warning*: `arguments myListOfStrings, string` will eat all arguments on
the command line. The same applies to other situations where one type is
a supertype of another type in terms of conversion e.g., floats eat ints.


**option `identifier`, `type`, `long name`, `short name` [, `default`]**

`option` declares a variable named `identifier` of type `type` initialized with
the value of the corresponding command line option `--long name` or `-short name`
converted to type `type` if it is present. The `--` and `-` are added
by commandeer for your convenience. If the option is not present,
`identifier` is initialized to its default type value or the passed
`default` value.

The command line option syntax follows Nim's one and adds space (!) i.e.,
`--times=3`, `--times:3`, `-t=3`, `-t:3`, `--times 3` and `-t 3` are all valid.

Syntactic sugar is provided for boolean options such that only the presence of
the option is needed to give a true value.


**exitoption `long name`, `short name`, `exit message`**

`exitoption` declares a long and short option string for which the application
will immediately output `exit message` and exit. This can be used for subcommand specific exit messages too:

```nim
commandline:
  subcommand add, "add":
    arguments filenames, string
    exitoption "help", "h", "add help"
  exitoption "help", "h", "general help"
```

This is mostly used for printing the version or the help message.


**errormsg `custom error message`**

`errormsg` sets a string `custom error message` that will be displayed after the other error messages if the command line arguments or options are invalid.


**Valid types for `type` are:**

- `int`, `float`, `string`, `bool`, `char`


Design
------

- Keep as much logic out of the module and into the hands of
  the developer as possible
- No magical variables should be made implicitly available. All created
  variables should be explicitly chosen by the developer.
- Keep it simple and streamlined. Command line parsers can do a lot for
  you, but I prefer to be in adequate control.
- Test in context. Tests are run on the installed package because that
  is what people get.


Tests
-----

Run the test suite:

    nimble tests

TODO and Contribution
---------------------

- Use and see what needs to be added
