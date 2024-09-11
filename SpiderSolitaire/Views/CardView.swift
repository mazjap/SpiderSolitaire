import SwiftUI

struct CardView: View {
  private let cardData: CardData
  private let width: Double
  private let height: Double
  private let cardShape: RoundedRectangle
  private let textFontSize: Double
  private let imageFontSize: Double
  private let horizontalBottomPadding: Double
  private let strokeWidth: Double
  
  init(for cardData: CardData, width: Double, height: Double) {
    self.cardData = cardData
    self.width = width
    self.height = height
    
    let minDimension = min(width, height)
    
    self.cardShape = RoundedRectangle(cornerRadius: minDimension / 10)
    self.textFontSize = height / 4.5
    self.imageFontSize = height / 5
    self.horizontalBottomPadding = minDimension / 15
    self.strokeWidth = max(1, minDimension / 30)
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
        .stroke(.black, lineWidth: strokeWidth)
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
                .font(.system(size: textFontSize))
              
              Spacer(minLength: 0)
              
              image
                .font(.system(size: imageFontSize))
            }
            
            Spacer(minLength: 2)
            
            image
              .resizable()
              .scaledToFit()
          }
          .multilineTextAlignment(.center)
          .foregroundStyle(cardContentColor)
          .padding([.horizontal, .bottom], horizontalBottomPadding)
        }
    } else {
      ZStack {
        Color(red: 0.2, green: 0.6, blue: 1)
          .clipShape(cardShape)
          
        Image("card.back")
          .resizable()
          .scaledToFit()
          .foregroundStyle(.white)
          .padding(horizontalBottomPadding)
        
        cardShape
          .stroke(.black, lineWidth: strokeWidth)
      }
      .frame(width: width, height: height)
    }
  }
}

#Preview {
  VStack(spacing: 6) {
    let width: Double = 90
    let height: Double = 135
    
    HStack(spacing: 6) {
      ForEach(Card.Suit.allCases, id: \.rawValue) { suit in
        VStack(spacing: 6) {
          CardView(for: Card(value: .ace, suit: suit), width: width, height: height)
          CardView(for: Card(value: .king, suit: suit, isVisible: true), width: width, height: height)
          CardView(for: Card(value: .queen, suit: suit, isVisible: true), width: width, height: height)
          CardView(for: Card(value: .jack, suit: suit, isVisible: true), width: width, height: height)
          CardView(for: Card(value: .ace, suit: suit, isVisible: true), width: width, height: height)
        }
      }
    }
  }
}
