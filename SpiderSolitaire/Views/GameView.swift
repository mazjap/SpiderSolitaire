import SwiftUI

struct GameView: View {
  @State private var model: GameViewModel
  @State private var draggingColumn: Int?
  @State private var cardStackFrames = [Int : CGRect]()
  @Namespace private var namespace
  private let backgroundColor = Color.green.mix(with: .black, by: 0.2)
  private let cardShape = RoundedRectangle(cornerRadius: 4)
  
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
                  .transition(.scale)
              } else {
                CardStackView(cards: cards, frames: $cardStackFrames, columnIndex: columnNum, cardWidth: cardWidth, cardHeight: cardHeight, namespace: namespace) {
                  draggingColumn = columnNum
                } onDragEnd: { draggingCardIndex, offset in
                  if let moveToColumnIndex = cardStackFrames.first(where: { $0.value.contains(offset) })?.key {
                    withAnimation {
                      model.moveCards(fromColumn: columnNum, cardIndex: draggingCardIndex, toColumn: moveToColumnIndex)
                    }
                    return false
                  }
                  return true
                }
                .zIndex(draggingColumn == columnNum ? 1 : 0)
              }
            }
            .transition(.offset(.zero))
          }
          .frame(height: cardHeight)
          
          Spacer()
          
          controls
        }
        .padding(.horizontal, outerHorizontalPadding)
      }
    }
    .onAppear {
      onGameStart()
    }
  }
}

// MARK: - Additional Views
extension GameView {
  private var stats: some View {
    HStack {
      // TODO: - Implement Score
      Text("Score\n0")
      
      Spacer()
      
      Text("Time\n\(model.formattedTime)")
      
      Spacer()
      
      Text("Moves\n\(model.state.moves)")
    }
    .multilineTextAlignment(.center)
    .monospaced()
    .foregroundStyle(.white)
    .padding(.horizontal, 20)
  }
  
  private var controls: some View {
    HStack {
      Text("1")
      Text("2")
      
      Button("Print frames") {
        print(cardStackFrames)
      }
      
      Text("3")
      Text("4")
    }
    .foregroundStyle(.white)
  }
}

// MARK: - View Functions
extension GameView {
  private func completedSets(width: Double, height: Double) -> some View {
    let subsequentCardOffset: Double = 30
    
    return ZStack {
      ForEach(Array(model.state.completedSets.enumerated()), id: \.element.id) { (index, set) in
        CardView(for: .completedSet(set), width: width, height: height, namespace: namespace)
          .offset(x: subsequentCardOffset * Double(index))
      }
    }
    .frame(height: height)
  }
  
  private func drawStack(width: Double, height: Double) -> some View {
    let subsequentCardOffset: Double = 4
    
    return ZStack {
      ForEach(Array(model.state.draws.enumerated()), id: \.element.id) { (index, set) in
        CardView(for: .hidden, width: width, height: height, namespace: namespace)
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

extension GameView {
  private func onGameStart() {
    model.revealTopCardsInAllColumns()
  }
}

#Preview {
  var gameState = GameState(suits: .oneSuit)
  gameState.completedSets = [
    //    CompletedSet(suit: .heart),
    //    CompletedSet(suit: .heart),
    //    CompletedSet(suit: .club),
    //    CompletedSet(suit: .club),
    //    CompletedSet(suit: .diamond),
    //    CompletedSet(suit: .diamond),
    //    CompletedSet(suit: .spade),
    //    CompletedSet(suit: .spade)
  ]
  
  //  gameState.seconds = Int(60.0 * 59.99)
  
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
