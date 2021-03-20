//
//  ExtensionResolver.swift
//  PranceCore
//
//  Created by Tristan Burnside on 3/19/21.
//

import Foundation

final class ExtensionResolver: ASTChecker {
  let file: File
  
  init(file: File) {
    self.file = file
  }
  
  func check() throws {
    for extend in file.extensions {
      if let type = file.customTypes.first(where: { $0.name == extend.name }) {
        type.functions.append(contentsOf: extend.functions)
      } else {
        throw ParseError.couldNotFindTypeForExtension(extend.name)
      }
    }
    
    for def in file.defaults {
      if let proto = file.protocols.first(where: { $0.name == def.name }) {
        for function in def.functions {
          guard let prototype = proto.prototypes.first(where: { $0.name == function.prototype.name }) else {
            throw ParseError.unknownFunction(function.prototype.name)
          }
          if prototype != function.prototype {
            throw ParseError.functionDoesNotMatchDeclaration(prototype.name, inType: proto.name)
          }
          proto.defaults[function.prototype.name] = function
        }
      } else {
        throw ParseError.couldNotFindTypeForExtension(def.name)
      }
    }
  }
}
