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
    // Check for all protocol function implentations
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
      return proto.prototypes.filter { proto.defaults[$0.name] == nil }.map { (type, proto.name, $0) }
    }.filter { (type, protocolName, protocolFunction) -> Bool in
      return !type.functions.contains(where: { (function) -> Bool in
        function.prototype == protocolFunction
      })
    }
    .forEach({ (type, protocolName, protocolFunction) in
      throw ParseError.unimplementedProtocol(protocolName, in: type.name, missing: protocolFunction.name)
    })
  
    // Add conformance stubs where relying on default implementatons
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
    }.filter { (type, protocolName, protocolFunction) -> Bool in
      return !type.functions.contains(where: { (function) -> Bool in
        function.prototype == protocolFunction
      })
    }
    .forEach({ (type, protocolName, protocolFunction) in
      type.protocolConformanceStubs.append((protocolName, protocolFunction))
    })
  }
}
