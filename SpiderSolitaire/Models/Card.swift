import Foundation

struct Card: Hashable, Identifiable {
  let value: Value
  let suit: Suit
  let id: UUID
  var isVisible: Bool
  
  init(value: Value, suit: Suit, id: UUID = UUID(), isVisible: Bool = false) {
    self.value = value
    self.suit = suit
    self.id = id
    self.isVisible = isVisible
  }
}

extension Card: CustomStringConvertible, CustomDebugStringConvertible {
  var description: String {
    "\(isVisible ? "Visible" : "Hidden") \(value.rawValue) of \(suit.rawValue)s"
  }
  
  var debugDescription: String {
    "\(description). ID: \(id)"
  }
}

extension Card {
  enum Value: String, CaseIterable {
    case ace
    case two
    case three
    case four
    case five
    case six
    case seven
    case eight
    case nine
    case ten
    case jack
    case queen
    case king
    
    var larger: Value? {
      switch self {
      case .ace: .two
      case .two: .three
      case .three: .four
      case .four: .five
      case .five: .six
      case .six: .seven
      case .seven: .eight
      case .eight: .nine
      case .nine: .ten
      case .ten: .jack
      case .jack: .queen
      case .queen: .king
      case .king: nil
      }
    }
  }
  
  enum Suit: String, CaseIterable {
    case heart
    case diamond
    case spade
    case club
  }
}

// Useful for debugging/testing
extension Card.Value {
  static var random: Card.Value {
    switch Int.random(in: 0..<13) {
    case 0: .ace
    case 1: .two
    case 2: .three
    case 3: .four
    case 4: .five
    case 5: .six
    case 6: .seven
    case 7: .eight
    case 8: .nine
    case 9: .ten
    case 10: .jack
    case 11: .queen
    default: .king
    }
  }
}

extension Card.Suit {
  static var random: Card.Suit {
    switch Int.random(in: 0..<3) {
    case 0: .heart
    case 1: .diamond
    case 2: .spade
    default: .club
    }
  }
}
