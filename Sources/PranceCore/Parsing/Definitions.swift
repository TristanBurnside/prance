//
//  Definitions.swift
//  PranceCore
//
//  Created by Tristan Burnside on 8/2/19.
//

import Foundation

extension TypeToken: Definable {
  func create(from tokenStream: TokenStream) throws -> Definition {
    guard let nameToken = tokenStream.next()?.token as? IdentifierToken else {
      throw ParseError.unexpectedEOF
    }
    
    var protos = [String]()

    if tokenStream.peek()?.token is ColonToken {
      try tokenStream.skip(ColonToken())
      guard let firstProto = tokenStream.next()?.token as? IdentifierToken else {
        let badToken = tokenStream.previous()
        throw ParseError.unexpectedToken(badToken.token, badToken.marker)
      }
      protos.append(firstProto.name)
      while tokenStream.peek()?.token is CommaToken {
        try tokenStream.skip(CommaToken())
        guard let next = tokenStream.next()?.token as? IdentifierToken else {
          let badToken = tokenStream.previous()
          throw ParseError.unexpectedToken(badToken.token, badToken.marker)
        }
        protos.append(next.name)
      }
    }
    
    try tokenStream.skip(LeftBraceToken())
    var properties = [(String, StoredType)]()
    var functions = [FunctionDefinition]()
    while let token = tokenStream.next()?.token as? MemberExpressable {
      switch try token.expressMember(tokenStream: tokenStream) {
      case .variable(let variable):
        properties.append((variable.name, variable.type))
      case .function(let function):
        functions.append(function)
      }
    }
    return .type(TypeDefinition(name: nameToken.name, properties: properties, functions: functions, protocols: protos))
  }
}

extension ProtocolToken: Definable {
  func create(from tokenStream: TokenStream) throws -> Definition {
    guard let nameToken = tokenStream.next()?.token as? IdentifierToken else {
      let badToken = tokenStream.previous()
      throw ParseError.unexpectedToken(badToken.token, badToken.marker)
    }
    
    try tokenStream.skip(LeftBraceToken())
    var properties = [(String, StoredType)]()
    var functions = [Prototype]()
    while let token = tokenStream.next()?.token as? ProtocolMemberExpressable {
      switch try token.expressProtocolMember(tokenStream: tokenStream) {
      case .variable(let variable):
        properties.append((variable.name, variable.type))
      case .function(let function):
        functions.append(function)
      }
    }
    
    return .proto(ProtocolDefinition(name: nameToken.name, properties: properties, prototypes: functions))
  }
}

extension FunctionToken: Definable {
  func create(from tokenStream: TokenStream) throws -> Definition {
    return try .function(createFunction(from: tokenStream))
  }
  
  func createFunction(from tokenStream: TokenStream) throws -> FunctionDefinition {
    guard let funNameToken = tokenStream.next()?.token as? PrototypeDefinable else {
      throw ParseError.unexpectedEOF
    }
    let prototype = try funNameToken.expressPrototype(tokenStream: tokenStream)
    try tokenStream.skip(LeftBraceToken())
    var expressions = [Expr]()
    while !(tokenStream.peek()?.token is RightBraceToken) {
      expressions.append(try tokenStream.expressNext())
    }
    try tokenStream.skip(RightBraceToken())
    return FunctionDefinition(prototype: prototype, expr: expressions)
  }
  
  func parseVariableDefinition(tokenStream: TokenStream) throws -> VariableDefinition {
    guard let identifier = tokenStream.next()?.token as? VariableDefinable else {
      throw ParseError.unexpectedEOF
    }
    return try identifier.expressVariableDefinition(tokenStream: tokenStream)
  }
}

extension ExternToken: Definable {
  func create(from tokenStream: TokenStream) throws -> Definition {
    guard let name = tokenStream.next() as? PrototypeDefinable else {
      throw ParseError.unexpectedEOF
    }
    return try .extern(name.expressPrototype(tokenStream: tokenStream))
  }
}

protocol VariableDefinable {
  func expressVariableDefinition(tokenStream: TokenStream) throws -> VariableDefinition
}

extension IdentifierToken: VariableDefinable {
  func expressVariableDefinition(tokenStream: TokenStream) throws -> VariableDefinition {
    // colon
    tokenStream.next()
    // identifier(type)
    guard let typeIdentifier = tokenStream.next()?.token as? TypeIdentifiable else {
      throw ParseError.unexpectedEOF
    }
    guard let type = typeIdentifier.toType() else {
      throw ParseError.unexpectedEOF
    }
    return VariableDefinition(name: name, type: type)
  }
}

protocol TypeIdentifiable {
  func toType() -> StoredType?
}

extension IdentifierToken: TypeIdentifiable {
  func toType() -> StoredType? {
    return name.toType()
  }
}

protocol PrototypeDefinable {
  func expressPrototype(tokenStream: TokenStream) throws -> Prototype
}

extension IdentifierToken: PrototypeDefinable {
  func expressPrototype(tokenStream: TokenStream) throws -> Prototype {
    tokenStream.next()
    
    var params = [VariableDefinition]()
    
    while let nextVar = tokenStream.next()?.token as? VariableDefinable {
      params.append(try nextVar.expressVariableDefinition(tokenStream: tokenStream))
      try tokenStream.skip(CommaToken())
    }
    
    let returnType: StoredType
    guard let nextToken = tokenStream.peek()?.token else {
      throw ParseError.unexpectedEOF
    }
    switch nextToken {
    case let typeIdentifier as IdentifierToken:
      guard let type = typeIdentifier.name.toType() else {
        throw ParseError.unexpectedToken(nextToken, FilePosition(line: 0, position: 0))
      }
      returnType = type
      tokenStream.next()
    case _ as LeftBraceToken:
      returnType = VoidStore()
    default:
      throw ParseError.unexpectedToken(nextToken, FilePosition(line: 0, position: 0))
    }
    
    return Prototype(name: name, params: params, returnType: returnType)
  }
}
