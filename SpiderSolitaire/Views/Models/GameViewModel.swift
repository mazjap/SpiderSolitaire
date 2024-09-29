import Foundation
import Combine

enum AnimationLayerDrawAction {
  case `do`([Card])
  case undo([Card])
}

enum AnimationLayerCompleteSetAction {
  case `do`([Card])
  case undo([Card], index: Int)
}

enum CardActionError: Error {
  case noDrawsAvailable
  case noPreviousMovesAvailable
  case attemptedDrawButNoCardsOnStack(index: Int)
}

struct AnimationLayerState {
  var drawAction: AnimationLayerDrawAction?
  var completedSetAction: AnimationLayerCompleteSetAction?
  var drawCount: Int
  var completedSetCount: Int
}

@MainActor
@Observable
class GameViewModel {
  // MARK: - Storage
  private(set) var state: GameState
  private let initialTime: Int
  private var elapsedTime: Int = 0
  @ObservationIgnored
  nonisolated(unsafe) private var timerCancellable: AnyCancellable?
  private let timerLock = NSLock()
  private var hintsForHashValue: (hash: Int, [Move])?
  private var animationLayerDraw: AnimationLayerDrawAction?
  private var animationLayerCompletedSet: AnimationLayerCompleteSetAction?
  
  var drawCount: Int {
    state.draws.count
  }
  
  var completedSetCount: Int {
    state.completedSets.count
  }
  
  var animationLayerState: AnimationLayerState {
    AnimationLayerState(drawAction: animationLayerDraw, completedSetAction: animationLayerCompletedSet, drawCount: drawCount, completedSetCount: completedSetCount)
  }
  
  private let formatter: DateComponentsFormatter = {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.minute, .second]
    formatter.unitsStyle = .positional
    formatter.zeroFormattingBehavior = .pad
    return formatter
  }()
  
  init(state: GameState) {
    self.state = state
    self.initialTime = state.seconds
    
    updateFormatter()
  }
  
  deinit {
    stopTimerInternal()
  }
}

// MARK: - State mutating functions
extension GameViewModel {
  func revealTopCardsInAllColumns() {
    state.mutateColumns { column in
      guard !column.cards.isEmpty else { return }
      column.cards[column.cards.count - 1].isVisible = true
    }
  }
  
  func validateAllColumns() {
    for columnIndex in 0..<10 {
      validateIndex(forColumn: columnIndex)
    }
  }
  
  func moveCards(fromColumn source: Int, cardIndex: Int, toColumn destination: Int) -> Bool {
    let cardsToMove = state[source].cards[cardIndex...]
    let cardsToMoveCount = cardsToMove.count
    
    guard state[destination].cards.last == nil || state[destination].cards.last?.value == cardsToMove.first?.value.larger else { return true }
    
    state[source].cards.removeSubrange(cardIndex..<cardsToMove.endIndex)
    state[destination].cards.append(contentsOf: cardsToMove)
    
    var didRevealCard = false
    
    if !state[source].isEmpty {
      didRevealCard = !state[source].cards[state[source].cards.count - 1].isVisible
      state[source].cards[state[source].cards.count - 1].isVisible = true
    }
    
    validateIndex(forColumn: source)
    validateIndex(forColumn: destination)
    
    state.previousMoves.append(.move(columnIndex: UInt8(source), cardCount: UInt8(cardsToMoveCount), destinationIndex: UInt8(destination), didRevealCard: didRevealCard))
    
    checkForCompletedSet(forColumn: source)
    checkForCompletedSet(forColumn: destination)
    
    incrementMoves()
    return false
  }
  
  func startTimer() {
    guard timerCancellable == nil else { return }
    
    timerLock.lock()
    defer { timerLock.unlock()}
    
    // FIXME: - Replace `unowned` with `weak` if timer is ever used elsewhere
    timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
      .autoconnect()
      .sink { [unowned self] _ in
        self.elapsedTime += 1
        self.state.seconds = self.initialTime + self.elapsedTime
        
        self.updateFormatter()
      }
  }
  
  func stopTimer() {
    // `stopTimerInternal` can be called from any context
    // and should only be used by deinit, hence, private.
    // All other uses should be from @MainActor
    stopTimerInternal()
  }
  
  nonisolated
  private func stopTimerInternal() {
    timerLock.lock()
    defer { timerLock.unlock() }
    timerCancellable?.cancel()
    timerCancellable = nil
  }
  
  func popDraw() throws -> Draw {
    guard let draw = state.draws.popLast() else {
      throw CardActionError.noDrawsAvailable
    }
    
    animationLayerDraw = .do(draw.cards)
    
    return draw
  }
  
  func apply(draw: Draw) -> [Int] {
    // Animation step 1, remove from view hierarchy
    animationLayerDraw = nil
    
    // Animation step 2, add somewhere else in the view hierarchy.
    // MatchedGeometryEffect will handle the rest
    var indices = [Int](repeating: 0, count: 10)
    
    state.mutateColumns { column, index in
      indices[index] = column.cards.count
      column.cards.append(draw[index])
    }
    
    state.previousMoves.append(.draw(id: draw.id))
    incrementMoves()
    
    validateAllColumns()
    
    return indices
  }
  
  func makeCardsVisible(at indices: [Int]) {
    for (columnIndex, cardIndex) in indices.enumerated() {
      self[columnIndex][cardIndex].isVisible = true
    }
  }
  
