//
//  MultiCharTokenGenerator.swift
//  PranceCore
//
//  Created by Tristan Burnside on 6/9/19.
//

import Foundation

class MultiCharTokenGenerator: TokenGenerator {
  
  // Handle single-scalar tokens, like comma,
  // leftParen, rightParen, and the operators
  private static let tokenMapping: [String: Tokenizable] = [
    "&&" : LogicalOperatorToken(type: .and),
    "||" : LogicalOperatorToken(type: .or),
    "==" : LogicalOperatorToken(type: .equals),
    "!=" : LogicalOperatorToken(type: .notEqual),
    "<=" : LogicalOperatorToken(type: .lessThanOrEqual),
    ">=" : LogicalOperatorToken(type: .greaterThanOrEqual),
    "fun": FunctionToken(),
    "extern": ExternToken(),
    "if": IfToken(),
    "then": ThenToken(),
    "else": ElseToken(),
    "return": ReturnToken(),
    "var": VariableToken(),
    "for": ForToken(),
    "while": WhileToken(),
    "type": TypeToken(),
    "protocol": ProtocolToken(),
    "default": DefaultToken(),
    "extension": ExtensionToken()
  ]
  
  var isValid: Bool = true
  
  var isComplete: Bool = false
  
  private var currentString = ""
  
  func consume(char: Character) {
    let newString = currentString.appending(String(char))
    guard isPrefix(key: newString) else {
      isValid = false
      return
    }
    currentString = newString
    if MultiCharTokenGenerator.tokenMapping[currentString] != nil {
      isComplete = true
    }
  }
  
  func emitToken() throws -> Tokenizable {
    guard let currentValue = MultiCharTokenGenerator.tokenMapping[currentString] else {
      throw "No token to emit"
    }
    return currentValue
  }
  
  func reset() {
    currentString = ""
    isValid = true
    isComplete = false
  }
  
  private func isPrefix(key: String) -> Bool {
    return MultiCharTokenGenerator.tokenMapping
      .keys
      .filter { $0.hasPrefix(key) }
      .count != 0
  }
}
