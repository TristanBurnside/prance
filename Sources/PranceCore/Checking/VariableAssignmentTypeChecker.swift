//
//  VariableAssignmentTypeChecker.swift
//  PranceCore
//
//  Created by Tristan Burnside on 3/7/21.
//

import Foundation

final class VariableAssignmentTypeChecker: ASTChecker {
  let file: File
  
  init(file: File) {
    self.file = file
  }
  
  func check() throws {
    try checkExpr { (expr, parameterValues) in
      switch expr {
      case .variableAssignment(let variableExpr, let storedExpr, _):
        let assignableTypeNames = validTypeNames(for: variableExpr.type)
        if !assignableTypeNames.contains(storedExpr.type.name) {
          throw ParseError.unableToAssign(type: storedExpr.type.name, to: variableExpr.type.name)
        }
      default:
        break
      }
    }
  }
}
