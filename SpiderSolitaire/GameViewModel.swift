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
    formatter.allowedUnits = [.hour, .minute, .second]
    formatter.unitsStyle = .positional
    return formatter
  }()
  
  init(state: GameState) {
    self.state = state
    self.initialTime = state.seconds
    
    revealTopCardsInAllColumns()
  }
  
  deinit {
    stopTimerInternal()
  }
}

// MARK: - State mutating functions
extension GameViewModel {
  private func revealTopCardsInAllColumns() {
    state.mutateColumns { cards in
      guard !cards.isEmpty else { return }
      cards[cards.count - 1].isVisible = true
    }
  }
  
  func startTimer() {
    timerLock.lock()
    defer { timerLock.unlock() }
    
    // FIXME: - Replace `unowned` with `weak` if timer is ever used elsewhere
    timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
      .sink { [unowned self] _ in
        self.state.seconds = self.initialTime + self.elapsedTime
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
  }
  
  func popDrawAndApply() {
    guard var draw = state.draws.popLast() else { return }
    
    draw.makeVisible()
    
    state.mutateColumns { cards, index in
      cards.append(draw[index])
    }
    
    incrementMoves()
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
