import SwiftUI

struct CardStackView: View {
  private let cards: [Card]
  private let cardWidth: Double
  private let cardHeight: Double
  private let offsets: [Double]
  private let onDragEnd: (Card, CGPoint) -> Void
  
  init(cards: [Card], cardWidth: Double, cardHeight: Double, onDragEnd: @escaping (Card, CGPoint) -> Void) {
    self.cards = cards
    self.cardWidth = cardWidth
    self.cardHeight = cardHeight
    
    self.onDragEnd = onDragEnd
    
    let visibleOffset = cardHeight / 4
    let hiddenOffset = cardHeight / 10
    
    var workingOffset: Double = 0
    
    self.offsets = cards.map {
      let offset = workingOffset
      
      if $0.isVisible {
        workingOffset += visibleOffset
      } else {
        workingOffset += hiddenOffset
      }
      
      return offset
    }
  }
  
  var body: some View {
    ZStack() {
      ForEach(Array(cards.enumerated()), id: \.element.id) { (index, card) in
        CardView(for: card, width: cardWidth, height: cardHeight)
          .offset(y: offsets[index])
      }
    }
  }
}

#Preview {
  @Previewable @State var cards = Card.Value.allCases.map { Card(value: $0, suit: .heart) }
  
  VStack {
    CardStackView(cards: cards, cardWidth: 30, cardHeight: 45) { card, offset in
      
    }
    
    Spacer()
    
    Button("Add Card") {
      cards.append(Card(value: Array(Card.Value.allCases).randomElement()!, suit: Array(Card.Suit.allCases).randomElement()!, isVisible: true))
    }
  }
  .onAppear {
    cards[cards.count - 1].isVisible = true
  }
}
