import SwiftUI

struct DrawStackHint: View {
  let drawStackFrame: CGRect
  
  var body: some View {
    AuraView()
      .cardSize(drawStackFrame.size)
      .position(x: drawStackFrame.midX, y: drawStackFrame.midY)
  }
}
