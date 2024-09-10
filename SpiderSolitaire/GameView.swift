import SwiftUI

struct GameView: View {
  @State private var model: GameViewModel
  private let backgroundColor = Color.green.mix(with: .black, by: 0.2)
  private let cardShape = RoundedRectangle(cornerRadius: 4)
  
  private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
  private let outerHorizontalPadding: Double = 4
  private let interCardSpacing: Double = 5
  private var totalCardSpacing: Double { (10 - 1) * interCardSpacing }
  private var totalHorizontalPadding: Double {
    (outerHorizontalPadding * 2) + totalCardSpacing
  }
  
  init(gameState: GameState) {
    self.model = GameViewModel(state: gameState)
  }
  
  var body: some View {
    GeometryReader { geometry in
      let cardWidth = (geometry.size.width - totalHorizontalPadding) / 10
      let cardHeight = cardWidth * 1.5
      
      ZStack {
        backgroundColor
          .ignoresSafeArea()
        
        VStack {
          stats
          
          Spacer()
            .frame(height: 10)
          
          HStack {
            completedSets(width: cardWidth, height: cardHeight)
            
            Spacer()
            
            drawStack(width: cardWidth, height: cardHeight)
              .onTapGesture {
                model.popDrawAndApply()
              }
          }
          
          Spacer()
            .frame(height: 10)
          
          HStack(spacing: interCardSpacing) {
            ForEach(0..<10) { columnNum in
              let cards = model[columnNum]
              
              if cards.isEmpty {
                emptyColumn(width: cardWidth, height: cardHeight)
              } else {
                CardStackView(cards: cards, cardWidth: cardWidth, cardHeight: cardHeight) { card, offset in
                  print("\(card) \(offset)")
                }
              }
            }
          }
          .frame(height: cardHeight)
          
          Spacer()
          
          controls
        }
        .padding(.horizontal, outerHorizontalPadding)
      }
    }
    .onReceive(timer) { date in
      model.updateTime(from: date)
    }
  }
  
  private var stats: some View {
    HStack {
      Spacer()
      
      // TODO: - Implement Score
      Text("Score\n0")
      
      Spacer()
      
      Text("Time\n\(model.formattedTime)")
      
      Spacer()
      
      Text("Moves\n\(model.state.moves)")
      
      Spacer()
    }
    .multilineTextAlignment(.center)
    .foregroundStyle(.white)
  }
  
  private var controls: some View {
    HStack {
      Text("1")
      Text("2")
      Text("3")
      Text("4")
    }
    .foregroundStyle(.white)
  }
  
  private func completedSets(width: Double, height: Double) -> some View {
    let subsequentCardOffset: Double = 30
    
    return ZStack {
      ForEach(Array(model.state.completedSets.enumerated()), id: \.element.id) { (index, set) in
        CardView(for: .completedSet(set), width: width, height: height)
          .offset(x: subsequentCardOffset * Double(index))
      }
    }
    .frame(height: height)
  }
  
  private func drawStack(width: Double, height: Double) -> some View {
    let subsequentCardOffset: Double = 4
    
    return ZStack {
      ForEach(Array(model.state.draws.enumerated()), id: \.element.id) { (index, set) in
        CardView(for: .hidden, width: width, height: height)
          .offset(x: -subsequentCardOffset * Double(index))
      }
    }
    .frame(height: height)
  }
  
  private func emptyColumn(width: Double, height: Double) -> some View {
    cardShape
      .foregroundStyle(.white.opacity(0.2))
      .frame(width: width, height: height)
      .overlay {
        cardShape
          .stroke(Color.white, lineWidth: 2)
      }
  }
}

#Preview {
  var gameState = GameState(suits: .oneSuit)
  gameState.completedSets = [CompletedSet(suit: .heart), CompletedSet(suit: .club)]
  
  return GameView(gameState: gameState)
}

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
