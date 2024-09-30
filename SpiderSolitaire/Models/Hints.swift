enum Hint {
  case move(columnIndex: Int, validityIndex: Int, destinationColumnIndex: Int)
  case moveAnyToFreeSpace(freeSpaceIndex: Int)
  case drawFromStack
}

enum HintDisplay {
  case move(columnIndex: Int, card: [Card], destinationColumnIndex: Int)
  case moveAnyToFreeSpace(freeSpaceIndex: Int)
  case drawFromStack
}
