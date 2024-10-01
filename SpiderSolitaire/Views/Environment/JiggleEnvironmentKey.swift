import SwiftUI

struct JiggleEnvironmentKey: EnvironmentKey {
  static let defaultValue: UUID? = nil
}

extension EnvironmentValues {
  var jiggleId: UUID? {
    get { self[JiggleEnvironmentKey.self] }
    set { self[JiggleEnvironmentKey.self] = newValue }
  }
}

extension View {
  func jiggle(id: UUID?) -> some View {
    self.environment(\.jiggleId, id)
  }
}
