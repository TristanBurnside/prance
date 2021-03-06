//
//  Expressions.swift
//  PranceCore
//
//  Created by Tristan Burnside on 6/16/19.
//

import Foundation

extension LeftParenToken: PostExpressable {
  func express(after previousExpr: Expr, tokenStream: TokenStream) throws -> Expr {
    var args = [FunctionArg]()
    if !(tokenStream.peek()?.token is RightParenToken) {
      var label: String?
      if let identifier = tokenStream.peek()?.token as? IdentifierToken {
        label = identifier.name
        try tokenStream.skip(identifier)
        try tokenStream.skip(ColonToken())
      }
      args.append(FunctionArg(label: label, expr: try tokenStream.expressNext(), typedExpr: nil))
    }
    while !(tokenStream.next()?.token is RightParenToken) {
      var label: String?
      if let identifier = tokenStream.peek()?.token as? IdentifierToken {
        label = identifier.name
        try tokenStream.skip(identifier)
        try tokenStream.skip(ColonToken())
      }
      args.append(FunctionArg(label: label, expr: try tokenStream.expressNext(), typedExpr: nil))
    }
    switch previousExpr {
    case .variable(let name):
      return .call(FunctionCall(name: name, args: args))
    case .memberDereference(let expr, .property(let name)):
      return .memberDereference(expr, .function(FunctionCall(name: name, args: args)))
    default:
      throw ParseError.unexpectedToken(self, tokenStream.next()!.marker)
    }
  }
}

extension MemberReferenceToken: PostExpressable {
  func express(after previousExpr: Expr, tokenStream: TokenStream) throws -> Expr {
    guard let identifier = tokenStream.next()?.token as? IdentifierToken else {
      throw ParseError.unexpectedEOF
    }
    return .memberDereference(previousExpr, .property(identifier.name))
  }
}

extension LiteralToken: Expressable {
  func express(tokenStream: TokenStream) throws -> Expr {
    return .literal(type)
  }
}

protocol TypeExpressable {
  func expressType() throws -> StoredType
}

extension VariableToken: Expressable {
  func express(tokenStream: TokenStream) throws -> Expr {
    guard let next = tokenStream.next(),
      let identifier = next.token as? IdentifierToken else {
        throw ParseError.unexpectedEOF
    }
    guard tokenStream.next()?.token is ColonToken else {
      throw ParseError.unexpectedEOF
    }
    guard let typeToken = tokenStream.next()?.token as? TypeExpressable else {
      throw ParseError.unexpectedEOF
    }
    let type = try typeToken.expressType()
    return .variableDefinition(VariableDefinition(name: identifier.name, type: type))
  }
}

enum TypeMemberDefinition {
  case variable(VariableDefinition)
  case function(FunctionDefinition)
}

enum ProtocolMemberDefinition {
  case variable(VariableDefinition)
  case function(Prototype)
}

enum TypeMemberReference {
  case property(String)
  case function(FunctionCall)
}

protocol MemberExpressable {
  func expressMember(tokenStream: TokenStream) throws -> TypeMemberDefinition
}

protocol ProtocolMemberExpressable {
  func expressProtocolMember(tokenStream: TokenStream) throws -> ProtocolMemberDefinition
}

extension VariableToken: MemberExpressable {
  func expressMember(tokenStream: TokenStream) throws -> TypeMemberDefinition {
    guard let next = tokenStream.next(),
      let identifier = next.token as? IdentifierToken else {
        throw ParseError.unexpectedEOF
    }
    guard tokenStream.next()?.token is ColonToken else {
      throw ParseError.unexpectedEOF
    }
    guard let typeToken = tokenStream.next()?.token as? TypeExpressable else {
      throw ParseError.unexpectedEOF
    }
    let type = try typeToken.expressType()
    return .variable(VariableDefinition(name: identifier.name, type: type))
  }
}

extension VariableToken: ProtocolMemberExpressable {
  func expressProtocolMember(tokenStream: TokenStream) throws -> ProtocolMemberDefinition {
    guard case .variable(let member) = try expressMember(tokenStream: tokenStream) else {
      throw ParseError.unexpectedEOF
    }
    return .variable(member)
  }
}

extension FunctionToken: MemberExpressable {
  func expressMember(tokenStream: TokenStream) throws -> TypeMemberDefinition {
    let definition = try createFunction(from: tokenStream)
    return .function(definition)
  }
}

