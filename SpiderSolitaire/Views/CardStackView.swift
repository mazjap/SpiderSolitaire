import SwiftUI

struct CardStackView: View {
  @State private var currentDragInfo: (index: Int, offset: CGSize)?
  @Binding var frames: [Int : CGRect]
  
  private let cards: [Card]
  private let columnIndex: Int
  private let cardWidth: Double
  private let cardHeight: Double
  private let namespace: Namespace.ID
  
  private let onDragEnd: (Int, CGPoint) -> Bool
  private let onDragStart: () -> Void
  
  private let offsets: [Double]
  
  init(cards: [Card], frames: Binding<[Int : CGRect]>, columnIndex: Int, cardWidth: Double, cardHeight: Double, namespace: Namespace.ID, onDragStart: @escaping () -> Void, onDragEnd: @escaping (Int, CGPoint) -> Bool) {
    self.cards = cards
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
    
    self.offsets = cards.map {
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
          
          CardView(for: card, width: cardWidth, height: cardHeight)
            .transition(.scale(scale: 1))
            .matchedGeometryEffect(id: card.id, in: namespace)
            .offset(offset)
            .gesture(DragGesture(coordinateSpace: .global)
              .onChanged { value in
                if currentDragInfo == nil {
                  onDragStart()
                }
                
                currentDragInfo = (index, value.translation)
              }
              .onEnded { value in
                if onDragEnd(index, value.location) {
                  withAnimation {
                    currentDragInfo = nil
                  }
                } else {
                  currentDragInfo = nil
                }
              },
                     isEnabled: card.isVisible
            )
        }
      }
      .onChange(of: cards, initial: true) {
        frames[columnIndex] = geometry.frame(in: .global)
      }
    }
    .frame(width: cardWidth, height: cardHeight + (offsets.last ?? 0))
    .padding(.top, (offsets.last ?? 0))
  }
}

#Preview {
  @Previewable @State var cards = Card.Value.allCases.map { Card(value: $0, suit: .heart) }
  @Previewable @Namespace var namespace
  
  VStack {
    CardStackView(cards: cards, frames: .constant([:]), columnIndex: 0, cardWidth: 30, cardHeight: 45, namespace: namespace) {
      print("Card(s) dragged")
    } onDragEnd: { card, offset in
      return true
    }
    
//    Spacer()
    
    Button("Add Card") {
      cards.append(Card(value: Array(Card.Value.allCases).randomElement()!, suit: Array(Card.Suit.allCases).randomElement()!, isVisible: true))
    }
  }
  .onAppear {
    cards[cards.count - 1].isVisible = true
  }
}
