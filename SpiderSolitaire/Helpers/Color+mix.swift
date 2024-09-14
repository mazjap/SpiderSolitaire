import SwiftUI

#if os(macOS)
typealias NativeColor = NSColor
#else
typealias NativeColor = UIColor
#endif

extension Color {
  @available(iOS, deprecated: 18, obsoleted: 18, message: "Use the built in mix function instead.")
  @available(macOS, deprecated: 15, obsoleted: 15, message: "Use the built in mix function instead.")
  @_disfavoredOverload
  func mix(with color: Color, by amount: Double) -> Color {
    let amountInverse = 1 - amount
    
    var r1: CGFloat = 0
    var g1: CGFloat = 0
    var b1: CGFloat = 0
    var a1: CGFloat = 0
    
    var r2: CGFloat = 0
    var g2: CGFloat = 0
    var b2: CGFloat = 0
    var a2: CGFloat = 0
    
    NativeColor(self).getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
    NativeColor(color).getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
    
    return Color(
      red: r1 * amountInverse + r2 * amount,
      green: g1 * amountInverse + g2 * amount,
      blue: b1 * amountInverse + b2 * amount,
      opacity: a1 * amountInverse + a2 * amount
    )
  }
}
