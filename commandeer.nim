import algorithm
import parseopt2
import sequtils
import strutils
import tables
import typetraits


type
  assignmentProc = proc(value: string)
  Quantifier {.pure.} = enum
    single, oneOrMore, zeroOrMore
  Assigner = tuple[assign: assignmentProc, quantity: Quantifier]
  # Only allow one level of CommandLineMapping, so no recursion
  CommandLineMapping = ref object
    assigners: seq[Assigner]
    shortOptions: TableRef[string, assignmentProc]
    longOptions: TableRef[string, assignmentProc]
    activate: proc()

var errorMessage: string = ""
var subCommands = newTable[string, CommandLineMapping]()
var currentMapping: CommandLineMapping


## Debugging, conversion and utility procs

proc `$`*(f: assignmentProc): string = "assignmentProc"


proc `$`*(clm: CommandLineMapping): string =
  result = "{" &
    "assigners: " & $clm.assigners & ", " &
    "shorts: " & $clm.shortOptions & ", " &
    "longs: " & $clm.longOptions &
    "}"

proc assignConversion(variable: var int, value: string) =
  variable = strutils.parseInt(value)


proc assignConversion(variable: var seq[int], value: string) =
  variable.add(strutils.parseInt(value))


proc assignConversion(variable: var float, value: string) =
  variable = strutils.parseFloat(value)


proc assignConversion(variable: var seq[float], value: string) =
  variable.add(strutils.parseFloat(value))


proc assignConversion(variable: var string, value: string) =
  if value == "": raise newException(ValueError, "Empty string")
  variable = value


proc assignConversion(variable: var seq[string], value: string) =
  variable.add(value)


proc assignConversion(variable: var bool, value: string) =
  ## will accept "yes", "true" as true values
  ## the only way we get an empty string here is because of a key
  ## with no value, in which case the presence of the key is enough
  ## to return true
  variable = if value == "": true else: strutils.parseBool(value)


proc assignConversion(variable: var seq[bool], value: string) =
  variable.add(if value == "": true else: strutils.parseBool(value))


proc assignConversion(variable: var char, value: string) =
  if value == "": raise newException(ValueError, "Empty string")
  variable = value[0]


proc assignConversion(variable: var seq[char], value: string) =
  variable.add(value[0])


proc exitWithErrorMessage(msg="") =
  if msg != "" and errorMessage != "":
    quit msg & "\n" & errorMessage, QuitFailure
  elif msg != "":
    quit msg, QuitFailure
  elif errorMessage != "":
    quit errorMessage, QuitFailure
  else:
    quit QuitFailure


proc getOptionAssignment(key: string): assignmentProc =
  var tmpMapping = currentMapping
  var optionAssignmentProcs: TableRef[string, assignmentProc]

  while not tmpMapping.isNil and optionAssignmentProcs.isNil:
    if key in tmpMapping.longOptions:
      optionAssignmentProcs = tmpMapping.longOptions
    elif key in tmpMapping.shortOptions:
      optionAssignmentProcs = tmpMapping.shortOptions
    else:
      if tmpMapping == subcommands[""]:
        tmpMapping = nil
      else:
        tmpMapping = subcommands[""]

  if tmpMapping.isNil:
    return nil
  else:
    return optionAssignmentProcs[key]


