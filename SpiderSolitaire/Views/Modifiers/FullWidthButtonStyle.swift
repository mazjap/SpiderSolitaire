import SwiftUI

struct FullWidthButtonStyle: ButtonStyle {
  @ScaledMetric private var height: Double = 46
  
  func makeBody(configuration: Configuration) -> some View {
    ZStack {
      RoundedRectangle(cornerRadius: 8)
        .foregroundStyle(.tint)
        .frame(height: height)
      
      configuration.label
    }
  }
}
