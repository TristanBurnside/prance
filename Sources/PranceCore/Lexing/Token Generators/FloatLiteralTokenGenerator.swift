//
//  FloatLiteralTokenGenerator.swift
//  PranceCore
//
//  Created by Tristan Burnside on 6/9/19.
//

import Foundation

class FloatLiteralTokenGenerator: TokenGenerator {
  
  var isValid: Bool = true
  
  var isComplete: Bool = false
  
  var currentString = ""
  
  var hasIPart: Bool {
    return !currentString.isEmpty
  }
  
  var hasPoint = false
  
  func consume(char: Character) {
    guard !isComplete else {
      isValid = false
      return
    }
    if char.isWholeNumber {
      currentString.append(char)
      return
    }
    if char == ".",
      hasIPart,
      !hasPoint {
      currentString.append(char)
      hasPoint = true
      return
    }
    if char == "f",
      hasIPart {
      currentString.append(char)
      isComplete = true
      return
    }
    isValid = false
  }
  
  func emitToken() throws -> Tokenizable {
    guard let currentFloat = Float(currentString) else {
      throw "Token is not a float literal"
    }
    return LiteralToken(type: .float(currentFloat))
  }
  
  func reset() {
    currentString = ""
    hasPoint = false
    isComplete = false
    isValid = true
  }
}
