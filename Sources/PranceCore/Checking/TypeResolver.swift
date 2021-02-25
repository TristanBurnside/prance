//
//  TypeResolver.swift
//  PranceCore
//
//  Created by Tristan Burnside on 2/23/21.
//

import Foundation
import LLVM

indirect enum TypedExpr {
  case literal(LiteralType, StoredType)
  case variable(String, StoredType)
  case variableDefinition(VariableDefinition, StoredType)
  case memberDereference(TypedExpr, TypeMemberReference, StoredType)
  case variableAssignment(TypedExpr, TypedExpr, StoredType)
  case binary(TypedExpr, BinaryOperator, TypedExpr, StoredType)
  case logical(TypedExpr, LogicalOperator, TypedExpr, StoredType)
  case ifelse(TypedExpr, [TypedExpr], [TypedExpr], StoredType)
  case forLoop(TypedExpr, TypedExpr, [TypedExpr], StoredType)
  case whileLoop(TypedExpr, [TypedExpr], StoredType)
  case call(FunctionCall, StoredType)
  case `return`(TypedExpr?, StoredType)
  
  var type: StoredType {
    switch self {
    case .literal(_, let type):
      return type
    case .variable(_, let type):
      return type
    case .variableDefinition(_, let type):
      return type
    case .memberDereference(_, _, let type):
      return type
    case .variableAssignment(_, _, let type):
      return type
    case .binary(_, _, _, let type):
      return type
    case .logical(_, _, _, let type):
      return type
    case .ifelse(_, _, _, let type):
      return type
    case .forLoop(_, _, _, let type):
      return type
    case .whileLoop(_, _, let type):
      return type
    case .call(_, let type):
      return type
    case .return(_, let type):
      return type
    }
  }
}

final class TypeResolver {
  
  let file: File
  let allTypes: [String: CallableType]
  var parameterValues: StackMemory = StackMemory()
  
  init(file: File) {
    var allTypes = [String: CallableType]()
    for type in file.customTypes {
      allTypes[type.name] = type
    }
    for proto in file.protocols {
      allTypes[proto.name] = proto
    }
    self.allTypes = allTypes
    self.file = file
  }
  
  func resolveTypes() throws {
    for type in file.customTypes {
      parameterValues.startFrame()
      parameterValues.addVariable(name: "self", type: CustomStore(name: type.name)!, value: nil)
      for function in type.functions {
        parameterValues.startFrame()
        for arg in function.prototype.params {
          parameterValues.addVariable(name: arg.name, type: arg.type, value: nil)
        }
        function.typedExpr = try resolveTypes(for: function.expr)
        parameterValues.endFrame()
      }
      parameterValues.startFrame()
      for arg in type.initMethod.prototype.params {
        parameterValues.addVariable(name: arg.name, type: arg.type, value: nil)
      }
      type.initMethod.typedExpr = try resolveTypes(for: type.initMethod.expr)
      parameterValues.endFrame()
      parameterValues.endFrame()
    }
    
    parameterValues.startFrame()
    for function in file.functions {
      parameterValues.startFrame()
      for arg in function.prototype.params {
        parameterValues.addVariable(name: arg.name, type: arg.type, value: nil)
      }
      function.typedExpr = try resolveTypes(for: function.expr)
      parameterValues.endFrame()
    }
    file.typedExpressions = try resolveTypes(for: file.expressions)
    parameterValues.endFrame()
  }
  
  private func resolveTypes(for exprs: [Expr]) throws -> [TypedExpr] {
    return try exprs.map { try resolveType(of: $0) }
  }
  
