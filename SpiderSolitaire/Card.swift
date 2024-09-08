import Foundation

struct Card: Hashable, Identifiable {
  let value: Value
  let suit: Suit
  let id: UUID = UUID()
  var isVisible: Bool = false
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
  
  enum Suit: String {
    case heart
    case diamond
    case spade
    case clover
  }
}
