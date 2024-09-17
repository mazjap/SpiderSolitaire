import SwiftUI

struct CardStackView: View {
  @State private var currentDragInfo: (index: Int, pointRelativeToOrigin: CGPoint, offset: CGSize)?
  @Binding var frames: [Int : CGRect]
  
  private let cardStack: CardStack
  private let columnIndex: Int
  private let cardWidth: Double
  private let cardHeight: Double
  private let namespace: Namespace.ID
  
  private let cardShape = RoundedRectangle(cornerRadius: 4)
  
  private let onDragEnd: (Int, CGRect) -> Bool
  private let onDragStart: () -> Void
  
  private let offsets: [Double]
  
  init(cardStack: CardStack, frames: Binding<[Int : CGRect]>, columnIndex: Int, cardWidth: Double, cardHeight: Double, namespace: Namespace.ID, onDragStart: @escaping () -> Void, onDragEnd: @escaping (Int, CGRect) -> Bool) {
    self.cardStack = cardStack
    self._frames = frames
    self.columnIndex = columnIndex
    self.cardWidth = cardWidth
    self.cardHeight = cardHeight
    self.namespace = namespace
    
    self.onDragStart = onDragStart
    self.onDragEnd = onDragEnd
    
    let visibleOffset = cardHeight / 3
    let hiddenOffset = cardHeight / 10
    
    var workingOffset: Double = 0
    
    self.offsets = cardStack.cards.map {
      let offset = workingOffset
      
      if $0.isVisible {
        workingOffset += visibleOffset
      } else {
        workingOffset += hiddenOffset
      }
      
      return offset
    }
  }
  
  var body: some View {
    GeometryReader { geometry in
      ZStack {
        if cards.isEmpty {
          emptyColumn(width: cardWidth, height: cardHeight)
            .transition(.scale)
        } else {
          ForEach(Array(cards.enumerated()), id: \.element.id) { (index, card) in
            let verticalOffset = offsets[index]
            let offset: CGSize = {
              if let currentDragInfo, currentDragInfo.index <= index {
                return CGSize(
                  width: currentDragInfo.offset.width,
                  height: currentDragInfo.offset.height + verticalOffset
                )
              } else {
                return CGSize(width: 0, height: verticalOffset)
              }
            }()
            let isUsable = index >= Int(validityIndex)
            
            CardView(for: card, width: cardWidth, height: cardHeight, isUsable: isUsable, namespace: namespace)
              .offset(offset)
              .gesture(DragGesture(coordinateSpace: .global)
                .onChanged { value in
                  if let relativePoint = currentDragInfo?.pointRelativeToOrigin {
                    currentDragInfo = (index, relativePoint, value.translation)
                  } else {
                    onDragStart()
                    
                    let absFrame = frames[columnIndex] ?? .zero
                    let frame = CGRect(
                      x: absFrame.minX,
                      y: absFrame.minY + verticalOffset,
                      width: absFrame.width,
                      height: absFrame.height - verticalOffset
                    )
                    
                    let pointRelativeToOrigin = CGPoint(
                      x: value.location.x - frame.minX,
                      y: value.location.y - frame.minY
                    )
                    
                    currentDragInfo = (index, pointRelativeToOrigin, value.translation)
                  }
                }
                .onEnded { value in
                  guard let relativePoint = currentDragInfo?.pointRelativeToOrigin
                  else { return }
                  
                  let absFrame = frames[columnIndex] ?? .zero
                  let frame = CGRect(
                    x: value.location.x - relativePoint.x,
                    y: value.location.y - relativePoint.y,
                    width: absFrame.width,
                    height: absFrame.height - verticalOffset
                  )
                  
                  if onDragEnd(index, frame) {
                    withAnimation {
                      currentDragInfo = nil
                    }
                  } else {
                    currentDragInfo = nil
                  }
                },
                isEnabled: card.isVisible && isUsable
              )
          }
        }
      }
      .onChange(of: cards, initial: true) {
        frames[columnIndex] = geometry.frame(in: .global)
      }
      .onChange(of: [cardWidth, cardHeight]) {
        frames[columnIndex] = geometry.frame(in: .global)
      }
    }
    .frame(width: cardWidth, height: cardHeight + (offsets.last ?? 0))
    .padding(.top, (offsets.last ?? 0))
  }
  
  private func emptyColumn(width: Double, height: Double) -> some View {
    cardShape
      .foregroundStyle(.white.opacity(0.2))
      .frame(width: width, height: height)
      .overlay {
        cardShape
          .stroke(Color.white, lineWidth: 2)
      }
  }
}

extension CardStackView {
  private var cards: [Card] {
    cardStack.cards
  }
  
  private var validityIndex: Int {
    min(cardStack.validityIndex, cards.count - 1)
  }
}

#Preview {
  @Previewable @State var cards = Card.Value.allCases.map { Card(value: $0, suit: .heart) }
  @Previewable @Namespace var namespace
  
  VStack {
    CardStackView(cardStack: .init(cards: cards, validityIndex: .max), frames: .constant([:]), columnIndex: 0, cardWidth: 30, cardHeight: 45, namespace: namespace) {
      print("Card(s) dragged")
    } onDragEnd: { card, offset in
      return true
    }
    
    Button("Add Card") {
      cards.append(Card(value: Array(Card.Value.allCases).randomElement()!, suit: Array(Card.Suit.allCases).randomElement()!, isVisible: true))
    }
  }
  .onAppear {
    cards[cards.count - 1].isVisible = true
  }
}
