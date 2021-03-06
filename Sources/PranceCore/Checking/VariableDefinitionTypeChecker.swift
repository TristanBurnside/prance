//
//  VariableDefinitionTypeChecker.swift
//  PranceCore
//
//  Created by Tristan Burnside on 3/5/21.
//

import Foundation

final class VariableDefinitionTypeChecker: ASTChecker {
  let file: File
  
  init(file: File) {
    self.file = file
  }
  
  func check() throws {
    try checkExpr { (expr, parameterValues) in
      switch expr {
      case .variableDefinition(_, let type):
        if let customType = type as? CustomStore,
           allTypes[customType.name] == nil {
          throw ParseError.undefinedType(customType.name, FilePosition(line: 0, position: 0))
        }
      default:
        break
      }
    }
  }
}
