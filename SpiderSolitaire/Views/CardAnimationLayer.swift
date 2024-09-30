import SwiftUI

struct CardAnimationLayer: View {
  private let state: AnimationLayerState
  private let cardStackFrames: [CGRect]
  private let drawStackFrame: CGRect
  private let drawStackSpacing: Double
  private let completedSetsFrame: CGRect
  private let completedSetSpacing: Double
  private let showsCardOverlayTesting = false
  
  private var currentHint: HintDisplay? {
    state.currentHint
  }
  
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
  
  init(state: AnimationLayerState, cardStackFrames: [CGRect], drawStackFrame: CGRect, drawStackSpacing: Double, completedSetsFrame: CGRect, completedSetSpacing: Double) {
    self.state = state
    self.cardStackFrames = cardStackFrames
    self.drawStackFrame = drawStackFrame
    self.drawStackSpacing = drawStackSpacing
    self.completedSetsFrame = completedSetsFrame
    self.completedSetSpacing = completedSetSpacing
  }
  
  var body: some View {
    ZStack {
      let size = cardSize
      let width = size.width
      let height = size.height
      
      if let cards = inProgressDraw {
        drawOverlay(cards, width: width, height: height)
      }
      
      if let cards = inProgressSet {
        setOverlay(cards, width: width, height: height)
      }
      
      if let currentHint {
        // TODO: - Hint overlay
      }
      
      if showsCardOverlayTesting {
        cardOverlayTesting
      }
    }
  }
  
  private func drawOverlay(_ cards: [Card], width: Double, height: Double) -> some View {
    ForEach(cards) { card in
      let frame = drawStackFrame
      
      CardView(for: card, width: width, height: height, isUsable: true)
        .position(x: frame.maxX - (width / 2) - (Double(drawCount) * drawStackSpacing), y: frame.midY)
    }
  }
  
  private func setOverlay(_ cards: [Card], width: Double, height: Double) -> some View {
    let frame = completedSetsFrame
    
    return ForEach(cards) { card in
      CardView(for: card, width: width, height: height, isUsable: true)
        .position(x: frame.minX + (width / 2) + (Double(completedSetCount) * completedSetSpacing), y: frame.midY)
    }
  }
  
  private var cardOverlayTesting: some View {
    ZStack {
      ForEach(Array(cardStackFrames.enumerated()), id: \.offset) { (index, frame) in
        Rectangle()
          .fill(Color.red.opacity(0.5))
          .border(.blue, width: 1)
          .frame(width: frame.width, height: frame.height)
          .position(x: frame.midX, y: frame.midY)
      }
      .allowsHitTesting(false)
    }
  }
}
