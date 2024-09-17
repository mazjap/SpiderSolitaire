import SwiftUI

#if os(macOS)
typealias NativeColor = NSColor
#else
typealias NativeColor = UIColor
#endif

enum ColorConversionError: Error {
  case cannotConvertColorSpace(from: CGColorSpace?, to: CGColorSpace)
  case cannotConvertCGColorToNativeColor
}

extension NativeColor {
  func toRGBColorSpace() throws -> NativeColor {
    let deviceRGBColorSpace = CGColorSpaceCreateDeviceRGB()
    guard let newCgColor = cgColor.converted(
      to: deviceRGBColorSpace,
      intent: .defaultIntent,
      options: nil)
    else {
      throw ColorConversionError.cannotConvertColorSpace(from: cgColor.colorSpace, to: deviceRGBColorSpace)
    }
    
    #if os(macOS)
    guard let newColor = NativeColor(cgColor: newCgColor) else {
      throw ColorConversionError.cannotConvertCGColorToNativeColor
    }
    #else
    let newColor = NativeColor(cgColor: newCgColor)
    #endif
    
    return newColor
  }
}

extension Color {
  init(nativeColor: NativeColor) {
    #if os(macOS)
    self.init(nsColor: nativeColor)
    #else
    self.init(uiColor: nativeColor)
    #endif
  }
  
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
    
    do {
      try NativeColor(self).toRGBColorSpace().getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
      try NativeColor(color).toRGBColorSpace().getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
      
      return Color(
        red: r1 * amountInverse + r2 * amount,
        green: g1 * amountInverse + g2 * amount,
        blue: b1 * amountInverse + b2 * amount,
        opacity: a1 * amountInverse + a2 * amount
      )
    } catch {
      return self
    }
  }
}
