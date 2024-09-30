import SwiftUI

struct CardSizeEnvironmentKey: EnvironmentKey {
  static let defaultValue: CGSize = CGSize(width: 10, height: 10)
}

extension EnvironmentValues {
  var cardSize: CGSize {
    get { self[CardSizeEnvironmentKey.self] }
    set { self[CardSizeEnvironmentKey.self] = newValue }
  }
  
  var cardShape: RoundedRectangle {
    let minDimension = min(cardSize.width, cardSize.height)
    
    return RoundedRectangle(cornerRadius: minDimension / 10)
  }
}

extension View {
  func cardSize(_ cardSize: CGSize?) -> some View {
    self.environment(\.cardSize, cardSize ?? CardSizeEnvironmentKey.defaultValue)
  }
  
  func cardSize(width: Double, height: Double) -> some View {
    self.cardSize(CGSize(width: width, height: height))
  }
}
