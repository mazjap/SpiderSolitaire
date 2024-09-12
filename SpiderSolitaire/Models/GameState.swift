import Foundation

enum Move: Equatable {
  case draw(id: UUID)
  case move(columnIndex: UInt8, cardCount: UInt8, destinationIndex: UInt8, didRevealCard: Bool)
}

struct GameState: Equatable {
  var completedSets: [CompletedSet]
  var draws: [Draw]
  var previousMoves: [Move]
  
  var column1: CardStack
  var column2: CardStack
  var column3: CardStack
  var column4: CardStack
  var column5: CardStack
  var column6: CardStack
  var column7: CardStack
  var column8: CardStack
  var column9: CardStack
  var column10: CardStack
  
  var seconds: Int = 0
  var moveCount: Int = 0
  
  subscript(column: Int) -> CardStack {
    get {
      switch column {
      case 0: column1
      case 1: column2
      case 2: column3
      case 3: column4
      case 4: column5
      case 5: column6
      case 6: column7
      case 7: column8
      case 8: column9
      case 9: column10
      default: fatalError("Column index out of bounds")
      }
    }
    set {
      switch column {
      case 0: column1 = newValue
      case 1: column2 = newValue
      case 2: column3 = newValue
      case 3: column4 = newValue
      case 4: column5 = newValue
      case 5: column6 = newValue
      case 6: column7 = newValue
      case 7: column8 = newValue
      case 8: column9 = newValue
      case 9: column10 = newValue
      default: fatalError("Column index out of bounds")
      }
    }
  }
  
  init(completedSets: [CompletedSet] = [], column1: CardStack, column2: CardStack, column3: CardStack, column4: CardStack, column5: CardStack, column6: CardStack, column7: CardStack, column8: CardStack, column9: CardStack, column10: CardStack, draws: [Draw], previousMoves: [Move] = []) {
    self.completedSets = completedSets
    self.draws = draws
    self.previousMoves = previousMoves
    self.previousMoves.reserveCapacity(100)
    
    self.column1 = column1
    self.column2 = column2
    self.column3 = column3
    self.column4 = column4
    self.column5 = column5
    self.column6 = column6
    self.column7 = column7
    self.column8 = column8
    self.column9 = column9
    self.column10 = column10
  }
  
  init(suits: GameComplexity) {
    var fullDeck = Self.generateFullDeck(suits: suits)
    
    let column1 = CardStack(cards: Array(fullDeck.prefix(6)), validityIndex: .max)
    fullDeck.trimPrefix(column1.cards)
    
    let column2 = CardStack(cards: Array(fullDeck.prefix(6)), validityIndex: .max)
    fullDeck.trimPrefix(column2.cards)
    
    let column3 = CardStack(cards: Array(fullDeck.prefix(6)), validityIndex: .max)
    fullDeck.trimPrefix(column3.cards)
    
    let column4 = CardStack(cards: Array(fullDeck.prefix(6)), validityIndex: .max)
    fullDeck.trimPrefix(column4.cards)
    
    let column5 = CardStack(cards: Array(fullDeck.prefix(5)), validityIndex: .max)
    fullDeck.trimPrefix(column5.cards)
    
    let column6 = CardStack(cards: Array(fullDeck.prefix(5)), validityIndex: .max)
    fullDeck.trimPrefix(column6.cards)
    
    let column7 = CardStack(cards: Array(fullDeck.prefix(5)), validityIndex: .max)
    fullDeck.trimPrefix(column7.cards)
    
    let column8 = CardStack(cards: Array(fullDeck.prefix(5)), validityIndex: .max)
    fullDeck.trimPrefix(column8.cards)
    
    let column9 = CardStack(cards: Array(fullDeck.prefix(5)), validityIndex: .max)
    fullDeck.trimPrefix(column9.cards)
    
    let column10 = CardStack(cards: Array(fullDeck.prefix(5)), validityIndex: .max)
    fullDeck.trimPrefix(column10.cards)
    
    let draws: [Draw] = fullDeck.split(every: 10)
      .map { Array($0) }
      .map {
        Draw(column1: $0[0], column2: $0[1], column3: $0[2], column4: $0[3], column5: $0[4], column6: $0[5], column7: $0[6], column8: $0[7], column9: $0[8], column10: $0[9])
      }
    
    self.init(column1: column1, column2: column2, column3: column3, column4: column4, column5: column5, column6: column6, column7: column7, column8: column8, column9: column9, column10: column10, draws: draws)
  }
  
