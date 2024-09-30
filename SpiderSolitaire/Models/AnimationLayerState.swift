struct AnimationLayerState {
  var currentHint: HintDisplay?
  var inProgressDraw: [Card]?
  var inProgressSet: [Card]?
  var drawCount: Int
  var completedSetCount: Int
}
