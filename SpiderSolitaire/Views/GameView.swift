import SwiftUI

struct GameView: View {
  @State private var model: GameViewModel
  @State private var draggingColumn: Int?
  @State private var cardStackFrames = [CGRect](repeating: .zero, count: 10)
  @State private var drawStackFrame = CGRect.zero
  @State private var completedSetsFrame = CGRect.zero
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
                do {
                  let draw = try model.popDraw()
                  // Use a slight delay to allow the view to update
                  Task {
                    var indices: [Int]?
                    
                    withAnimation {
                      indices = model.apply(draw: draw)
                    } completion: {
                      Task {
                        model.makeCardsVisible(at: indices ?? [])
                        try? await Task.sleep(for: .seconds(0.3))
                        // TODO: - Now check for completed sets
                        withAnimation {
                          for i in 0..<10 {
                            model.checkForCompletedSet(forColumn: i)
                          }
                        }
                      }
                      
                    }
                  }
                } catch {
                  print(error)
                }
              }
          }
          
          Spacer()
            .frame(height: 10)
          
          HStack(spacing: interCardSpacing) {
            cards(width: cardWidth, height: cardHeight)
          }
          .frame(height: cardHeight)
          
          Spacer()
          
          controls
        }
        .padding(.horizontal, outerHorizontalPadding)
        
        CardAnimationLayer(
          state: model.animationLayerState,
          cardStackFrames: cardStackFrames,
          drawStackFrame: drawStackFrame,
          completedSetsFrame: completedSetsFrame
        )
        .ignoresSafeArea()
        
        Rectangle()
          .fill(.clear)
          .stroke(Color.red, lineWidth: 4)
          .frame(width: drawStackFrame.width, height: drawStackFrame.height)
          .position(x: drawStackFrame.midX, y: drawStackFrame.midY)
          .ignoresSafeArea()
        
        Rectangle()
          .fill(.clear)
          .stroke(Color.purple, lineWidth: 4)
          .frame(width: completedSetsFrame.width, height: completedSetsFrame.height)
          .position(x: completedSetsFrame.midX, y: completedSetsFrame.midY)
          .ignoresSafeArea()
      }
    }
    .namespace(namespace)
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
            CardView(for: .hidden, width: width, height: height, isUsable: true)
              .rotationEffect(.degrees(20))
              .offset(x: width / 3)
            
            CardView(for: .hidden, width: width, height: height, isUsable: true)
              .rotationEffect(.degrees(-20))
              .offset(x: -width / 3)
            
            CardView(for: .hidden, width: width, height: height, isUsable: true)
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
          model.popPreviousMoveAndApply { completion in
            withAnimation {
              completion()
            }
          }
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
    
    return GeometryReader { geometry in
      ZStack {
        ForEach(Array(model.state.completedSets.enumerated()), id: \.element.id) { (index, set) in
          CardView(for: .completedSet(set), width: width, height: height, isUsable: true)
            .offset(x: subsequentCardOffset * Double(index))
        }
      }
      .onChange(of: model.state.completedSets, initial: true) {
        completedSetsFrame = geometry.frame(in: .global)
      }
    }
    .frame(
      width: width + (subsequentCardOffset * Double(max(0, model.completedSetCount - 1))),
      height: height)
  }
  
  private func drawStack(width: Double, height: Double) -> some View {
    let subsequentCardOffset: Double = 8
    let maxWidth = width + (subsequentCardOffset * Double(max(0, model.drawCount - 1)))
    
    return GeometryReader { geometry in
      ZStack {
        ForEach(Array(model.state.draws.enumerated()), id: \.element.id) { (index, set) in
          CardView(for: .hidden, width: width, height: height, isUsable: true)
            .offset(x: (maxWidth - width) / 2 - subsequentCardOffset * Double(index))
        }
      }
      .frame(
        width: maxWidth,
        height: height
      )
      .onChange(of: model.state.draws, initial: true) {
        drawStackFrame = geometry.frame(in: .global)
      }
    }
    .frame(
      width: maxWidth,
      height: height
    )
  }
  
  private func cards(width: Double, height: Double) -> some View {
    ForEach(Array($cardStackFrames.enumerated()), id: \.offset) { (columnNum, frame) in
      let cardStack = model[columnNum]
      
      CardStackView(cardStack: cardStack, frame: frame, cardWidth: width, cardHeight: height) {
        draggingColumn = columnNum
      } onDragEnd: { draggingCardIndex, frame in
        let shouldAnimateReturn: Bool
        
        let bestSharedArea = cardStackFrames.enumerated()
          .filter { $0.offset != columnNum }
          .map { (key: $0.offset, value: $0.element.sharedArea(with: frame)) }
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
}

extension GameView {
  private func onGameStart() {
    model.revealTopCardsInAllColumns()
    model.validateAllColumns()
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
  
//  gameState.column1 = CardStack(cards: [Card.Value.four, Card.Value.three, Card.Value.two, Card.Value.ace].map { Card(value: $0, suit: .diamond, isVisible: true) } + Array(Card.Value.allCases).reversed().dropLast().map {
//    Card(value: $0, suit: .club, isVisible: true)
//  }, validityIndex: 0)
//  gameState.column2 = CardStack(cards: [Card(value: .ace, suit: .club, isVisible: true)], validityIndex: 0)
//  
//  gameState.column3 = CardStack(cards: Array(Card.Value.allCases).reversed().dropLast().map {
//    Card(value: $0, suit: .random, isVisible: true)
//  }, validityIndex: 0)
//  gameState.column4 = CardStack(cards: [Card(value: .ace, suit: .club, isVisible: true)], validityIndex: 0)
  
  gameState.column1 = CardStack(
    cards: Array(Card.Value.allCases).reversed().dropLast().map {
    Card(value: $0, suit: .club, isVisible: true)
  }, validityIndex: 0)
  gameState.column2 = CardStack(
    cards: Array(Card.Value.allCases).reversed().dropLast().map {
    Card(value: $0, suit: .club, isVisible: true)
  }, validityIndex: 0)
  gameState.column3 = CardStack(
    cards: Array(Card.Value.allCases).reversed().dropLast().map {
    Card(value: $0, suit: .club, isVisible: true)
  }, validityIndex: 0)
  gameState.column4 = CardStack(
    cards: Array(Card.Value.allCases).reversed().dropLast().map {
    Card(value: $0, suit: .club, isVisible: true)
  }, validityIndex: 0)
  gameState.column5 = CardStack(
    cards: Array(Card.Value.allCases).reversed().dropLast().map {
    Card(value: $0, suit: .club, isVisible: true)
  }, validityIndex: 0)
  gameState.column6 = CardStack(
    cards: Array(Card.Value.allCases).reversed().dropLast().map {
    Card(value: $0, suit: .club, isVisible: true)
  }, validityIndex: 0)
  gameState.column7 = CardStack(
    cards: Array(Card.Value.allCases).reversed().dropLast().map {
    Card(value: $0, suit: .club, isVisible: true)
  }, validityIndex: 0)
  gameState.column8 = CardStack(
    cards: Array(Card.Value.allCases).reversed().dropLast().map {
    Card(value: $0, suit: .club, isVisible: true)
  }, validityIndex: 0)
  gameState.column9 = CardStack(
    cards: Array(repeating: Card.Value.ace, count: 8).map {
    Card(value: $0, suit: .club, isVisible: true)
  }, validityIndex: 0)
  gameState.column10 = CardStack(cards: [], validityIndex: -1)
  
  gameState.seconds = Int(60.0 * 59.99)
  
  return GameView(gameState: gameState)
}
