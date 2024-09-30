import SwiftUI

struct FreeSpaceHint: View {
  private let columnFrame: CGRect
  
  init(columnFrame: CGRect) {
    self.columnFrame = columnFrame
  }
  
  var body: some View {
    AuraView()
      .cardSize(columnFrame.size)
      .position(x: columnFrame.midX, y: columnFrame.midY)
  }
}
