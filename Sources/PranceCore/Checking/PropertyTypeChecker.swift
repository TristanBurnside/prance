//
//  PropertyTypeChecker.swift
//  PranceCore
//
//  Created by Tristan Burnside on 3/7/21.
//

import Foundation

final class PropertyTypeChecker: ASTChecker {
  let file: File
  
  init(file: File) {
    self.file = file
  }
  
  func check() throws {
    for type in allTypes.values {
      for property in type.properties {
        let type = property.1
        if type is CustomStore,
           allTypes[type.name] == nil {
          throw ParseError.undefinedType(type.name, FilePosition(line: 0, position: 0))
        }
      }
    }
  }
}
