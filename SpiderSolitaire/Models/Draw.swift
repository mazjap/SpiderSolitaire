import Foundation

struct Draw: Hashable, Identifiable {
  var column1: Card
  var column2: Card
  var column3: Card
  var column4: Card
  var column5: Card
  var column6: Card
  var column7: Card
  var column8: Card
  var column9: Card
  var column10: Card
  
  var id: UUID
  
  init(column1: Card, column2: Card, column3: Card, column4: Card, column5: Card, column6: Card, column7: Card, column8: Card, column9: Card, column10: Card, id: UUID = UUID()) {
    self.column1 = column1
    self.column2 = column2
    self.column3 = column3
    self.column4 = column4
    self.column5 = column5
    self.column6 = column6
    self.column7 = column7
    self.column8 = column8
    self.column9 = column9
    self.column10 = column10
    self.id = id
  }
}

extension Draw {
  subscript(index: Int) -> Card {
    get {
      switch index {
      case 0: return column1
      case 1: return column2
      case 2: return column3
      case 3: return column4
      case 4: return column5
      case 5: return column6
      case 6: return column7
      case 7: return column8
      case 8: return column9
      case 9: return column10
      default: fatalError("Index out of bounds")
      }
    }
    set {
      switch index {
      case 0: column1 = newValue
      case 1: column2 = newValue
      case 2: column3 = newValue
      case 3: column4 = newValue
      case 4: column5 = newValue
      case 5: column6 = newValue
      case 6: column7 = newValue
      case 7: column8 = newValue
      case 8: column9 = newValue
      case 9: column10 = newValue
      default: fatalError("Index out of bounds")
      }
    }
  }
}

extension Draw {
  mutating func makeVisible() {
    column1.isVisible = true
    column2.isVisible = true
    column3.isVisible = true
    column4.isVisible = true
    column5.isVisible = true
    column6.isVisible = true
    column7.isVisible = true
    column8.isVisible = true
    column9.isVisible = true
    column10.isVisible = true
  }
  
  mutating func makeHidden() {
    column1.isVisible = false
    column2.isVisible = false
    column3.isVisible = false
    column4.isVisible = false
    column5.isVisible = false
    column6.isVisible = false
    column7.isVisible = false
    column8.isVisible = false
    column9.isVisible = false
    column10.isVisible = false
  }
}

extension Draw {
  var cards: [Card] {
    [
      column1, column2,
      column3, column4,
      column5, column6,
      column7, column8,
      column9, column10
    ]
  }
}
