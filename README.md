# Prance
A language and LLVM based compiler for teaching/learning about [Protocol Oriented Programming](https://developer.apple.com/videos/play/wwdc2015/408/) concepts.

Prance code uses an Object-oriented style without type inheritence. This is intended to prompt users into finding non heirarchical solutions to problems.

**v0.1**

Support for:
- if-else
- c-like for statements
- while loops
- primitive double, float, int and string types
- stand alone functions
- reference types
  - properties
  - methods
  - protocol conformance
- protocols
  - functions
- arithmetic operators
- logical comparators

## Getting started
get llvm `brew install llvm@11`

clone this repo 

run `swift build`

run `swift package generate-xcodeproj`

open `prance.xcodeproj`

run `swift ./DerivedData/prance/SourcePackages/checkouts/LLVMSwift/utils/make-pkgconfig.swift`

build in XCode

compiled `Prance` binary should reside in ./DerivedData/Prance/Build/Products/Debug/Prance

compile the demo code at `samples/demo.prance` by calling `./Prance demo.prance`

run the demo code `./demo`
