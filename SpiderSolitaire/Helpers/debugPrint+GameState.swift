#if DEBUG

func debugPrint(gameState: GameState) {
  // Ugly, but useful
  print("""
GameState(
completedSets: \(gameState.completedSets.map {
"CompletedSet(suit: .\($0.suit.rawValue), id: UUID(uuidString: \($0.id.uuidString))!)"
}), 
\(gameState.mapColumns { stack, index in
    "column\(index + 1): CardStack(cards: [\n\(stack.cards.map { "Card(value: .\($0.value), suit: .\($0.suit), id: UUID(uuidString: \"\($0.id.uuidString)\")!, isVisible: \($0.isVisible))" }.joined(separator: ", \n"))], validityIndex: \(stack.validityIndex)), \n"
}.joined())
draws: [\(gameState.draws.map { draw in
"Draw(" + (0..<10).map { "column\($0 + 1): Card(value: .\(draw[$0].value), suit: .\(draw[$0].suit), id: UUID(uuidString: \"\(draw[$0].id.uuidString)\")!, isVisible: \(draw[$0].isVisible))" }.joined(separator: ", \n") + ")"
}.joined(separator: ", \n"))],
previousMoves: [\(gameState.previousMoves.map {
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
}

#endif
