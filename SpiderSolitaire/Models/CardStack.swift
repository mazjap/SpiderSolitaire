import Foundation

struct CardStack: Equatable {
  var cards: [Card]
  var validityIndex: UInt8
  
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
  
  subscript(range: Range<Int>) -> ArraySlice<Card> {
    get {
      cards[range]
    }
    set {
      cards[range] = newValue
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
  
  func map<T>(_ transform: (Card) throws -> T) rethrows -> [T] {
    try cards.map(transform)
  }
  
  func forEach(_ body: (Card) throws -> Void) rethrows {
    try cards.forEach(body)
  }
  
  func reduce<T>(_ initial: T, _ nextPartialResult: (T, Card) throws -> T) rethrows -> T {
    try cards.reduce(initial, nextPartialResult)
  }
  
  mutating func removeSubrange(_ subrange: Range<Int>) {
    cards.removeSubrange(subrange)
  }
  
  mutating func append(_ newElement: Card) {
    cards.append(newElement)
  }
  
  mutating func append<Seq>(contentsOf newElements: Seq) where Seq: Sequence, Seq.Element == Card {
    cards.append(contentsOf: newElements)
  }
}
