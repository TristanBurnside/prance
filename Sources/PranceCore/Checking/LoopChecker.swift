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
      switch expr {
      case .ifelse(let cond, _, _, _):
        condition = cond
      case .forLoop(_, let cond, _, _):
        condition = cond
      case .whileLoop(let cond, _, _):
        condition = cond
      default:
        return
      }
      guard case .logical = condition else {
        throw ParseError.loopDeclarationMustIncludeComparison
      }
    }
  }
}
