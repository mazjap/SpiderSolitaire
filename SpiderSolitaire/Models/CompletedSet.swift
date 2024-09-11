import Foundation

struct CompletedSet: Equatable, Identifiable {
  var suit: Card.Suit
  var id: UUID
  
  init(suit: Card.Suit, id: UUID = UUID()) {
    self.suit = suit
    self.id = id
  }
}
