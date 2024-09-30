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
  
  private let completedSetSpacing: Double = 30
  private let drawStackSpacing: Double = 8
  
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
                handleDrawFromStack()
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
          drawStackSpacing: drawStackSpacing,
          completedSetsFrame: completedSetsFrame,
          completedSetSpacing: completedSetSpacing
        )
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
        debugPrint(gameState: model.state)
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
        withAnimation(.linear(duration: 0.3)) {
          model.popPreviousMoveAndApply { completion in
            Task {
              try? await Task.sleep(for: .seconds(0.3))
              withAnimation(.linear(duration: 0.3)) {
                completion()
              }
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
    return GeometryReader { geometry in
      ZStack {
        ForEach(Array(model.state.completedSets.enumerated()), id: \.element.id) { (index, set) in
          CardView(for: .completedSet(set), width: width, height: height, isUsable: true)
            .offset(x: completedSetSpacing * Double(index))
        }
      }
      .onChange(of: model.state.completedSets, initial: true) {
        completedSetsFrame = geometry.frame(in: .global)
      }
    }
    .frame(
      width: width + (completedSetSpacing * Double(max(0, model.completedSetCount - 1))),
      height: height)
  }
  
  private func drawStack(width: Double, height: Double) -> some View {
    let maxWidth = width + (drawStackSpacing * Double(max(0, model.drawCount - 1)))
    
    return GeometryReader { geometry in
      ZStack {
        ForEach(Array(model.state.draws.enumerated()), id: \.element.id) { (index, set) in
          CardView(for: .hidden, width: width, height: height, isUsable: true)
            .offset(x: (maxWidth - width) / 2 - drawStackSpacing * Double(index))
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

// MARK: - Non-View Functions
extension GameView {
  private func handleDrawFromStack() {
    do {
      let draw = try model.popDraw()
      // Use a slight delay to allow the view to update
      Task {
        var indices: [Int]?
        
        withAnimation(.linear(duration: 0.3)) {
          indices = model.apply(draw: draw)
        }
        
        try await Task.sleep(for: .seconds(0.2))
        model.makeCardsVisible(at: indices ?? [])
        // Sleep for duration of `CardView` flip animation (0.3s)
        try? await Task.sleep(for: .seconds(0.3))
        
        withAnimation {
          for i in 0..<10 {
            model.checkForCompletedSet(forColumn: i)
          }
        }
      }
    } catch {
      print(error)
    }
  }
  
  private func onGameStart() {
    model.revealTopCardsInAllColumns()
    model.validateAllColumns()
  }
}

#Preview {
  return GameView(gameState: .almostCompletedSets)
}
