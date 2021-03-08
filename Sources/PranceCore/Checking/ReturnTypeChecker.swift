//
//  ReturnTypeChecker.swift
//  PranceCore
//
//  Created by Tristan Burnside on 3/7/21.
//

import Foundation

final class ReturnTypeChecker: ASTChecker {
  let file: File
  
  init(file: File) {
    self.file = file
  }
  
  func check() throws {
    // Check that all returns are of the right type
    try checkExpr { (expr, parameterValues) in
      switch expr {
      case .return(_, let returnType):
        guard let returnVar = try? parameterValues.findVariable(name: ".return") else {
          throw ParseError.unexpectedReturn
        }
        let validReturnTypes = validTypeNames(for: returnVar.1)
        guard validReturnTypes.contains(returnType.name) else {
          throw ParseError.returnTypeMismatch(expected: returnVar.1.name, got: returnType.name)
        }
      default:
        break
      }
    }
    
    // Check that each function has a return (if necessary)
    for function in file.functions {
      if try !hasReturn(exprs: function.typedExpr),
         !(function.prototype.returnType is VoidStore) {
        throw ParseError.noReturnInFunction(function.prototype.name)
      }
    }
    
    for type in file.customTypes {
      for function in type.functions {
        if try !hasReturn(exprs: function.typedExpr),
           !(function.prototype.returnType is VoidStore) {
          throw ParseError.noReturnInFunction(function.prototype.name)
        }
      }
    }
  }
  
  private func hasReturn(exprs: [TypedExpr]) throws -> Bool {
    for exprIndex in 0..<exprs.count {
      let expr = exprs[exprIndex]
      if try hasReturn(expr: expr) {
        guard exprIndex == exprs.count - 1 else {
          throw ParseError.unreachableCode
        }
        return true
      }
    }
    return false
  }
  
  private func hasReturn(expr: TypedExpr) throws -> Bool {
    switch expr {
    case .forLoop(_, _, let body, _):
      return try hasReturn(exprs: body)
    case .ifelse(_, let thens, let elses, _):
      let returnInThen = try hasReturn(exprs: thens)
      let returnInElse = try hasReturn(exprs: elses)
      return returnInThen && returnInElse
    case .return:
      return true
    case .whileLoop(_, let body, _):
      return try hasReturn(exprs: body)
    default:
      return false
    }
  }
}
