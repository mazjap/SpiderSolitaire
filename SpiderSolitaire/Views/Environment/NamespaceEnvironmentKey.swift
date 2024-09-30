import SwiftUI

struct NamespaceEnvironmentKey: EnvironmentKey {
  static let defaultValue: Namespace.ID? = nil
}

extension EnvironmentValues {
  var namespace: Namespace.ID? {
    get { self[NamespaceEnvironmentKey.self] }
    set { self[NamespaceEnvironmentKey.self] = newValue }
  }
}

extension View {
  func namespace(_ namespace: Namespace.ID?) -> some View {
    self.environment(\.namespace, namespace)
  }
}
