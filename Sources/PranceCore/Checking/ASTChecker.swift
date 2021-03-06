//
//  ASTChecker.swift
//  PranceCore
//
//  Created by Tristan Burnside on 3/3/21.
//

protocol ASTChecker {
  init(file: File)
  var file: File { get }
  func check() throws
}

extension ASTChecker {
  
  var allTypes: [String: CallableType] {
    var allTypes = [String: CallableType]()
    for type in file.customTypes {
      allTypes[type.name] = type
    }
    for proto in file.protocols {
      allTypes[proto.name] = proto
    }
    return allTypes
  }
  
  func checkExpr(checker: (TypedExpr, StackMemory) throws -> ()) rethrows {
    let parameterValues = StackMemory()
      for type in file.customTypes {
        parameterValues.startFrame()
        parameterValues.addVariable(name: "self", type: CustomStore(name: type.name)!, value: nil)
        for function in type.functions {
          parameterValues.startFrame()
          for arg in function.prototype.params {
            parameterValues.addVariable(name: arg.name, type: arg.type, value: nil)
          }
          try function.typedExpr.forEach { try checkRecursive(expr: $0, parameterValues: parameterValues, checker: checker) }
          parameterValues.endFrame()
        }
        parameterValues.startFrame()
        for arg in type.initMethod.prototype.params {
          parameterValues.addVariable(name: arg.name, type: arg.type, value: nil)
        }
        try type.initMethod.typedExpr.forEach { try checkRecursive(expr: $0, parameterValues: parameterValues, checker: checker) }
        parameterValues.endFrame()
        parameterValues.endFrame()
      }
      
      parameterValues.startFrame()
      for function in file.functions {
        parameterValues.startFrame()
        for arg in function.prototype.params {
          parameterValues.addVariable(name: arg.name, type: arg.type, value: nil)
        }
        try function.typedExpr.forEach { try checkRecursive(expr: $0, parameterValues: parameterValues, checker: checker) }
        parameterValues.endFrame()
      }
      try file.typedExpressions.forEach { try checkRecursive(expr: $0, parameterValues: parameterValues, checker: checker) }
      parameterValues.endFrame()
    }
  
  private func checkRecursive(expr: TypedExpr, parameterValues: StackMemory, checker: (TypedExpr, StackMemory) throws -> ()) rethrows {
    try checker(expr, parameterValues)
    switch expr {
    case .binary(let left, _, let right, _):
      try checkRecursive(expr: left, parameterValues: parameterValues, checker: checker)
      try checkRecursive(expr: right, parameterValues: parameterValues, checker: checker)
    case .forLoop(let decl, let cond, let body, _):
      try checkRecursive(expr: decl, parameterValues: parameterValues, checker: checker)
      try checkRecursive(expr: cond, parameterValues: parameterValues, checker: checker)
      try body.forEach { try checkRecursive(expr: $0, parameterValues: parameterValues, checker: checker) }
    case .call(let call, _):
      try call.args.forEach { try checkRecursive(expr: $0.typedExpr, parameterValues: parameterValues, checker: checker) }
    case .ifelse(let cond, let thens, let elses, _):
      try checkRecursive(expr: cond, parameterValues: parameterValues, checker: checker)
      try thens.forEach { try checkRecursive(expr: $0, parameterValues: parameterValues, checker: checker) }
      try elses.forEach { try checkRecursive(expr: $0, parameterValues: parameterValues, checker: checker) }
    case .logical(let left, _, let right, _):
      try checkRecursive(expr: left, parameterValues: parameterValues, checker: checker)
      try checkRecursive(expr: right, parameterValues: parameterValues, checker: checker)
    case .memberDereference(let instance, .property, _):
      try checkRecursive(expr: instance, parameterValues: parameterValues, checker: checker)
    case .memberDereference(let instance, .function(let call), _):
      try checkRecursive(expr: instance, parameterValues: parameterValues, checker: checker)
      try call.args.forEach { try checkRecursive(expr: $0.typedExpr, parameterValues: parameterValues, checker: checker) }
    case .return(let value, _):
      if let value = value {
        try checkRecursive(expr: value, parameterValues: parameterValues, checker: checker)
      }
    case .variableAssignment(let variable, let value, _):
      try checkRecursive(expr: variable, parameterValues: parameterValues, checker: checker)
      try checkRecursive(expr: value, parameterValues: parameterValues, checker: checker)
    case .whileLoop(let cond, let body, _):
      try checkRecursive(expr: cond, parameterValues: parameterValues, checker: checker)
      try body.forEach { try checkRecursive(expr: $0, parameterValues: parameterValues, checker: checker) }
    case .literal, .variable, .variableDefinition:
      break
    }
  }
}
