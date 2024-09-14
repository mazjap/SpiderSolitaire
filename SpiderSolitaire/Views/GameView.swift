import SwiftUI

struct GameView: View {
  @State private var model: GameViewModel
  @State private var draggingColumn: Int?
  @State private var cardStackFrames = [Int : CGRect]()
  @State private var areNewGameOptionsShown = false
  @Namespace private var namespace
  @ScaledMetric private var controlImageSize = Double(30)
  
  private let backgroundColor = Color.green.mix(with: .black, by: 0.2)
  
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
              let cardStack = model[columnNum]
              
              CardStackView(cardStack: cardStack, frames: $cardStackFrames, columnIndex: columnNum, cardWidth: cardWidth, cardHeight: cardHeight, namespace: namespace) {
                draggingColumn = columnNum
              } onDragEnd: { draggingCardIndex, frame in
                let shouldAnimateReturn: Bool
                
                let bestSharedArea = cardStackFrames
                  .filter({ $0.key != columnNum })
                  .mapValues({
                    $0.sharedArea(with: frame)
                  })
                  .max(by: {
                    $0.value < $1.value
                  })
                
                if let bestSharedArea, bestSharedArea.value > 0.1, bestSharedArea.value <= 1 {
                  shouldAnimateReturn = withAnimation {
                    model.moveCards(fromColumn: columnNum, cardIndex: draggingCardIndex, toColumn: bestSharedArea.key)
                  }
                } else {
                  shouldAnimateReturn = true
                }
                
                return shouldAnimateReturn
              }
              .zIndex(draggingColumn == columnNum ? 1 : 0)
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
      
      Text("Moves\n\(model.state.moveCount)")
    }
    .multilineTextAlignment(.center)
    .monospaced()
    .foregroundStyle(.white)
    .padding(.horizontal, 20)
    .confirmationDialog("New Game Difficulty", isPresented: $areNewGameOptionsShown) {
      Button("One Suit") {
        model = GameViewModel(state: GameState(suits: .oneSuit))
        onGameStart()
      }
      Button("Two Suits") {
        model = GameViewModel(state: GameState(suits: .twoSuits))
        onGameStart()
      }
      Button("Four Suits") {
        model = GameViewModel(state: GameState(suits: .fourSuits))
        onGameStart()
      }
      
      Button("Cancel", role: .cancel) {}
    }
  }
  
  private var controls: some View {
    HStack {
      Button {
        // TODO: - Implement Settings (haptics, colors, default game mode, etc.)
      } label: {
        VStack {
          Image(systemName: "gear")
            .resizable()
            .scaledToFit()
            .frame(width: controlImageSize, height: controlImageSize)
          
          Text("Settings")
        }
      }
      .padding(.trailing, -8)
      
      Spacer()
      
      Button {
        // TODO: - Implement hints
      } label: {
        VStack {
          Image(systemName: "lightbulb.max.fill")
            .resizable()
            .scaledToFit()
            .frame(width: controlImageSize, height: controlImageSize)
            .foregroundStyle(.yellow)
          
          Text("Hint")
        }
      }
      
      Spacer()
      
      #if DEBUG
      Button {
        // Ugly but useful
        print("""
GameState(
  completedSets: \(model.state.completedSets.map { 
    "CompletedSet(suit: .\($0.suit.rawValue), id: UUID(uuidString: \($0.id.uuidString))!)"
  }), 
  \(model.state.mapColumns { stack, index in
          "column\(index + 1): CardStack(cards: [\n\(stack.cards.map { "Card(value: .\($0.value), suit: .\($0.suit), id: UUID(uuidString: \"\($0.id.uuidString)\")!, isVisible: \($0.isVisible))" }.joined(separator: ", \n"))], validityIndex: \(stack.validityIndex)), \n"
  }.joined())
  draws: [\(model.state.draws.map { draw in
    "Draw(" + (0..<10).map { "column\($0 + 1): Card(value: .\(draw[$0].value), suit: .\(draw[$0].suit), id: UUID(uuidString: \"\(draw[$0].id.uuidString)\")!, isVisible: \(draw[$0].isVisible))" }.joined(separator: ", \n") + ")"
  }.joined(separator: ", \n"))],
  previousMoves: [\(model.state.previousMoves.map {
    switch $0 {
    case let .draw(id):
      ".draw(id: UUID(uuidString: \"\(id.uuidString)\")!)"
    case let .move(columnIndex, cardCount, destinationIndex, didRevealCard):
      ".move(columnIndex: \(columnIndex), cardCount: \(cardCount), destinationIndex: \(destinationIndex), didRevealCard: \(didRevealCard))"
    case let .completedSet(columnIndex, didRevealCard):
      ".completedSet(columnIndex: \(columnIndex), didRevealCard: \(didRevealCard))"
    }
  }.joined(separator: ", \n"))]
)
""")
      } label: {
        VStack {
          Image(systemName: "ladybug.fill")
            .resizable()
            .scaledToFit()
            .frame(width: controlImageSize, height: controlImageSize)
          
          Text("Debug")
        }
      }
      
      Spacer()
      #endif
      
      Button {
        areNewGameOptionsShown.toggle()
      } label: {
        VStack {
          let width = controlImageSize * 0.75
          let height = controlImageSize
          ZStack {
            CardView(for: .hidden, width: width, height: height, isUsable: true, namespace: namespace)
              .rotationEffect(.degrees(20))
              .offset(x: width / 3)
            
            CardView(for: .hidden, width: width, height: height, isUsable: true, namespace: namespace)
              .rotationEffect(.degrees(-20))
              .offset(x: -width / 3)
            
            CardView(for: .hidden, width: width, height: height, isUsable: true, namespace: namespace)
              .offset(y: -width / 10)
          }
          .frame(width: height, height: height)
          .offset(y: width / 10)
          
          Text("Play")
        }
      }
      
      Spacer()
      
      Button {
        withAnimation {
          model.popPreviousMoveAndApply()
        }
      } label: {
        VStack {
          Image(systemName: "arrow.uturn.backward")
            .resizable()
            .scaledToFit()
            .frame(width: controlImageSize, height: controlImageSize)
          
          Text("Undo")
        }
        .foregroundStyle(model.canUndo ? .white : .gray)
      }
    }
    .lineLimit(1)
    .minimumScaleFactor(0.1)
    .foregroundStyle(.white)
    .padding(.top, 8)
    .padding(.bottom, 4)
    .padding(.horizontal, 20)
    .background {
      RoundedRectangle(cornerRadius: 10)
        .fill(Color.black.opacity(0.5))
    }
    .padding(.horizontal, 25)
  }
}

