extension Array {
  func split(every splitSize: Int) -> [ArraySlice<Element>] {
    var slices = [ArraySlice<Element>]()
    
    for i in stride(from: 0, to: count, by: splitSize) {
      let endIndex = Swift.min(i + splitSize, count)
      slices.append(self[i..<endIndex])
    }
    
    return slices
  }
}