## Interpretation of the tokens
proc interpretCLI(cliTokens: var seq[GetoptResult]) =
  var argumentIndex = 0
  currentMapping = subCommands[""]

  while len(cliTokens) > 0:
    var token = cliTokens.pop()
    if token.kind in [parseopt2.cmdLongOption, parseopt2.cmdShortOption]:
      var assign = getOptionAssignment(token.key)

      if assign.isNil:
        # Ignore superfluous extra option
        continue

      try:
        assign(token.val)
      except ValueError:
        if token.val != "":
          exitWithErrorMessage(getCurrentExceptionMsg())
        if len(cliTokens) > 0:
          # There might be a space separating key and value
          # The value is the next token
          var nextToken = cliTokens.pop()
          if nextToken.kind == parseopt2.cmdArgument:
            try:
              assign(nextToken.key)
            except ValueError:
              exitWithErrorMessage(getCurrentExceptionMsg())
          else:
            cliTokens.add(nextToken)
            exitWithErrorMessage("Missing value for option '" & token.key & "'")
        else:
          exitWithErrorMessage("Missing value for option '" & token.key & "'")

    elif token.kind == parseopt2.cmdArgument:
      # Activate subcommand and continue interpreting after
      if argumentIndex == 0 and token.key in subcommands:
        currentMapping = subcommands[token.key]
        currentMapping.activate()
        continue

      # Ignore superfluous extra arguments
      if argumentIndex >= len(currentMapping.assigners):
        continue

      # Deal with regular argument
      var assigner = currentMapping.assigners[argumentIndex]
      var atLeastOneAssignment = false
      var nextToken: GetoptResult

      try:
        assigner.assign(token.key)  # key is the value for cmdArgument
        atLeastOneAssignment = true

        if assigner.quantity in [Quantifier.zeroOrMore, Quantifier.oneOrMore]:
          while len(cliTokens) > 0:  # broken by emptiness, conversion, option
            nextToken = cliTokens.pop()
            # echo "nextToken ", nextToken
            if nextToken.kind != parseopt2.cmdArgument:
              cliTokens.add(nextToken)
              break
            assigner.assign(nextToken.key)
      except ValueError:
        case assigner.quantity
        of Quantifier.single:
          exitWithErrorMessage(getCurrentExceptionMsg())
        of Quantifier.zeroOrMore:
          if atLeastOneAssignment:
            cliTokens.add(nextToken)
          else:
            cliTokens.add(token)
        of Quantifier.oneOrMore:
          if atLeastOneAssignment:
            cliTokens.add(nextToken)
          else:
            exitWithErrorMessage(getCurrentExceptionMsg())

      inc(argumentIndex)

  if argumentIndex < len(currentMapping.assigners):
    exitWithErrorMessage("Missing command line arguments")


## Command line dsl keywords ##

template argument*(identifier: untyped, t: typeDesc): untyped =
  var identifier: t
  currentMapping.assigners.add((
    proc(value: string) {.closure.} =
      try:
        assignConversion(identifier, value)
      except ValueError:
        raise newException(
          ValueError,
          "Couldn't convert '" & value & "' to " & name(t)
        )
    ,
    Quantifier.single
  ))


template arguments*(identifier: untyped, t: typeDesc, atLeast1: bool=true): untyped =
  var identifier = newSeq[t]()
  currentMapping.assigners.add((
    proc(value: string) {.closure.} =
      try:
        assignConversion(identifier, value)
      except ValueError:
        raise newException(
          ValueError,
          "Couldn't convert '" & value & "' to " & name(t)
        )
    ,
    if atLeast1: Quantifier.oneOrMore else: Quantifier.zeroOrMore
  ))


template option*(identifier: untyped, t: typeDesc, long, short: string,
                 default: t): untyped =
  var identifier: t = default
  var assignment = proc(value: string) =
    try:
      assignConversion(identifier, value)
    except ValueError:
      raise newException(
        ValueError,
        "Couldn't convert '" & value & "' to " & name(t)
      )
  currentMapping.longOptions[long] = assignment
  currentMapping.shortOptions[short] = assignment


template option*(identifier: untyped, t: typeDesc, long, short: string): untyped =
  var identifier: t
  var assignment = proc(value: string) =
    try:
      assignConversion(identifier, value)
    except ValueError:
      raise newException(
        ValueError,
        "Couldn't convert '" & value & "' to " & name(t)
      )
  currentMapping.longOptions[long] = assignment
  currentMapping.shortOptions[short] = assignment


template exitoption*(long, short, msg: string): untyped =
  var exiter = proc(value: string) =
    quit msg, QuitSuccess
  currentMapping.longOptions[long] = exiter
  currentMapping.shortOptions[short] = exiter


template errormsg*(msg: string): untyped =
  errorMessage = msg


template subcommand*(identifier: untyped, subcommandName: string,
                    statements: untyped): untyped =
    var identifier: bool = false
    subCommands[subcommandName] = CommandLineMapping(
      assigners: newSeq[Assigner](),
      shortOptions: newTable[string, assignmentProc](),
      longOptions: newTable[string, assignmentProc](),
      activate: proc() =
        identifier = true
    )
    currentMapping = subCommands[subcommandName]
    statements
    currentMapping = subCommands[""]


template commandline*(statements: untyped): untyped =
  var cliTokens = reversed(toSeq(parseopt2.getopt()))
  var defaultMapping = CommandLineMapping(
    assigners: newSeq[Assigner](),
    shortOptions: newTable[string, assignmentProc](),
    longOptions: newTable[string, assignmentProc](),
    activate: proc() = discard
  )
  subCommands[""] = defaultMapping
  currentMapping = defaultMapping
  statements
  interpretCLI(cliTokens)
