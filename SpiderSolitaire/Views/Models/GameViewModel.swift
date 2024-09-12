import Foundation
import Combine

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
  
  func popDrawAndApply() {
    guard var draw = state.draws.popLast() else { return }
    
    draw.makeVisible()
    
    state.mutateColumns { column, index in
      column.cards.append(draw[index])
    }
    
    for columnIndex in 0..<10 {
      validateIndex(forColumn: columnIndex)
    }
    
    state.previousMoves.append(.draw(id: draw.id))
    incrementMoves()
  }
  
  func popPreviousMoveAndApply() {
    switch state.previousMoves.popLast() {
    case .draw(let id):
      let defaultCard = Card(value: .ace, suit: .diamond)
      var draw = Draw(column1: defaultCard, column2: defaultCard, column3: defaultCard, column4: defaultCard, column5: defaultCard, column6: defaultCard, column7: defaultCard, column8: defaultCard, column9: defaultCard, column10: defaultCard, id: id)
      
      state.mutateColumns { stack, index in
        guard let card = stack.cards.popLast() else { return }
        draw[index] = card
      }
      
      state.draws.append(draw)
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
    case .none:
      break
    }
    
    incrementMoves()
  }
  
  private func validateIndex(forColumn columnIndex: Int) {
    if self[columnIndex].count > 1 {
      // FIXME: - Check that suit is the same, or that it alternates between red and black
      for cardIndex in stride(from: self[columnIndex].count - 2, to: 0, by: -1) {
        guard self[columnIndex][cardIndex].value != self[columnIndex][cardIndex + 1].value.larger else {
          continue
        }
        
        self[columnIndex].validityIndex = cardIndex + 1
        return
      }
    } else {
      self[columnIndex].validityIndex = self[columnIndex].count - 1
    }
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