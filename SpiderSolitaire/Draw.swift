import Foundation

struct Draw: Equatable, Identifiable {
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