// MARK: - View Functions
extension GameView {
  private func completedSets(width: Double, height: Double) -> some View {
    let subsequentCardOffset: Double = 30
    
    return ZStack {
      ForEach(Array(model.state.completedSets.enumerated()), id: \.element.id) { (index, set) in
        CardView(for: .completedSet(set), width: width, height: height, isUsable: true, namespace: namespace)
          .offset(x: subsequentCardOffset * Double(index))
      }
    }
    .frame(height: height)
  }
  
  private func drawStack(width: Double, height: Double) -> some View {
    let subsequentCardOffset: Double = 4
    
    return ZStack {
      ForEach(Array(model.state.draws.enumerated()), id: \.element.id) { (index, set) in
        CardView(for: .hidden, width: width, height: height, isUsable: true, namespace: namespace)
          .offset(x: -subsequentCardOffset * Double(index))
      }
    }
    .frame(height: height)
  }
}

extension GameView {
  private func onGameStart() {
    model.revealTopCardsInAllColumns()
  }
}

#Preview {
  var gameState = GameState(suits: .oneSuit)
//  gameState.completedSets = [
//    CompletedSet(suit: .heart),
//    CompletedSet(suit: .heart),
//    CompletedSet(suit: .club),
//    CompletedSet(suit: .club),
//    CompletedSet(suit: .diamond),
//    CompletedSet(suit: .diamond),
//    CompletedSet(suit: .spade),
//    CompletedSet(suit: .spade)
//  ]
  
  gameState.column1 = CardStack(cards: Array(Card.Value.allCases).reversed().dropLast().map {
    Card(value: $0, suit: .club, isVisible: true)
  }, validityIndex: 0)
  gameState.column2 = CardStack(cards: [Card(value: .ace, suit: .club, isVisible: true)], validityIndex: 0)
  
  gameState.seconds = Int(60.0 * 59.99)
  
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
