import SwiftUI

struct CardAnimationLayer: View {
  private let state: AnimationLayerState
  private let cardStackFrames: [CGRect]
  private let drawStackFrame: CGRect
  private let completedSetsFrame: CGRect
  
  private var inProgressDraw: [Card]? {
    state.inProgressDraw
  }
  
  private var inProgressSet: [Card]? {
    state.inProgressSet
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
      
      if let cards = inProgressDraw {
        ForEach(cards) { card in
          let frame = drawStackFrame
          
          CardView(for: card, width: width, height: height, isUsable: true)
            .position(x: frame.maxX - (width / 2) - (Double(drawCount) * 8), y: frame.midY)
        }
      }
      
      if let cards = inProgressSet {
        let frame = completedSetsFrame
        
        ForEach(cards) { card in
          CardView(for: card, width: width, height: height, isUsable: true)
            .position(x: frame.minX + (width / 2) + (Double(completedSetCount) * 30), y: frame.midY)
        }
      }
    }
  }
}