extension FunctionToken: ProtocolMemberExpressable {
  func expressProtocolMember(tokenStream: TokenStream) throws -> ProtocolMemberDefinition {
    guard let prototypeToken = tokenStream.next()?.token as? PrototypeDefinable else {
      let badToken = tokenStream.previous()
      throw ParseError.unexpectedToken(badToken.token, badToken.marker)
    }
    let prototype = try prototypeToken.expressPrototype(tokenStream: tokenStream)
    return .function(prototype)
  }
}

extension IdentifierToken: Expressable {
  func express(tokenStream: TokenStream) throws -> Expr {
    return .variable(name)
  }
}

extension IdentifierToken: TypeExpressable {
  func expressType() throws -> StoredType {
    guard let type = name.toType() else {
      throw ParseError.undefinedType(name, FilePosition(line:0, position: 0))
    }
    return type
  }
}

extension IfToken: Expressable {
  func express(tokenStream: TokenStream) throws -> Expr {
    
    // Consume LParen
    tokenStream.next()
    
    let condition = try tokenStream.expressNext()
    
    //Consume RParen
    tokenStream.next()
    
    guard tokenStream.next()?.token is LeftBraceToken else {
      throw ParseError.unexpectedToken(WhitespaceToken(), FilePosition(line: 0, position: 0))
    }
    
    var thens = [Expr]()
    while !(tokenStream.peek()?.token is RightBraceToken?) {
      thens.append(try tokenStream.expressNext())
    }
    tokenStream.next()
    
    var elses = [Expr]()
    if tokenStream.peek()?.token is ElseToken? {
      tokenStream.next()
      guard tokenStream.next()?.token is LeftBraceToken? else {
        throw ParseError.unexpectedToken(WhitespaceToken(), FilePosition(line: 0, position: 0))
      }
      while !(tokenStream.peek()?.token is RightBraceToken?) {
        elses.append(try tokenStream.expressNext())
      }
      tokenStream.next()
    }
    
    return .ifelse(condition, thens, elses)
  }
}

extension ReturnToken: Expressable {
  func express(tokenStream: TokenStream) throws -> Expr {
    if tokenStream.peek()?.token is RightBraceToken? {
      return .return(nil)
    }
    return .return(try tokenStream.expressNext())
  }
}

protocol Returnable {}

extension ReturnToken: Returnable {}

extension ForToken: Expressable {
  func express(tokenStream: TokenStream) throws -> Expr {
    guard tokenStream.next()?.token is LeftParenToken? else {
      throw ParseError.unexpectedToken(WhitespaceToken(), FilePosition(line:0, position:0))
    }
    
    //assignment
    let assign = try tokenStream.expressNext()
    guard tokenStream.next()?.token is SemicolonToken else {
      throw ParseError.unexpectedToken(WhitespaceToken(), FilePosition(line: 0, position: 0))
    }
    
    //condition
    let condition = try tokenStream.expressNext()
    guard tokenStream.next()?.token is SemicolonToken else {
      throw ParseError.unexpectedToken(WhitespaceToken(), FilePosition(line: 0, position: 0))
    }
    
    //increment
    let increment = try tokenStream.expressNext()
    guard tokenStream.next()?.token is RightParenToken?,
          tokenStream.next()?.token is LeftBraceToken? else {
      throw ParseError.unexpectedToken(WhitespaceToken(), FilePosition(line: 0, position: 0))
    }
    
    //body
    var body = [Expr]()
    while tokenStream.peek()?.token is Expressable {
      body.append(try tokenStream.expressNext())
    }
    guard tokenStream.next()?.token is RightBraceToken? else {
      throw ParseError.unexpectedToken(WhitespaceToken(), FilePosition(line: 0, position: 0))
    }
    body.append(increment)
    return .forLoop(assign, condition, body)
  }
}

extension AssignToken: PostExpressable {
  func express(after previousExpr: Expr, tokenStream: TokenStream) throws -> Expr {
    let valueExpr = try tokenStream.expressNext()
    return .variableAssignment(previousExpr, valueExpr)
  }
}

extension OperatorToken: PostExpressable {
  func express(after previousExpr: Expr, tokenStream: TokenStream) throws -> Expr {
    let nextExpr = try tokenStream.expressNext()
    return .binary(previousExpr, type, nextExpr)
  }
}

extension LogicalOperatorToken: PostExpressable {
  func express(after previousExpr: Expr, tokenStream: TokenStream) throws -> Expr {
    let nextExpr = try tokenStream.expressNext()
    return .logical(previousExpr, type, nextExpr)
  }
}
