//
//  IntegerLiteralTokenGenerator.swift
//  PranceCore
//
//  Created by Tristan Burnside on 6/9/19.
//

import Foundation

class IntegerLiteralTokenGenerator: TokenGenerator {
  
  var isValid: Bool = true
  
  var isComplete: Bool = false
  
  var currentString = ""
  
  func consume(char: Character) {
    guard char.isWholeNumber else {
      isValid = false
      return
    }
    currentString.append(char)
    isComplete = true
  }
  
  func emitToken() throws -> Tokenizable {
    guard let currentInt = Int(currentString) else {
      throw "Token is not an integer literal"
    }
    return LiteralToken(type: .integer(currentInt))
  }
  
  func reset() {
    currentString = ""
    isComplete = false
    isValid = true
  }
}
