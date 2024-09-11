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
    
    guard state[destination].cards.last == nil || state[destination].cards.last?.value == cardsToMove.first?.value.larger else { return true }
    
    state[source].removeSubrange(cardIndex..<cardsToMove.endIndex)
    state[destination].append(contentsOf: cardsToMove)
    
    if !state[source].isEmpty {
      state[source][state[source].cards.count - 1].isVisible = true
    }
    
    validateIndex(forColumn: source)
    validateIndex(forColumn: destination)
    
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
    
    incrementMoves()
  }
  
  private func validateIndex(forColumn columnIndex: Int) {
    if self[columnIndex].count > 1 {
      // FIXME: - Check that suit is the same, or that it alternates between red and black
      for cardIndex in stride(from: self[columnIndex].count - 2, to: 0, by: -1) {
        guard self[columnIndex][cardIndex].value != self[columnIndex][cardIndex + 1].value.larger else {
          continue
        }
        
        self[columnIndex].validityIndex = UInt8(cardIndex + 1)
        return
      }
    } else {
      self[columnIndex].validityIndex = UInt8(self[columnIndex].count - 1)
    }
    
    print("New valid index for column: \(columnIndex)")
    for (index, card) in self[columnIndex].cards.enumerated() {
      print("\(index == self[columnIndex].validityIndex ? "-->" : "   ") \(card)")
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
    state.moves += 1
    startTimer()
  }
}

// MARK: - Computed Variables
extension GameViewModel {
  var formattedTime: String {
    formatter.string(from: DateComponents(second: state.seconds)) ?? String(state.seconds)
  }
}

// MARK: - Model Convenience
extension GameViewModel {
  subscript(column: Int) -> CardStack {
    get {
      return state[column]
    }
    set {
      state[column] = newValue
    }
  }
}
