import Foundation

struct CompletedSet: Hashable, Identifiable {
  var suit: Card.Suit
  var id: UUID
  
  init(suit: Card.Suit, id: UUID = UUID()) {
    self.suit = suit
    self.id = id
  }
}
