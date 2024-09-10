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
    case .spade, .club: .black
    }
    
    if card.isVisible {
      cardShape
        .fill(.white)
        .stroke(.black)
        .frame(width: width, height: height)
        .overlay {
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
          
          let image = Image(systemName: "suit.\(card.suit.rawValue).fill")
          
          VStack {
            HStack(spacing: 0) {
              Text("\(numRep)")
                .font(.system(size: 10))
              
              image
                .font(.system(size: 8))
              
              Spacer()
            }
            
            Spacer(minLength: 2)
            
            image
              .resizable()
              .scaledToFit()
            
            Spacer(minLength: 2)
            
            HStack(spacing: 0) {
              Spacer()
              
              Text("\(numRep)")
                .font(.system(size: 10))
              
              image
                .font(.system(size: 8))
            }
          }
          .multilineTextAlignment(.center)
          .foregroundStyle(cardContentColor)
          .padding(.horizontal, 2)
        }
    } else {
      ZStack {
        Color.white
        
        Image("card.back")
          .resizable()
          .scaledToFit()
          .foregroundStyle(Color.blue.mix(with: .white, by: 0.2))
        
        cardShape
          .stroke(.black)
      }
      .frame(width: width, height: height)
      .clipShape(cardShape)
    }
  }
}

#Preview {
  HStack {
    let width: Double = 30
    let height: Double = 45
    
    CardView(for: .hidden, width: width, height: height)
    
    CardView(for: .completedSet(CompletedSet(suit: .heart)), width: width, height: height)
    
    CardView(for: Card(value: .ace, suit: .club, isVisible: true), width: width, height: height)
  }
}
