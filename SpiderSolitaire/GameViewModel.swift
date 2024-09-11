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
    state.mutateColumns { cards in
      guard !cards.isEmpty else { return }
      cards[cards.count - 1].isVisible = true
    }
  }
  
  func moveCards(fromColumn source: Int, cardIndex: Int, toColumn destination: Int) {
    let cardsToMove = self[source][cardIndex...]
    self[source].removeSubrange(cardIndex..<cardsToMove.endIndex)
    self[destination].append(contentsOf: cardsToMove)
    
    if !self[source].isEmpty {
      self[source][self[source].count - 1].isVisible = true
    }
    
    incrementMoves()
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
    
    state.mutateColumns { cards, index in
      cards.append(draw[index])
    }
    
    incrementMoves()
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
  subscript(column: Int) -> [Card] {
    get {
      guard 0...9 ~= column else { return [] }
      return state[column]
    }
    set {
      guard 0...9 ~= column else { return }
      state[column] = newValue
    }
  }
}
