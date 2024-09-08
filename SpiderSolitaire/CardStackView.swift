import SwiftUI

class OffsetCounter {
  private(set) var offset: Double = 0
  private var wasLastVisible: Bool = false
  
  func reset() {
    offset = 0
  }
  
  func increment(card: Card) {
    if wasLastVisible {
      offset += 5
    } else {
      offset += 3
    }
    
    wasLastVisible = card.isVisible
  }
}

struct CardStackView: View {
  private let cards: [Card]
  private let cardWidth: Double
  private let cardHeight: Double
  
  private let offsetCounter = OffsetCounter()
  
  init(cards: [Card], cardWidth: Double, cardHeight: Double) {
    self.cards = cards
    self.cardWidth = cardWidth
    self.cardHeight = cardHeight
  }
  
  var body: some View {
    ZStack {
      let _ = offsetCounter.reset()
      
      ForEach(Array(cards.enumerated()), id: \.element.id) { (index, card) in
        CardView(for: card, width: cardWidth, height: cardHeight)
          .offset(y: offsetCounter.offset)
        
        let _ = offsetCounter.increment(card: card)
      }
    }
  }
}
