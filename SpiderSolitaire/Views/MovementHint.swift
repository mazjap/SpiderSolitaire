import SwiftUI

struct MovementHint: View {
  @State private var isAtDesination = false
  @State private var cardStackFrame = CGRect.zero
  @Environment(\.namespace) private var animation
  @Namespace private var defaultNamespace
  
  private let width: Double
  private let height: Double
  
  private var namespace: Namespace.ID {
    animation ?? defaultNamespace
  }
  
  private let fromFrame: CGRect
  private let cards: [Card]
  private let toFrame: CGRect
  
  private var fromOffset: CGPoint {
    let halfCurrentStackHeight = cardStackFrame.height / 2
    
    return CGPoint(x: fromFrame.midX, y: fromFrame.maxY - halfCurrentStackHeight)
  }
  
  private var toOffset: CGPoint {
    let offset = height / 3
    let halfCurrentStackHeight = cardStackFrame.height / 2
    
    return CGPoint(x: toFrame.midX, y: toFrame.maxY + halfCurrentStackHeight - height + offset)
  }
  
  init(fromFrame: CGRect, cards: [Card], toFrame: CGRect, width: Double, height: Double) {
    self.fromFrame = fromFrame
    self.cards = cards
    self.toFrame = toFrame
    self.width = width
    self.height = height
  }
  
  var body: some View {
    ZStack {
      AuraView()
        .cardSize(cardStackFrame.size)
        .position(isAtDesination ? toOffset : fromOffset)
      
      if isAtDesination {
        CardStackView(cardStack: CardStack(cards: cards, validityIndex: -1), frame: $cardStackFrame, cardWidth: width, cardHeight: height, onDragStart: {}, onDragEnd: {_,_ in false})
          .opacity(0.75)
          .position(toOffset)
          .matchedGeometryEffect(id: cards.map(\.id.uuidString).joined(), in: namespace)
      } else {
        CardStackView(cardStack: CardStack(cards: cards, validityIndex: -1), frame: $cardStackFrame, cardWidth: width, cardHeight: height, onDragStart: {}, onDragEnd: {_,_ in false})
          .opacity(0.75)
          .position(fromOffset)
          .matchedGeometryEffect(id: cards.map(\.id.uuidString).joined(), in: namespace)
      }
    }
    .onChange(of: cards, initial: true) {
      animateChange()
    }
    .onChange(of: [fromFrame, toFrame]) {
      animateChange()
    }
  }
  
  private func animateChange() {
    Task {
      withAnimation(.linear(duration: 0.6)) {
        isAtDesination = true
      }
      
      try? await Task.sleep(for: .seconds(1))
      isAtDesination = false
      try? await Task.sleep(for: .seconds(0.1))
    }
  }
}
