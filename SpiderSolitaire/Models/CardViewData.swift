enum CardData {
  case card(Card)
  case hidden
  case completedSet(CompletedSet)
  
  var card: Card {
    switch self {
    case .card(let card):
      return card
    case .hidden:
      return Card(value: .ace, suit: .club, isVisible: false)
    case .completedSet(let set):
      return Card(value: .king, suit: set.suit, isVisible: true)
    }
  }
}
