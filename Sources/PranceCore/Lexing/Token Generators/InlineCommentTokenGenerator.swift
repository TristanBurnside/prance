//
//  InlineCommentTokenGenerator.swift
//  PranceCore
//
//  Created by Tristan Burnside on 6/11/19.
//

import Foundation

class InlineCommentTokenGenerator: TokenGenerator {
  
  var isValid: Bool = true
  
  var isComplete: Bool = false
  
  var hasFirstSlash = false
  var hasSecondSlash = false
  
  func consume(char: Character) {
    if !hasFirstSlash {
      consumeFirst(char: char)
      return
    }
    if !hasSecondSlash {
      consumeSecond(char: char)
      return
    }
    consumeBody(char: char)
  }
  
  func emitToken() throws -> Tokenizable {
    return CommentToken()
  }
  
  func reset() {
    isValid = true
    isComplete = false
    hasFirstSlash = false
    hasSecondSlash = false
  }
  
  private func consumeFirst(char: Character) {
    if char == "/" {
      hasFirstSlash = true
    } else {
      isValid = false
    }
  }
  
  private func consumeSecond(char: Character) {
    if char == "/" {
      hasSecondSlash = true
      isComplete = true
    } else {
      isValid = false
    }
  }
  
  private func consumeBody(char: Character) {
    guard char != "\n" else {
      isValid = false
      return
    }
  }
}
