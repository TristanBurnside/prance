//
//  ProtocolConformanceChecker.swift
//  PranceCore
//
//  Created by Tristan Burnside on 3/3/21.
//

import Foundation

final class ProtocolConformanceChecker: ASTChecker {
  
  let file: File
  
  init(file: File) {
    self.file = file
  }
  
  func check() throws {
    try file.customTypes.map {
      return ($0, $0.protocols)
    }.flatMap { (type, protos) -> [(TypeDefinition, String)] in
      return protos.map { (type, $0) }
    }.map { (type, proto) -> (TypeDefinition, ProtocolDefinition) in
      guard let protoDef = file.protocols.first(where: { $0.name == proto }) else {
        throw ParseError.unknownProtocol(proto, in: type.name)
      }
      return (type, protoDef)
    }.flatMap { (type, proto) in
      return proto.prototypes.map { (type, proto.name, $0) }
    }.forEach({ (type, protocolName, protocolFunction) in
      if !type.functions.contains(where: { (function) -> Bool in
        function.prototype == protocolFunction
      }) {
        throw ParseError.unimplementedProtocol(protocolName, in: type.name, missing: protocolFunction.name)
      }
    })
  }
}
