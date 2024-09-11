import Foundation

struct CardStack: Equatable {
  var cards: [Card]
  var validityIndex: Int
  
  static let empty = CardStack(cards: [], validityIndex: .max)
}

// MARK: - Collection Convenience Methods & Properties
extension CardStack {
  subscript(index: Int) -> Card {
    get {
      cards[index]
    }
    set {
      cards[index] = newValue
    }
  }
  
  subscript(bounds: Range<Int>) -> ArraySlice<Card> {
    get {
      cards[bounds]
    }
    set {
      cards[bounds] = newValue
    }
  }
  
  var first: Card? {
    cards.first
  }
  
  var last: Card? {
    cards.last
  }
  
  var isEmpty: Bool {
    cards.isEmpty
  }
  
  var count: Int {
    cards.count
  }
}
