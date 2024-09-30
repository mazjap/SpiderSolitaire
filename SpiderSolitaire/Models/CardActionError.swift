enum CardActionError: Error {
  case noDrawsAvailable
  case noPreviousMovesAvailable
  case attemptedDrawButNoCardsOnStack(index: Int)
}