  private func resolveType(of expr: Expr) throws -> TypedExpr {
    switch expr {
    case .literal(.integer(let value)):
      return .literal(.integer(value), IntStore())
    case .literal(.float(let value)):
      return .literal(.float(value), FloatStore())
    case .literal(.double(let value)):
      return .literal(.double(value), DoubleStore())
    case .literal(.string(let value)):
      return .literal(.string(value), StringStore())
    case .memberDereference(let instanceExpr, let reference):
      let instanceWithType = try resolveType(of: instanceExpr)
      let instanceType = instanceWithType.type
      guard let definition = allTypes[instanceType.name] else {
        throw ParseError.undefinedType(instanceType.name, FilePosition(line: 0, position: 0))
      }
      switch reference {
      case .property(let name):
        let property = definition.properties.first { (propName, _) -> Bool in
          return name == propName
        }
        let type = property?.1 ?? VoidStore()
        return .memberDereference(instanceWithType, reference, type)
      case .function(let functionCall):
        let function = definition.prototypes.first { function -> Bool in
          return functionCall.name == function.name
        }
        let newArgs = try functionCall.args.map { return FunctionArg(label: $0.label, expr: $0.expr, typedExpr: try resolveType(of: $0.expr)) }
        let newCall = FunctionCall(name: functionCall.name, args: newArgs, returnType: functionCall.returnType)
        let type = function?.returnType ?? VoidStore()
        return .memberDereference(instanceWithType, .function(newCall), type)
      }
    case .call(let functionCall):
      let newArgs = try functionCall.args.map { return FunctionArg(label: $0.label, expr: $0.expr, typedExpr: try resolveType(of: $0.expr)) }
      let newCall = FunctionCall(name: functionCall.name, args: newArgs, returnType: functionCall.returnType)
      return .call(newCall, functionCall.returnType ?? VoidStore())
    case .return(let returnExpr):
      if let returnExpr = returnExpr {
        let typedReturn = try resolveType(of: returnExpr)
        return .return(typedReturn, typedReturn.type)
      } else {
        return .return(nil, VoidStore())
      }
    case .binary(let lhs, let op, let rhs):
      let lhsTyped = try resolveType(of: lhs)
      let rhsTyped = try resolveType(of: rhs)
      guard lhsTyped.type.name == rhsTyped.type.name else {
        throw ParseError.invalidOperation(lhsTyped.type, rhsTyped.type, FilePosition(line: 0, position: 0))
      }
      return .binary(lhsTyped, op, rhsTyped, lhsTyped.type)
    case .logical(let lhs, let op, let rhs):
      let lhsTyped = try resolveType(of: lhs)
      let rhsTyped = try resolveType(of: rhs)
      guard lhsTyped.type.name == rhsTyped.type.name else {
        throw ParseError.invalidComparison(lhsTyped.type, rhsTyped.type, FilePosition(line: 0, position: 0))
      }
      return .logical(lhsTyped, op, rhsTyped, IntStore())
    case .variable(let name):
      let variableType = try parameterValues.findVariable(name: name).1
      return .variable(name, variableType)
    case .variableDefinition(let definition):
      parameterValues.addVariable(name: definition.name, type: definition.type, value: nil)
      return .variableDefinition(definition, VoidStore())
    case .variableAssignment(let variable, let value):
      let variableTyped = try resolveType(of: variable)
      let valueTyped = try resolveType(of: value)
      return .variableAssignment(variableTyped, valueTyped, VoidStore())
    case .ifelse(let condition, let thens, let elses):
      let conditionTyped = try resolveType(of: condition)
      let thensTyped = try thens.map { try resolveType(of: $0) }
      let elsesTyped = try elses.map { try resolveType(of: $0) }
      return .ifelse(conditionTyped, thensTyped, elsesTyped, VoidStore())
    case .forLoop(let start, let condition, let body):
      let startTyped = try resolveType(of: start)
      let conditionTyped = try resolveType(of: condition)
      let bodyTyped = try body.map { try resolveType(of: $0) }
      return .forLoop(startTyped, conditionTyped, bodyTyped, VoidStore())
    case .whileLoop(let condition, let body):
      let conditionTyped = try resolveType(of: condition)
      let bodyTyped = try body.map { try resolveType(of: $0) }
      return .whileLoop(conditionTyped, bodyTyped, VoidStore())
    }
  }
}
