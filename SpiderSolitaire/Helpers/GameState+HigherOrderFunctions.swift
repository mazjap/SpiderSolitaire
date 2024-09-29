// Convenience
extension GameState {
  func forEachColumn(_ body: (CardStack) throws -> Void) rethrows {
    try forEachColumn { cardStack, _ in
      try body(cardStack)
    }
  }
  
  func forEachColumn(_ body: (CardStack, Int) throws -> Void) rethrows {
    try body(column1, 0)
    try body(column2, 1)
    try body(column3, 2)
    try body(column4, 3)
    try body(column5, 4)
    try body(column6, 5)
    try body(column7, 6)
    try body(column8, 7)
    try body(column9, 8)
    try body(column10, 9)
  }
  
  func mapColumns<T>(_ body: (CardStack) throws -> T) rethrows -> [T] {
    try mapColumns { cards, _ in
      try body(cards)
    }
  }
  
  func mapColumns<T>(_ body: (CardStack, Int) throws -> T) rethrows -> [T] {
    var result = [T]()
    result.reserveCapacity(10)
    
    try forEachColumn { stack, index in
      try result.append(body(stack, index))
    }
    
    return result
  }
  
  func reduceColumns<Result>(_ initialValue: Result, _ nextPartialResult: (Result, CardStack) throws -> Result) rethrows -> Result {
    try reduceColumns(initialValue) { result, cardStack, _ in
      try nextPartialResult(result, cardStack)
    }
  }
  
  @_disfavoredOverload
  mutating func reduceColumns<Result>(_ initialValue: Result, _ nextPartialResult: (Result, inout CardStack) throws -> Result) rethrows -> Result {
    try reduceColumns(initialValue) { result, cardStack, _ in
      try nextPartialResult(result, &cardStack)
    }
  }
  
  func reduceColumns<Result>(_ initialValue: Result, _ nextPartialResult: (Result, CardStack, Int) throws -> Result) rethrows -> Result {
    try reduceColumns(into: initialValue) { result, cardStack, cardStackIndex in
      result = try nextPartialResult(result, cardStack, cardStackIndex)
    }
  }
  
  @_disfavoredOverload
  mutating func reduceColumns<Result>(_ initialValue: Result, _ nextPartialResult: (Result, inout CardStack, Int) throws -> Result) rethrows -> Result {
    try reduceColumns(into: initialValue) { result, cardStack, cardStackIndex in
      result = try nextPartialResult(result, &cardStack, cardStackIndex)
    }
  }
  
  func reduceColumns<Result>(into initialResult: Result, _ updatingAccumulatingResult: (inout Result, CardStack) throws -> Void) rethrows -> Result {
    try reduceColumns(into: initialResult) { result, cardStack, _ in
      try updatingAccumulatingResult(&result, cardStack)
    }
  }
  
  @_disfavoredOverload
  mutating func reduceColumns<Result>(into initialResult: Result, _ updatingAccumulatingResult: (inout Result, inout CardStack) throws -> Void) rethrows -> Result {
    try reduceColumns(into: initialResult) { result, cardStack, _ in
      try updatingAccumulatingResult(&result, &cardStack)
    }
  }
  
  func reduceColumns<Result>(into initialResult: Result, _ updatingAccumulatingResult: (inout Result, CardStack, Int) throws -> Void) rethrows -> Result {
    var result = initialResult
    
    try forEachColumn { stack, index in
      try updatingAccumulatingResult(&result, stack, index)
    }
    
    return result
  }
  
  @_disfavoredOverload
  mutating func reduceColumns<Result>(into initialResult: Result, _ updatingAccumulatingResult: (inout Result, inout CardStack, Int) throws -> Void) rethrows -> Result {
    var result = initialResult
    
    try mutateColumns { stack, index in
      try updatingAccumulatingResult(&result, &stack, index)
    }
    
    return result
  }
}
