import SwiftUI

struct CardAnimationLayer: View {
  private let state: AnimationLayerState
  private let cardStackFrames: [CGRect]
  private let drawStackFrame: CGRect
  private let completedSetsFrame: CGRect
  
  private var drawAction: AnimationLayerDrawAction? {
    state.drawAction
  }
  
  private var completedSetAction: AnimationLayerCompleteSetAction? {
    state.completedSetAction
  }
  
  private var drawCount: Int {
    state.drawCount
  }
  
  private var completedSetCount: Int {
    state.completedSetCount
  }
  
  private var cardSize: CGSize {
    let frame = cardStackFrames[0]
    
    return CGSize(width: frame.width, height: frame.width * 1.5)
  }
  
  init(state: AnimationLayerState, cardStackFrames: [CGRect], drawStackFrame: CGRect, completedSetsFrame: CGRect) {
    self.state = state
    self.cardStackFrames = cardStackFrames
    self.drawStackFrame = drawStackFrame
    self.completedSetsFrame = completedSetsFrame
  }
  
  var body: some View {
    ZStack {
      let size = cardSize
      let width = size.width
      let height = size.height
      
      switch drawAction {
      case let .do(cards): // To card stacks
        ForEach(Array(cards.enumerated()), id: \.offset) { (columnNum, card) in
          let frame = drawStackFrame
          
          CardView(for: card, width: width, height: height, isUsable: true)
            .position(x: frame.maxX - (width / 2) - (Double(drawCount) * 8), y: frame.midY) // FIXME: - Correct the y offset
        }
      case let .undo(cards): // To draw pile
        let frame = drawStackFrame
        
        ForEach(cards) { card in
          CardView(for: card, width: width, height: height, isUsable: true)
            .position(x: frame.maxX - 20, y: frame.midY)
        }
      case .none:
        EmptyView()
      }
      
      switch completedSetAction {
      case let .do(cards): // To Complete sets pile
        let frame = completedSetsFrame
        
        ForEach(cards) { card in
          CardView(for: card, width: width, height: height, isUsable: true)
            .position(x: frame.minX + (width / 2) + (Double(completedSetCount) * 30), y: frame.midY)
        }
      case let .undo(cards, index): // To single card stack
        let frame = cardStackFrames[index]
        
        ForEach(cards) { card in
          CardView(for: card, width: width, height: height, isUsable: true)
            .position(x: frame.midX, y: frame.maxY)
        }
      case .none:
        EmptyView()
      }
    }
  }
}
