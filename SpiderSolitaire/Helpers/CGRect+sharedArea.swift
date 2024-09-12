import Foundation

extension CGRect {
  func sharedArea(with rect: CGRect) -> CGFloat {
    let sharedArea = intersection(rect)
    
    return (sharedArea.width * sharedArea.height) / (width * height)
  }
}
