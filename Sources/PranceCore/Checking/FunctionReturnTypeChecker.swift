//
//  FunctionReturnTypeChecker.swift
//  PranceCore
//
//  Created by Tristan Burnside on 3/5/21.
//

import Foundation

final class FunctionReturnTypeChecker: ASTChecker {
  let file: File
  
  init(file: File) {
    self.file = file
  }
  
  func check() throws {
    for function in file.functions {
      try checkFunctionReturn(function)
    }
  }
  
  func checkFunctionReturn(_ function: FunctionDefinition) throws {
    let returnedType = function.typedExpr.last?.type ?? VoidStore()
    let typeNames = validTypeNames(for: function.prototype.returnType)
    guard typeNames.contains(returnedType.name) else {
      throw ParseError.returnTypeMismatch(expected: function.prototype.returnType.name, got: returnedType.name)
    }
  }
  
  private func validTypeNames(for storedType: StoredType) -> [String] {
    if let type = file.customTypes.first(where: { (type) -> Bool in
      type.name == storedType.name
    }) {
      return [type.name]
    }
    if let proto = file.protocols.first(where: { (proto) -> Bool in
      proto.name == storedType.name
    }) {
      let types = file.customTypes.filter { $0.protocols.contains(proto.name) }
      let typeNames = types.map { $0.name }
      return typeNames + [proto.name]
    }
    return [storedType.name]
  }
}
