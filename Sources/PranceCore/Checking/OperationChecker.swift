//
//  OperationChecker.swift
//  PranceCore
//
//  Created by Tristan Burnside on 3/7/21.
//

import Foundation

final class OperationChecker: ASTChecker {
  let file: File
  
  init(file: File) {
    self.file = file
  }
  
  func check() throws {
    try checkExpr { (expr, parameterValues) in
      switch expr {
      case .binary(let left, let op, let right, _):
        guard left.type.name == right.type.name else {
          throw ParseError.invalidOperation(left.type, right.type, FilePosition(line: 0, position: 0))
        }
        switch op {
        case .divide, .minus, .times, .plus:
          guard left.type is DoubleStore
                  || left.type is IntStore else {
            throw ParseError.invalidOperation(left.type, right.type, FilePosition(line: 0, position: 0))
          }
        case .mod:
          guard left.type is IntStore else {
            throw ParseError.invalidOperation(left.type, right.type, FilePosition(line: 0, position: 0))
          }
        }
      case .logical(let left, let op, let right, _):
        guard left.type.name == right.type.name else {
          throw ParseError.invalidOperation(left.type, right.type, FilePosition(line: 0, position: 0))
        }
        switch op {
        case .and, .or:
          guard left.type is IntStore else {
            throw ParseError.invalidOperation(left.type, right.type, FilePosition(line: 0, position: 0))
          }
        case .equals, .notEqual:
          guard left.type is IntStore ||
                  left.type is DoubleStore else {
            throw ParseError.invalidOperation(left.type, right.type, FilePosition(line: 0, position: 0))
          }
        case .lessThan, .lessThanOrEqual, .greaterThan, .greaterThanOrEqual:
          guard left.type is IntStore ||
                  left.type is DoubleStore else {
            throw ParseError.invalidOperation(left.type, right.type, FilePosition(line: 0, position: 0))
          }
        }
      default:
        break
      }
    }
  }
}