  static let empty = GameState(
    column1: .empty, column2: .empty,
    column3: .empty, column4: .empty,
    column5: .empty, column6: .empty,
    column7: .empty, column8: .empty,
    column9: .empty, column10: .empty,
    draws: []
  )
}

extension GameState {
  /// Mutates each column using the given closure
  /// - Parameter mutate: A closure used on each column with only a paramter, cardStack which acts agnostically on each column.
  mutating func mutateColumns(_ mutate: (inout CardStack) -> Void) {
    mutateColumns { cards, _ in
      mutate(&cards)
    }
  }
  
  /// Mutates each column using the given closure
  /// - Parameter mutate: A closure used on each column with the following parameters: cardStack - A `CardStack` struct which can be mutated. - index the index of the column being mutated
  mutating func mutateColumns(_ mutate: (inout CardStack, Int) -> Void) {
    mutate(&column1, 0)
    mutate(&column2, 1)
    mutate(&column3, 2)
    mutate(&column4, 3)
    mutate(&column5, 4)
    mutate(&column6, 5)
    mutate(&column7, 6)
    mutate(&column8, 7)
    mutate(&column9, 8)
    mutate(&column10, 9)
  }
  
  func mapColumns<T>(_ body: (CardStack) -> T) -> [T] {
    mapColumns { cards, _ in
      body(cards)
    }
  }
  
  func mapColumns<T>(_ body: (CardStack, Int) -> T) -> [T] {
    var result = [T]()
    result.reserveCapacity(10)
    
    result.append(body(column1, 0))
    result.append(body(column2, 1))
    result.append(body(column3, 2))
    result.append(body(column4, 3))
    result.append(body(column5, 4))
    result.append(body(column6, 5))
    result.append(body(column7, 6))
    result.append(body(column8, 7))
    result.append(body(column9, 8))
    result.append(body(column10, 9))
    
    return result
  }
}

extension GameState {
  enum GameComplexity {
    case oneSuit
    case twoSuits
    case fourSuits
  }
  
  static func generateFullDeck(suits: GameComplexity) -> [Card] {
    let deck1 = Card.Value.allCases.map { Card(value: $0, suit: .club) }
    let deck2 = Card.Value.allCases.map { Card(value: $0, suit: .club) }
    let deck3: [Card]
    let deck4: [Card]
    let deck5: [Card]
    let deck6: [Card]
    let deck7: [Card]
    let deck8: [Card]
    
    switch suits {
    case .oneSuit:
      deck3 = Card.Value.allCases.map { Card(value: $0, suit: .club) }
      deck4 = Card.Value.allCases.map { Card(value: $0, suit: .club) }
      deck5 = Card.Value.allCases.map { Card(value: $0, suit: .club) }
      deck6 = Card.Value.allCases.map { Card(value: $0, suit: .club) }
      deck7 = Card.Value.allCases.map { Card(value: $0, suit: .club) }
      deck8 = Card.Value.allCases.map { Card(value: $0, suit: .club) }
    case .twoSuits:
      deck3 = Card.Value.allCases.map { Card(value: $0, suit: .club, isVisible: false) }
      deck4 = Card.Value.allCases.map { Card(value: $0, suit: .club) }
      deck5 = Card.Value.allCases.map { Card(value: $0, suit: .heart) }
      deck6 = Card.Value.allCases.map { Card(value: $0, suit: .heart) }
      deck7 = Card.Value.allCases.map { Card(value: $0, suit: .heart) }
      deck8 = Card.Value.allCases.map { Card(value: $0, suit: .heart) }
    case .fourSuits:
      deck3 = Card.Value.allCases.map { Card(value: $0, suit: .heart) }
      deck4 = Card.Value.allCases.map { Card(value: $0, suit: .heart) }
      deck5 = Card.Value.allCases.map { Card(value: $0, suit: .spade) }
      deck6 = Card.Value.allCases.map { Card(value: $0, suit: .spade) }
      deck7 = Card.Value.allCases.map { Card(value: $0, suit: .diamond) }
      deck8 = Card.Value.allCases.map { Card(value: $0, suit: .diamond) }
    }
    
    return (deck1 + deck2 + deck3 + deck4 + deck5 + deck6 + deck7 + deck8).shuffled()
  }
}


extension GameState {
  subscript(column: UInt8) -> CardStack {
    get {
      self[Int(column)]
    }
    set {
      self[Int(column)] = newValue
    }
  }
}
