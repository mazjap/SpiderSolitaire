import SwiftUI

struct CardView: View {
  private let cardData: CardData
  private let width: Double
  private let height: Double
  private let cardShape = RoundedRectangle(cornerRadius: 4)
  
  init(for cardData: CardData, width: Double, height: Double) {
    self.cardData = cardData
    self.width = width
    self.height = height
  }
  
  init(for card: Card, width: Double, height: Double) {
    self.init(for: .card(card), width: width, height: height)
  }
  
  var body: some View {
    let card = cardData.card
    
    let cardContentColor: Color =
    switch card.suit {
    case .heart, .diamond: .red
    case .spade, .clover: .black
    }
    
    cardShape
      .fill(card.isVisible ? .white : .blue)
      .stroke(.black)
      .frame(width: width, height: height)
      .overlay {
        if card.isVisible {
          let numRep: String =
          switch card.value {
          case .ace: "A"
          case .two: "2"
          case .three: "3"
          case .four: "4"
          case .five: "5"
          case .six: "6"
          case .seven: "7"
          case .eight: "8"
          case .nine: "9"
          case .ten: "10"
          case .jack: "J"
          case .queen: "Q"
          case .king: "K"
          }
          
          Text("\(card.suit.rawValue.first!)\n\(numRep)")
            .multilineTextAlignment(.center)
            .foregroundStyle(cardContentColor)
        }
    }
  }
}
