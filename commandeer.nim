
import parseopt
import strutils
import tables


var
  arguments = newSeq[ string ]()
  shortOptions = initTable[string, string](32)
  longOptions = initTable[string, string](32)
  argumentIndex = 0
  error : ref E_Base

## String conversion
proc convert(s : string, ofType : char): char =
  result = s[0]
proc convert(s : string, ofType : int): int =
  result = parseInt(s)
proc convert(s : string, ofType : float): float =
  result = parseFloat(s)
proc convert(s : string, ofType : bool): bool =
  ## will accept "yes", "true" as true values
  if s == "":
    ## the only way we get an empty string here is because of a key
    ## with no value, in which case the presence of the key is enough
    ## to return true
    result = true
  else:
    result = parseBool(s)
proc convert(s : string, ofType : string): string =
    result = s.strip


template argument*(identifier : expr, ofType : expr): stmt {.immediate.} =
  bind arguments
  bind argumentIndex
  bind convert
  bind error

  var identifier : ofType

  if arguments.len <= argumentIndex:
    error = newException(E_Base, "Not enough command-line arguments")
  else:
    var typeVar : ofType
    try:
      identifier = convert(arguments[argumentIndex], typeVar)
      inc(argumentIndex)
    except EInvalidValue:
      error = getCurrentException()


template option*(identifier : expr, ofType : expr, longName : string,
                 shortName : string): stmt {.immediate.} =
  bind shortOptions
  bind longOptions
  bind convert
  bind error
  bind tables

  var identifier : ofType

  block:
    var typeVar : ofType
    if tables.hasKey(longOptions, longName):
      try:
        identifier = convert(tables.mget(longOptions, longName), typeVar)
      except EInvalidValue:
        error = getCurrentException()
    elif tables.hasKey(shortOptions, shortName):
      try:
        identifier = convert(tables.mget(shortOptions, shortName), typeVar)
      except EInvalidValue:
        error = getCurrentException()


template exitoption*(longName, shortName, msg : string): stmt =
  bind shortOptions
  bind longOptions
  bind tables

  if tables.hasKey(longOptions, longName):
    quit msg
  elif tables.hasKey(shortOptions,  shortName):
    quit msg


template commandLine*(statements : stmt): stmt {.immediate.} =
  bind arguments
  bind shortOptions
  bind longOptions
  bind error
  bind parseopt
  bind tables

  for kind, key, value in parseopt.getopt():
    case kind
    of parseopt.cmdArgument:
      arguments.add(key)
    of parseopt.cmdLongOption:
      tables.add(longOptions, key, value)
    of parseopt.cmdShortOption:
      tables.add(shortOptions, key, value)
    else:
      nil

  #Call the passed statements so that the above templates are called
  statements
  if not error.isNil:
    quit error.msg


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