  func popPreviousMoveAndApply(onCompletion: @escaping (() -> Void) -> Void) {
    switch state.previousMoves.popLast() {
    case .draw(let id):
      let defaultCard = Card(value: .ace, suit: .diamond)
      var draw = Draw(column1: defaultCard, column2: defaultCard, column3: defaultCard, column4: defaultCard, column5: defaultCard, column6: defaultCard, column7: defaultCard, column8: defaultCard, column9: defaultCard, column10: defaultCard, id: id)
      
      state.mutateColumns { stack, index in
        guard let card = stack.cards.popLast() else { return }
        draw[index] = card
      }
      animationLayerDraw = .undo(draw.cards)
      
      state.draws.append(draw)
      
      for i in 0..<10 {
        validateIndex(forColumn: i)
      }
      
      onCompletion {
        animationLayerDraw = nil
      }
    case let .move(newDestination, cardCount, newSource, shouldHideCard):
      let cardIndex = state[newSource].count - Int(cardCount)
      let cardsToMove = state[newSource].cards[cardIndex...]
      
      state[newSource].cards.removeSubrange(cardIndex..<cardsToMove.endIndex)
      
      if shouldHideCard, !state[newDestination].isEmpty {
        state[newDestination].cards[state[newDestination].cards.count - 1].isVisible = false
      }
      
      state[newDestination].cards.append(contentsOf: cardsToMove)
      
      validateIndex(forColumn: Int(newSource))
      validateIndex(forColumn: Int(newDestination))
    case let .completedSet(columnIndex, shouldHideCard): // Should not increment move count, just pop another move
      guard let completedSet = state.completedSets.popLast() else { return }
      if shouldHideCard, !state[columnIndex].isEmpty {
        state[columnIndex].cards[state[columnIndex].cards.count - 1].isVisible = false
      }
      
      let cards = Card.Value.allCases.reversed().map { Card(value: $0, suit: completedSet.suit, isVisible: true) }
      
      animationLayerCompletedSet = .undo(cards, index: Int(columnIndex))
      
      onCompletion {
        state[columnIndex].cards.append(contentsOf: cards)
        animationLayerCompletedSet = nil
      }
      popPreviousMoveAndApply(onCompletion: onCompletion)
      return
    case .none: return
    }
    
    incrementMoves()
  }
  
  func checkForCompletedSet(forColumn columnIndex: Int) {
    guard self[columnIndex].count >= 13,
          let last = self[columnIndex].cards.last,
          last.value == .ace
    else { return }
    
    let suit = last.suit
    var lastValue = last.value
    
    for card in self[columnIndex].cards.dropLast().reversed() where card.isVisible {
      guard card.isVisible,
            card.value == lastValue.larger,
            card.suit == last.suit
      else { break }
      
      lastValue = card.value
    }
    
    guard lastValue == .king else { return }
    
    let completedCards = self[columnIndex].cards.suffix(13)
    self[columnIndex].cards.removeLast(13)
    
    animationLayerCompletedSet = .do(Array(completedCards))
    
    // Use a completion handler to finalize the set completion
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
      guard let self = self else { return }
      self.animationLayerCompletedSet = nil
      self.state.completedSets.append(CompletedSet(suit: suit))
      
      var didRevealCard = false
      
      if !self.state[columnIndex].isEmpty {
        didRevealCard = !self.state[columnIndex].cards[self.state[columnIndex].cards.count - 1].isVisible
        self.state[columnIndex].cards[self.state[columnIndex].cards.count - 1].isVisible = true
      }
      
      self.state.previousMoves.append(.completedSet(columnIndex: UInt8(columnIndex), didRevealCard: didRevealCard))
      
      self.validateIndex(forColumn: columnIndex)
    }
  }
  
  private func validateIndex(forColumn columnIndex: Int) {
    guard let lastCard = self[columnIndex].cards.last else {
      self[columnIndex].validityIndex = -1
      return
    }
    
    for cardIndex in self[columnIndex].cards.indices.dropLast().reversed() {
      guard self[columnIndex][cardIndex].value == self[columnIndex][cardIndex + 1].value.larger,
            self[columnIndex][cardIndex].suit == lastCard.suit
      else {
        self[columnIndex].validityIndex = cardIndex + 1
        return
      }
    }
    
    self[columnIndex].validityIndex = 0
  }
  
  private func updateFormatter() {
    if state.seconds > 3600 {
      if !formatter.allowedUnits.contains(.hour) {
        formatter.allowedUnits.insert(.hour)
      }
    } else if formatter.allowedUnits.contains(.hour) {
      formatter.allowedUnits.remove(.hour)
    }
  }
  
  private func incrementMoves() {
    state.moveCount += 1
    startTimer()
  }
}

// MARK: - Computed Variables
extension GameViewModel {
  var formattedTime: String {
    formatter.string(from: DateComponents(second: Int(state.seconds))) ?? String(state.seconds)
  }
  
  var canUndo: Bool {
    !state.previousMoves.isEmpty
  }
}

// MARK: - Model Convenience
extension GameViewModel {
  subscript(column: UInt8) -> CardStack {
    get {
      return state[column]
    }
    set {
      state[column] = newValue
    }
  }
  
  subscript(column: Int) -> CardStack {
    get {
      self[UInt8(column)]
    } set {
      self[UInt8(column)] = newValue
    }
  }
}
