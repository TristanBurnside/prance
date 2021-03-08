//
//  FunctionCallChecker.swift
//  PranceCore
//
//  Created by Tristan Burnside on 3/4/21.
//

import Foundation

final class FunctionCallChecker: ASTChecker {
  
  let file: File
  
  init(file: File) {
    self.file = file
  }
  
  func check() throws {
    try checkExpr { (expr, _) in
      try validateCallExpr(expr: expr)
    }
  }
  
  private func validateCallExpr(expr: TypedExpr) throws {
    switch expr {
    case .call(let functionCall, _):
      guard let prototype = file.prototypeMap[functionCall.name] else {
        throw ParseError.unknownFunction(functionCall.name)
      }
      try checkCallArgs(call: functionCall, args: prototype.params)
    case .memberDereference(let instance, .function(let call), _):
      guard let instanceType = allTypes[instance.type.name] else {
        throw ParseError.typeDoesNotContainMembers(instance.type.name)
      }
      guard let prototype = instanceType.prototypes.first(where: { $0.name == call.name }) else {
        throw ParseError.unknownFunction(call.name)
      }
      try checkCallArgs(call: call, args: prototype.params)
    default:
      break
    }
  }
  
  private func checkCallArgs(call: FunctionCall, args: [VariableDefinition]) throws {
    for (passedArg, functionArg) in zip(call.args, args) {
      if passedArg.label != functionArg.name {
        throw ParseError.unexpectedArgumentInCall(got: passedArg.label ?? "", expected: functionArg.name)
      }
      let validTypes = validTypeNames(for: functionArg.type)
      if !validTypes.contains(passedArg.typedExpr.type.name) {
        throw ParseError.wrongType(expectedType: functionArg.type.name, for: functionArg.name, got: passedArg.typedExpr.type.name)
      }
      try validateCallExpr(expr: passedArg.typedExpr)
    }
  }
}
