//
//  StringLiteralTokenGenerator.swift
//  PranceCore
//
//  Created by Tristan Burnside on 6/9/19.
//

import Foundation

class StringLiteralTokenGenerator: TokenGenerator {
  
  var isValid: Bool = true
  
  var isComplete: Bool = false
  
  private var isEscaped: Bool = false
  
  private var currentString = ""
  private var hasOpeningQuote = false
  
  func consume(char: Character) {
    guard !isComplete else {
      isValid = false
      return
    }
    if !hasOpeningQuote {
      consumeFirst(char)
    } else if isEscaped {
      consumeEscaped(char)
    } else {
      consumeBody(char)
    }
  }
  
  func emitToken() throws -> Tokenizable {
    return LiteralToken(type: .string([.string(currentString)]))
  }
  
  func reset() {
    hasOpeningQuote = false
    currentString = ""
    isComplete = false
    isValid = true
  }
  
  private func consumeFirst(_ char: Character) {
    guard char == "\"" else {
      isValid = false
      return
    }
    hasOpeningQuote = true
  }
  
  private func consumeBody(_ char: Character) {
    if char == "\"" {
      isComplete = true
    } else {
      currentString.append(char)
    }
    if char == "\\" {
      isEscaped = true
    }
  }
  
  private func consumeEscaped(_ char: Character) {
    currentString.append(char)
    isEscaped = false
  }
}
