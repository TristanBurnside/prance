//
//  PropertyReferenceChecker.swift
//  PranceCore
//
//  Created by Tristan Burnside on 3/7/21.
//

import Foundation

final class PropertyReferenceChecker: ASTChecker {
  let file: File
  
  init(file: File) {
    self.file = file
  }
  
  func check() throws {
    try checkExpr { (expr, parameterValues) in
      switch expr {
      case .memberDereference(let instance, .property(let name), _):
        let type = try getTypeDefinition(for: instance.type)
        guard type.properties.contains(where: { $0.0 == name }) else {
          throw ParseError.type(type.name, doesNotContainProperty: name)
        }
      default:
        break
      }
    }
  }
  
  private func getTypeDefinition(for type: StoredType) throws -> CallableType {
    guard let typeDefinition = allTypes[type.name] else {
      throw ParseError.typeDoesNotContainMembers(type.name)
    }
    return typeDefinition
  }
}
