Commandeer
==========

Take command of your command line.

Commandeer easily deals with getting data from the commandline to variables.
Period. It does this little thing well and it lets **you** deal with the logic.

Usage
-----

```nimrod
commandLine:
  argument number, int
  argument squareIt, bool
  option help, bool, "help", "h"
  option times, int, "times", "t"

echo(number1)
if help:
  echo("usage: program [help] <int> <int> ")
```

See testCommandeer.nim for a bigger example.

That's all. It's not much and it doesn't pretend to be a magical experience.
It should Just Work.

Installation
------------

For now, you can just copy the commandeer.nim file to your project and
import it.

It will eventually be added to Babel.

Design
------

You should be the one in charge of the logic and most things should be
explicit. Command-line parsers can do a lot for you, but I prefer to
be in full control. Keep it simple and streamlined.

TODO and Contribution
---------------------

- Add to Babel package repository
- A nice way to override the default message for missing arguments
- Catch conversion exceptions (maybe?)
- Document some more
