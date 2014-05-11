
import parseopt2
import strutils
import tables


var
  argumentList = newSeq[ string ]()
  shortOptions = initTable[string, string](32)
  longOptions = initTable[string, string](32)
  argumentIndex = 0
  error : ref E_Base

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


template argument*(identifier : expr, t : typeDesc): stmt {.immediate.} =
  bind argumentList
  bind argumentIndex
  bind convert
  bind error

  var identifier : t

  if argumentList.len <= argumentIndex:
    error = newException(E_Base, "Not enough command-line argumentList")
  else:
    var typeVar : t
    try:
      identifier = convert(argumentList[argumentIndex], typeVar)
      inc(argumentIndex)
    except EInvalidValue:
      error = getCurrentException()


template option*(identifier : expr, t : typeDesc, longName : string,
                 shortName : string): stmt {.immediate.} =
  bind shortOptions
  bind longOptions
  bind convert
  bind error
  bind tables

  var identifier : t

  block:
    var typeVar : t
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
  bind argumentList
  bind shortOptions
  bind longOptions
  bind error
  bind parseopt2
  bind tables

  for kind, key, value in parseopt2.getopt():
    case kind
    of parseopt2.cmdArgument:
      argumentList.add(key)
    of parseopt2.cmdLongOption:
      tables.add(longOptions, key, value)
    of parseopt2.cmdShortOption:
      tables.add(shortOptions, key, value)
    else:
      discard

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