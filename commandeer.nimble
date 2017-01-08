# Package

version     = "0.10.5"
author      = "Guillaume Viger"
description = "A small command line parsing DSL"
license     = "MIT"

installFiles = @["commandeer.nim"]

# Dependencies

requires "nim >= 0.14.0"

task tests, "Run the Commandeer tester":
  exec "nim compile --run runTests"
