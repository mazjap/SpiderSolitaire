import Foundation

struct GameState: Equatable {
  var completedSets: [CompletedSet]
  var draws: [Draw]
  
  var column1: [Card]
  var column2: [Card]
  var column3: [Card]
  var column4: [Card]
  var column5: [Card]
  var column6: [Card]
  var column7: [Card]
  var column8: [Card]
  var column9: [Card]
  var column10: [Card]
  
  var moves: Int = 0
  var seconds: Int = 0
  
  subscript(column: Int) -> [Card] {
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
  
  init(completedSets: [CompletedSet] = [], column1: [Card], column2: [Card], column3: [Card], column4: [Card], column5: [Card], column6: [Card], column7: [Card], column8: [Card], column9: [Card], column10: [Card], draws: [Draw]) {
    self.completedSets = completedSets
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
    self.draws = draws
  }
  
  init(suits: GameComplexity) {
    var fullDeck = Self.generateFullDeck(suits: suits)
    
    let column1: [Card] = Array(fullDeck.prefix(6))
    fullDeck.trimPrefix(column1)
    
    let column2: [Card] = Array(fullDeck.prefix(6))
    fullDeck.trimPrefix(column2)
    
    let column3: [Card] = Array(fullDeck.prefix(6))
    fullDeck.trimPrefix(column3)
    
    let column4: [Card] = Array(fullDeck.prefix(6))
    fullDeck.trimPrefix(column4)
    
    let column5: [Card] = Array(fullDeck.prefix(5))
    fullDeck.trimPrefix(column5)
    
    let column6: [Card] = Array(fullDeck.prefix(5))
    fullDeck.trimPrefix(column6)
    
    let column7: [Card] = Array(fullDeck.prefix(5))
    fullDeck.trimPrefix(column7)
    
    let column8: [Card] = Array(fullDeck.prefix(5))
    fullDeck.trimPrefix(column8)
    
    let column9: [Card] = Array(fullDeck.prefix(5))
    fullDeck.trimPrefix(column9)
    
    let column10: [Card] = Array(fullDeck.prefix(5))
    fullDeck.trimPrefix(column10)
    
    let draws: [Draw] = fullDeck.split(every: 10)
      .map { Array($0) }
      .map {
        Draw(column1: $0[0], column2: $0[1], column3: $0[2], column4: $0[3], column5: $0[4], column6: $0[5], column7: $0[6], column8: $0[7], column9: $0[8], column10: $0[9])
      }
    
    self.init(column1: column1, column2: column2, column3: column3, column4: column4, column5: column5, column6: column6, column7: column7, column8: column8, column9: column9, column10: column10, draws: draws)
  }
  
  static let empty = GameState(column1: [], column2: [], column3: [], column4: [], column5: [], column6: [], column7: [], column8: [], column9: [], column10: [], draws: [])
}

extension GameState {
  mutating func mutateColumns(_ mutate: (inout [Card]) -> Void) {
    mutateColumns { cards, _ in
      mutate(&cards)
    }
  }
  
  mutating func mutateColumns(_ mutate: (inout [Card], Int) -> Void) {
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
