//
//  DoubleLiteralTokenGenerator.swift
//  PranceCore
//
//  Created by Tristan Burnside on 6/9/19.
//

import Foundation

class DoubleLiteralTokenGenerator: TokenGenerator {
  
  var isValid: Bool = true
  
  var isComplete: Bool = false
  
  var currentString = ""
  
  var hasIPart: Bool {
    return !currentString.isEmpty
  }
  
  var hasPoint = false
  
  func consume(char: Character) {
    if char.isWholeNumber {
      currentString.append(char)
      if hasPoint {
        isComplete = true
      }
      return
    }
    if char == ".",
      hasIPart,
      !hasPoint {
      currentString.append(char)
      hasPoint = true
      return
    }
    isValid = false
  }
  
  func emitToken() throws -> Tokenizable {
    guard let currentDouble = Double(currentString) else {
      throw "Token is not a double literal"
    }
    return LiteralToken(type: .double(currentDouble))
  }
  
  func reset() {
    currentString = ""
    hasPoint = false
    isComplete = false
    isValid = true
  }
}
