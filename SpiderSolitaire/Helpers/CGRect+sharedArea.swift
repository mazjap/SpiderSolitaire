import Foundation

extension CGRect {
  func sharedArea(with rect: CGRect) -> CGFloat {
    let area = width * height
    let otherArea = rect.width * rect.height
    
    let sharedWidth = min(maxX, rect.maxX) - max(minX, rect.minX)
    let sharedHeight = min(maxY, rect.maxY) - max(minY, rect.minY)
    let sharedArea = sharedWidth * sharedHeight
    
    let totalArea = area + otherArea - sharedArea
    
    return sharedArea / totalArea
  }
}
