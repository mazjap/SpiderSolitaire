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
  private(set) var hintsForHashValue: (hash: Int, hints: [Hint])?
  private var inProgressDraw: [Card]?
  private var inProgressSet: [Card]?
  private(set) var cardToJiggleId: UUID?
  
  var drawCount: Int {
    state.draws.count
  }
  
  var completedSetCount: Int {
    state.completedSets.count
  }
  
  var animationLayerState: AnimationLayerState {
    AnimationLayerState(currentHint: currentHint, inProgressDraw: inProgressDraw, inProgressSet: inProgressSet, drawCount: drawCount, completedSetCount: completedSetCount)
  }
  
  private(set) var currentHint: HintDisplay?
  
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
  func display(hint: Hint) {
    startTimer()
    
    currentHint = switch hint {
    case let .move(columnIndex, validityIndex, destinationColumnIndex):
        .move(columnIndex: columnIndex, card: Array(self[columnIndex].cards[validityIndex...]), destinationColumnIndex: destinationColumnIndex)
    case let .moveAnyToFreeSpace(freeSpaceIndex):
        .moveAnyToFreeSpace(freeSpaceIndex: freeSpaceIndex)
    case .drawFromStack:
        .drawFromStack
    }
  }
  
  func clearHint() {
    currentHint = nil
  }
  
  func calculateHints() {
    let newHash = state.hashValue
    guard hintsForHashValue?.hash != newHash else { return }
    
    var hints = [Hint]()
    var containsHiddenCards = false
    
    // Buffer mapping for needed top card for each column
    var bottomCardsToColumnIndexMapping = [Card.Value : [Int]]()
    
    // Buffer mapping for completed sets that a missing a select amount of cards
    var neededToCompleteSetMapping = [Card.Value : [Int]]()
    
    for columnIndex in 0..<10 {
      guard let bottomCard = self[columnIndex].cards.last else {
        continue
      }
      
      bottomCardsToColumnIndexMapping[bottomCard.value, default: []].append(columnIndex)
      
      if isComplete(forColumn: columnIndex, fromValue: bottomCard.value) {
        neededToCompleteSetMapping[bottomCard.value.smaller!, default: []].append(columnIndex)
      }
    }
    
    var brokenUpCompletedSets = [(from: Int, cardIndex: Int, to: Int)]()
    var freeSpaceColumns = [Int]()
    
    for columnIndex in 0..<10 {
      let stack = self[columnIndex]
      guard !stack.isEmpty else {
        freeSpaceColumns.append(columnIndex)
        continue
      }
      
      if !containsHiddenCards,
         let isVisible = stack.cards.first?.isVisible,
         !isVisible {
        containsHiddenCards = true
      }
      
      let cardToMove = stack[stack.validityIndex]
      
      if isComplete(forColumn: columnIndex, toValue: cardToMove.value) {
        var lowerValue = cardToMove.value.smaller
        var cardIndex = stack.validityIndex + 1
        var toBreak = [(cardIndex: Int, toColumnIndex: Int)]()
        while let currentValue = lowerValue {
          toBreak.append(
            contentsOf: neededToCompleteSetMapping[currentValue, default: []]
              .map { (cardIndex: cardIndex, toColumnIndex: $0) }
          )
          
          lowerValue = currentValue.smaller
          cardIndex += 1
        }
        
        brokenUpCompletedSets.append(contentsOf: toBreak.map { (from: columnIndex, cardIndex: $0.cardIndex, to: $0.toColumnIndex) })
      }
      
      guard let largerValue = cardToMove.value.larger,
            let indices = bottomCardsToColumnIndexMapping[largerValue]
      else { continue }
      
      hints.append(
        contentsOf: indices
          .filter { $0 != columnIndex }
          .map { .move(columnIndex: columnIndex, validityIndex: stack.validityIndex, destinationColumnIndex: $0) })
    }
    
    hints.append(contentsOf: brokenUpCompletedSets.map { Hint.move(columnIndex: $0.from, validityIndex: $0.cardIndex, destinationColumnIndex: $0.to) })
    
    if containsHiddenCards {
      hints.append(contentsOf: freeSpaceColumns.map { Hint.moveAnyToFreeSpace(freeSpaceIndex: $0) })
    }
    
    if hints.isEmpty {
      hints.append(.drawFromStack)
    }
    
    hintsForHashValue = (newHash, hints)
  }
  
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
  
  func makeFirstAvailableMove(for columnIndex: Int, cardIndex: Int) {
    let cardToMove = self[columnIndex][cardIndex]
    guard let neededCardValue = cardToMove.value.larger else {
      cardToJiggleId = cardToMove.id
      Task {
        try? await Task.sleep(for: .seconds(0.5))
        guard cardToJiggleId == cardToMove.id else { return }
        cardToJiggleId = nil
      }
      return
    }
    
    for columnToCompare in (0..<10).filter({ $0 != columnIndex }) {
      if let lastCard = self[columnToCompare].cards.last,
         lastCard.value == neededCardValue {
        _ = moveCards(fromColumn: columnIndex, cardIndex: cardIndex, toColumn: columnToCompare)
        return
      }
    }
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
    
    inProgressDraw = draw.cards
    
    return draw
  }
  
  func apply(draw: Draw) -> [Int] {
    // Animation step 1, remove from view hierarchy
    inProgressDraw = nil
    
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
  
  func popPreviousMoveAndApply(onCompletion: @escaping (UndoAction, @escaping () -> Void) -> Void) {
    switch state.previousMoves.popLast() {
    case .draw(let id):
      let defaultCard = Card(value: .ace, suit: .diamond)
      var draw = Draw(column1: defaultCard, column2: defaultCard, column3: defaultCard, column4: defaultCard, column5: defaultCard, column6: defaultCard, column7: defaultCard, column8: defaultCard, column9: defaultCard, column10: defaultCard, id: id)
      
      state.mutateColumns { stack, index in
        guard var card = stack.cards.popLast() else { return }
        card.isVisible = false
        draw[index] = card
      }
      inProgressDraw = draw.cards
      
      onCompletion(.draw) { [weak self] in
        draw.makeHidden()
        self?.inProgressDraw = nil
        self?.state.draws.append(draw)
        self?.validateAllColumns()
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
      
      inProgressSet = cards
      
      onCompletion(.set) { [weak self] in
        self?.state[columnIndex].cards.append(contentsOf: cards)
        self?.inProgressSet = nil
        
        self?.popPreviousMoveAndApply(onCompletion: onCompletion)
      }
      return
    case .none: return
    }
    
    incrementMoves()
  }
  
  /// Determines if the cards in the provided card stack are in order, from fromValue (ace) to toValue (king)
  private func isComplete(forColumn columnIndex: Int, fromValue: Card.Value = .ace, toValue: Card.Value = .king) -> Bool {
    guard self[columnIndex].count >= toValue - fromValue + 1,
          let last = self[columnIndex].cards.last,
          last.value == fromValue
    else { return false }
    
    var finalValue = last.value
    
    for card in self[columnIndex].usableCards.dropLast().reversed() where card.isVisible {
      guard card.isVisible,
            card.value == finalValue.larger,
            card.suit == last.suit
      else { break }
      
      finalValue = card.value
    }
    
    guard finalValue == toValue else { return false }
    return true
  }
  
  func checkForCompletedSet(forColumn columnIndex: Int) {
    guard let suit = self[columnIndex].cards.last?.suit else { return }
    guard isComplete(forColumn: columnIndex) else { return }
    
    let completedCards = self[columnIndex].cards.suffix(13)
    self[columnIndex].cards.removeLast(13)
    
    inProgressSet = Array(completedCards)
    
    // Use a completion handler to finalize the set completion
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
      guard let self = self else { return }
      self.inProgressSet = nil
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
      guard self[columnIndex][cardIndex].isVisible,
            self[columnIndex][cardIndex].value == self[columnIndex][cardIndex + 1].value.larger,
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
    currentHint = nil
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
