//
//  WhitespaceTokenGenerator.swift
//  PranceCore
//
//  Created by Tristan Burnside on 6/11/19.
//

import Foundation

class WhitespaceTokenGenerator: TokenGenerator {
  
  var isValid: Bool = true
  
  var isComplete: Bool = false
  
  func consume(char: Character) {
    if !char.isWhitespace {
      isValid = false
    } else {
      isComplete = true
    }
  }
  
  func emitToken() throws -> Tokenizable {
    return WhitespaceToken()
  }
  
  func reset() {
    isValid = true
    isComplete = false
  }
}
