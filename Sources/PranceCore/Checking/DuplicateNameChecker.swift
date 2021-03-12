//
//  DuplicateNameChecker.swift
//  PranceCore
//
//  Created by Tristan Burnside on 3/7/21.
//

import Foundation

final class DuplicateNameChecker: ASTChecker {
  let file: File
  
  init(file: File) {
    self.file = file
  }
  
  func check() throws {
    var fileLevelNames = Set<String>()
    var typeNameLists: [String: Set<String>] = [:]
    for type in allTypes.values {
      var typeNames = Set<String>()
      for property in type.properties {
        if !typeNames.insert(property.0).inserted {
          throw ParseError.duplicateDefinition(of: type.name + "." + property.0)
        }
      }
      for prototype in type.prototypes {
        if !typeNames.insert(prototype.name).inserted {
          throw ParseError.duplicateDefinition(of: type.name + "." + prototype.name)
        }
      }
      typeNameLists[type.name] = typeNames
    }
    
    for prototype in file.prototypeMap.keys {
      if !fileLevelNames.insert(prototype).inserted {
        throw ParseError.duplicateDefinition(of: prototype)
      }
    }
    
    try checkExpr { (expr, parameterValues) in
      switch expr {
      case .variableDefinition(let definition, _):
        if parameterValues.containsInCurrentFrame(definition.name) {
          throw ParseError.duplicateDefinition(of: definition.name)
        }
        if fileLevelNames.contains(definition.name) {
          throw ParseError.duplicateDefinition(of: definition.name)
        }
        if let type = try? parameterValues.findVariable(name: "self"),
           typeNameLists[type.name]?.contains(definition.name) ?? false {
          throw ParseError.duplicateDefinition(of: definition.name)
        }
      default:
        break
      }
    }
  }
}
