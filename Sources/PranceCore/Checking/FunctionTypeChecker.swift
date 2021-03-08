//
//  FunctionReturnTypeChecker.swift
//  PranceCore
//
//  Created by Tristan Burnside on 3/5/21.
//

import Foundation

final class FunctionTypeChecker: ASTChecker {
  let file: File
  
  init(file: File) {
    self.file = file
  }
  
  func check() throws {
    for function in file.prototypeMap.values {
      try checkFunction(prototype: function)
    }
    for type in allTypes.values {
      for function in type.prototypes {
        try checkFunction(prototype: function)
      }
    }
  }
  
  func checkFunction(prototype: Prototype) throws {
    try checkFunctionReturn(prototype)
    try checkFunctionArgs(prototype)
  }
  
  func checkFunctionArgs(_ prototype: Prototype) throws {
    for arg in prototype.params {
      if arg.type is CustomStore,
         allTypes[arg.type.name] == nil {
        throw ParseError.undefinedType(arg.type.name, FilePosition(line: 0, position: 0))
      }
    }
  }
  
  func checkFunctionReturn(_ prototype: Prototype) throws {
    if prototype.returnType is CustomStore,
       allTypes[prototype.returnType.name] == nil {
      throw ParseError.undefinedType(prototype.returnType.name, FilePosition(line: 0, position: 0))
    }
  }
}
