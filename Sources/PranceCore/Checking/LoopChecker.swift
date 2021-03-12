//
//  LoopChecker.swift
//  PranceCore
//
//  Created by Tristan Burnside on 3/7/21.
//

import Foundation

final class LoopChecker: ASTChecker {
  let file: File
  
  init(file: File) {
    self.file = file
  }
  
  func check() throws {
    try checkExpr { (expr, parameterValues) in
      var condition: TypedExpr? = nil
      var loopBody: [TypedExpr]? = nil
      switch expr {
      case .ifelse(let cond, _, _, _):
        condition = cond
      case .forLoop(_, let cond, let body, _):
        condition = cond
        loopBody = body
      case .whileLoop(let cond, let body, _):
        condition = cond
        loopBody = body
      default:
        return
      }
      if let loopBody = loopBody {
        try loopBody.forEach {
          if case .return = $0 {
            throw ParseError.unexpectedReturn
          }
        }
      }
      
      guard case .logical = condition else {
        throw ParseError.loopDeclarationMustIncludeComparison
      }
    }
  }
}
