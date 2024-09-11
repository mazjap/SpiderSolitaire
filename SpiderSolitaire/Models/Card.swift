import Foundation

struct Card: Hashable, Identifiable {
  let value: Value
  let suit: Suit
  let id: UUID = UUID()
  var isVisible: Bool = false
}

extension Card: CustomStringConvertible {
  var description: String {
    "\(isVisible ? "Visible" : "Hidden") \(value.rawValue) of \(suit.rawValue)s. ID: \(id)"
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
  }
  
  enum Suit: String, CaseIterable {
    case heart
    case diamond
    case spade
    case club
  }
}
