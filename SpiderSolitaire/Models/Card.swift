import Foundation

struct Card: Hashable, Identifiable {
  let value: Value
  let suit: Suit
  let id: UUID = UUID()
  var isVisible: Bool = false
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
