import SwiftUI

struct CardView: View {
  @State private var flipRotation: Double
  @State private var isVisuallyFlipped: Bool
  
  private let cardData: CardData
  private let width: Double
  private let height: Double
  private let namespace: Namespace.ID
  
  private let cardShape: RoundedRectangle
  private let textFontSize: Double
  private let imageFontSize: Double
  private let horizontalBottomPadding: Double
  private let strokeWidth: Double
  
  init(for cardData: CardData, width: Double, height: Double, namespace: Namespace.ID) {
    self.isVisuallyFlipped = cardData.card.isVisible
    self.flipRotation = cardData.card.isVisible ? 180 : 0
    
    self.cardData = cardData
    self.width = width
    self.height = height
    self.namespace = namespace
    
    let minDimension = min(width, height)
    
    self.cardShape = RoundedRectangle(cornerRadius: minDimension / 10)
    self.textFontSize = height / 4.5
    self.imageFontSize = height / 5
    self.horizontalBottomPadding = minDimension / 15
    self.strokeWidth = max(1, minDimension / 30)
  }
  
  init(for card: Card, width: Double, height: Double, namespace: Namespace.ID) {
    self.init(for: .card(card), width: width, height: height, namespace: namespace)
  }
  
  var body: some View {
    Group {
      if isVisuallyFlipped {
        faceUp
      } else {
        faceDown
      }
    }
    .rotation3DEffect(.degrees(flipRotation - (isVisuallyFlipped ? 180 : 0)), axis: (x: 0, y: 1, z: 0))
    .transition(.offset(.zero))
    .matchedGeometryEffect(id: cardData.card.id, in: namespace)
    .onChange(of: cardData.card.isVisible) {
      flipCard()
    }
  }
  
  @ViewBuilder
  private var faceUp: some View {
    let card = cardData.card
    
    let cardContentColor: Color =
    switch card.suit {
    case .heart, .diamond: .red
    case .spade, .club: .black
    }
    
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
  }
  
  @ViewBuilder
  private var faceDown: some View {
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
  
  private func flipCard() {
    withAnimation(.linear(duration: 0.15)) {
      flipRotation += 90
    } completion: {
      isVisuallyFlipped.toggle()
      withAnimation(.linear(duration: 0.15)) {
        flipRotation += 90
      }
    }
  }
}

#Preview {
  @Previewable @Namespace var namespace
  @Previewable @State var flippableCard = Card(value: .ten, suit: .spade, isVisible: false)
  
  VStack(spacing: 6) {
    let width: Double = 70
    let height: Double = 105
    
    HStack(spacing: 6) {
      ForEach(Card.Suit.allCases, id: \.rawValue) { suit in
        VStack(spacing: 6) {
          CardView(for: Card(value: .ace, suit: suit), width: width, height: height, namespace: namespace)
          CardView(for: Card(value: .king, suit: suit, isVisible: true), width: width, height: height, namespace: namespace)
          CardView(for: Card(value: .queen, suit: suit, isVisible: true), width: width, height: height, namespace: namespace)
          CardView(for: Card(value: .jack, suit: suit, isVisible: true), width: width, height: height, namespace: namespace)
          CardView(for: Card(value: .ace, suit: suit, isVisible: true), width: width, height: height, namespace: namespace)
        }
      }
    }
    
    HStack {
      CardView(for: flippableCard, width: width, height: height, namespace: namespace)
      
      Button("Flip card") {
        flippableCard.isVisible.toggle()
      }
    }
  }
}
