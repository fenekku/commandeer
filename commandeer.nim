
import parseopt2
import strutils
import strtabs


var
  argumentList = newSeq[string]()
  shortOptions = newStringTable(modeCaseSensitive)
  longOptions = newStringTable(modeCaseSensitive)
  argumentIndex = 0
  errorMsgs : seq[string] = @[]
  customErrorMsg : string
  inSubcommand = false
  subcommandSelected = false


## String conversion
proc convert(s : string, t : char): char =
  result = s[0]
proc convert(s : string, t : int): int =
  result = parseInt(s)
proc convert(s : string, t : float): float =
  result = parseFloat(s)
proc convert(s : string, t : bool): bool =
  ## will accept "yes", "true" as true values
  if s == "":
    ## the only way we get an empty string here is because of a key
    ## with no value, in which case the presence of the key is enough
    ## to return true
    result = true
  else:
    result = parseBool(s)
proc convert(s : string, t : string): string =
    result = s.strip


template argumentIMPL(identifier : untyped, t : typeDesc): untyped =

  var identifier : t

  if (inSubcommand and subcommandSelected) or not inSubcommand:
    if len(argumentList) <= argumentIndex:
      let eMsg = "Missing command line arguments"
      if len(errorMsgs) == 0:
        errorMsgs.add(eMsg)
      else:
        if not (errorMsgs[high(errorMsgs)][0] == 'M'):
          errorMsgs.add(eMsg)
    else:
      var typeVar : t
      try:
        identifier = convert(argumentList[argumentIndex], typeVar)
      except ValueError:
        let eMsg = capitalize(getCurrentExceptionMsg()) &
                   " for argument " & $(argumentIndex+1)
        errorMsgs.add(eMsg)

    inc(argumentIndex)


template argumentsIMPL(identifier : untyped, t : typeDesc, atLeast1 : bool): untyped =

  var identifier = newSeq[t]()

  if (inSubcommand and subcommandSelected) or not inSubcommand:
    if len(argumentList) <= argumentIndex:
      if atLeast1:
        let eMsg = "Missing command line arguments"
        if len(errorMsgs) == 0:
          errorMsgs.add(eMsg)
        else:
          if not (errorMsgs[high(errorMsgs)][0] == 'M'):
            errorMsgs.add(eMsg)
      else:
        discard
    else:
      var typeVar : t
      var firstError = true
      while true:
        if len(argumentList) == argumentIndex:
          break
        try:
          let argument = argumentList[argumentIndex]
          inc(argumentIndex)
          identifier.add(convert(argument, typeVar))
          firstError = false
        except ValueError:
          if atLeast1 and firstError:
            let eMsg = capitalize(getCurrentExceptionMsg()) &
                       " for argument " & $(argumentIndex+1)
            errorMsgs.add(eMsg)
          break


template optionDefaultIMPL(identifier : untyped, t : typeDesc, longName : string,
                           shortName : string, default : t): untyped =

  var identifier : t

  if (inSubcommand and subcommandSelected) or not inSubcommand:
    var typeVar : t
    if strtabs.hasKey(longOptions, longName):
      try:
        identifier = convert(longOptions[longName], typeVar)
      except ValueError:
        let eMsg = capitalize(getCurrentExceptionMsg()) &
                   " for option --" & longName
        errorMsgs.add(eMsg)
    elif strtabs.hasKey(shortOptions, shortName):
      try:
        identifier = convert(shortOptions[shortName], typeVar)
      except ValueError:
        let eMsg = capitalize(getCurrentExceptionMsg()) &
                   " for option -" & shortName
        errorMsgs.add(eMsg)
    else:
      #default values
      identifier = default


template optionIMPL(identifier : untyped, t : typeDesc, longName : string,
                    shortName : string): untyped =

  var identifier : t

  if (inSubcommand and subcommandSelected) or not inSubcommand:
    var typeVar : t
    if strtabs.hasKey(longOptions, longName):
      try:
        identifier = convert(longOptions[longName], typeVar)
      except ValueError:
        let eMsg = capitalize(getCurrentExceptionMsg()) &
                   " for option --" & longName
        errorMsgs.add(eMsg)
    elif strtabs.hasKey(shortOptions, shortName):
      try:
        identifier = convert(shortOptions[shortName], typeVar)
      except ValueError:
        let eMsg = capitalize(getCurrentExceptionMsg()) &
                   " for option -" & shortName
        errorMsgs.add(eMsg)

template exitoptionIMPL(longName, shortName, msg : string): untyped =

  if (inSubcommand and subcommandSelected) or not inSubcommand:
    if strtabs.hasKey(longOptions, longName):
      quit msg, QuitSuccess
    elif strtabs.hasKey(shortOptions, shortName):
      quit msg, QuitSuccess


template errormsgIMPL(msg : string): untyped =

  if (inSubcommand and subcommandSelected) or not inSubcommand:
    customErrorMsg = msg


template subcommandIMPL(identifier : untyped, subcommandName : string, stmts : untyped): untyped =

  var identifier : bool = false
  inSubcommand = true

  if len(argumentList) > 0 and argumentList[0] == subcommandName:
    identifier = true
    inc(argumentIndex)
    subcommandSelected = true

  stmts

  subcommandSelected = false
  inSubcommand = false


template commandline*(statements : untyped): untyped =

  template argument(identifier : untyped, t : typeDesc): untyped =
    argumentIMPL(identifier, t)

  template arguments(identifier : untyped, t : typeDesc, atLeast1 : bool = true): untyped =
    argumentsIMPL(identifier, t, atLeast1)

  template option(identifier : untyped, t : typeDesc, longName : string,
                  shortName : string, default : untyped): untyped =
    optionDefaultIMPL(identifier, t, longName, shortName, default)

  template option(identifier : untyped, t : typeDesc, longName : string,
                  shortName : string): untyped =
    optionIMPL(identifier, t, longName, shortName)

  template exitoption(longName, shortName, msg : string): untyped =
    exitoptionIMPL(longName, shortName, msg)

  template errormsg(msg : string): untyped =
    errormsgIMPL(msg)

  template subcommand(identifier : untyped, subcommandName : string, stmts : untyped): untyped =
    subcommandIMPL(identifier, subcommandName, stmts)

  for kind, key, value in parseopt2.getopt():
    case kind
    of parseopt2.cmdArgument:
      argumentList.add(key)
    of parseopt2.cmdLongOption:
      longOptions[key] = value
    of parseopt2.cmdShortOption:
      shortOptions[key] = value
    else:
      discard

  #Call the passed statements so that the above templates are called
  statements

  if len(errorMsgs) > 0:
    if not customErrorMsg.isNil:
      errorMsgs.add(customErrorMsg)
    quit join(errorMsgs, "\n")


when isMainModule:
  import unittest

  test "convert() returns converted type value from strings":
    var intVar : int
    var floatVar : float
    var boolVar : bool
    var stringVar : string
    var charVar : char

    check convert("10", intVar) == 10
    check convert("10.0", floatVar) == 10
    check convert("10", floatVar) == 10
    check convert("yes", boolVar) == true
    check convert("false", boolVar) == false
    check convert("no ", stringVar) == "no"
    check convert("*", charVar) == '*'
