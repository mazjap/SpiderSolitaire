import SwiftUI

struct AuraView: View {
  @Environment(\.cardSize) private var cardSize
  @Environment(\.cardShape) private var shape
  @State private var rotation: Double = 0
  
  var body: some View {
    Image("shimmer")
      .scaledToFill()
      .frame(width: cardSize.width + 60, height: cardSize.height + 60)
      .foregroundStyle(.white)
      .rotationEffect(Angle(degrees: rotation))
      .clipShape(shape)
      .blur(radius: 10)
      .overlay {
        shape
          .fill(.black)
          .frame(width: cardSize.width, height: cardSize.height)
          .blendMode(.destinationOut)
      }
      .compositingGroup()
      .frame(width: cardSize.width, height: cardSize.height)
//      .blur(radius: 20)
      .onAppear {
        withAnimation(.easeInOut(duration: 5).repeatForever(autoreverses: true)) {
          rotation = 80
        }
      }
  }
}

#Preview {
  ZStack {
    Color.green
    AuraView()
      .cardSize(CGSize(width: 100, height: 150))
  }
}
