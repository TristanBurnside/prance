//
//  SingleCharTokenGenerator.swift
//  PranceCore
//
//  Created by Tristan Burnside on 6/9/19.
//

import Foundation

class SingleCharTokenGenerator: TokenGenerator {
  // Handle single-scalar tokens, like comma,
  // leftParen, rightParen, and the operators
  static let tokenMapping: [Character: Tokenizable] = [
    ",": CommaToken(),
    "(": LeftParenToken(),
    ")": RightParenToken(),
    ";": SemicolonToken(),
    "+": OperatorToken(type: .plus),
    "-": OperatorToken(type: .minus),
    "*": OperatorToken(type: .times),
    "/": OperatorToken(type: .divide),
    "%": OperatorToken(type: .mod),
    "=": AssignToken(),
    ".": MemberReferenceToken(),
    ":": ColonToken(),
    "{": LeftBraceToken(),
    "}": RightBraceToken(),
    "<": LogicalOperatorToken(type: .lessThan),
    ">": LogicalOperatorToken(type: .greaterThan)
  ]
  
  private var currentValue: Tokenizable?
  
  func consume(char: Character) {
    guard currentValue == nil,
      let newValue = SingleCharTokenGenerator.tokenMapping[char] else {
        isValid = false
        return
    }
    currentValue = newValue
    isComplete = true
  }
  
  func emitToken() throws -> Tokenizable {
    guard let currentValue = currentValue else {
      throw "No token to emit"
    }
    return currentValue
  }
  
  func reset() {
    currentValue = nil
    isValid = true
    isComplete = false
  }
  
  var isValid: Bool = true
  
  var isComplete: Bool = false
}
