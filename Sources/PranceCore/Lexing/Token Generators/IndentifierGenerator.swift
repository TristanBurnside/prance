//
//  IndentifierGenerator.swift
//  PranceCore
//
//  Created by Tristan Burnside on 6/9/19.
//

import Foundation

class IdentifierGenerator: TokenGenerator {
  
  var isValid: Bool = true
  
  var isComplete: Bool = false
  
  private var currentString = ""
  
  func consume(char: Character) {
      if char.isAlphanumeric {
        currentString.append(char)
        isComplete = true
      } else {
        isValid = false
      }
  }
  
  func emitToken() throws -> Tokenizable {
    return IdentifierToken(name: currentString)
  }
  
  func reset() {
    currentString = ""
    isValid = true
    isComplete = false
  }
}
