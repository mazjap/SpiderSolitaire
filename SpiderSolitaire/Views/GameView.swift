import SwiftUI

struct GameView: View {
  @State private var model: GameViewModel
  @State private var draggingColumn: Int?
  @State private var cardStackFrames = [Int : CGRect]()
  @State private var areNewGameOptionsShown = false
  @Namespace private var namespace
  private let backgroundColor = Color.green.mix(with: .black, by: 0.2)
  
  private let outerHorizontalPadding: Double = 4
  private let interCardSpacing: Double = 5
  private var totalCardSpacing: Double { (10 - 1) * interCardSpacing }
  private var totalHorizontalPadding: Double {
    (outerHorizontalPadding * 2) + totalCardSpacing
  }
  
  init(gameState: GameState) {
    self.model = GameViewModel(state: gameState)
  }
  
  var body: some View {
    GeometryReader { geometry in
      let cardWidth = (geometry.size.width - totalHorizontalPadding) / 10
      let cardHeight = cardWidth * 1.5
      
      ZStack {
        backgroundColor
          .ignoresSafeArea()
        
        VStack {
          stats
          
          Spacer()
            .frame(height: 10)
          
          HStack {
            completedSets(width: cardWidth, height: cardHeight)
            
            Spacer()
            
            drawStack(width: cardWidth, height: cardHeight)
              .onTapGesture {
                model.popDrawAndApply()
              }
          }
          
          Spacer()
            .frame(height: 10)
          
          HStack(spacing: interCardSpacing) {
            ForEach(0..<10) { columnNum in
              let cardStack = model[columnNum]
              
              CardStackView(cardStack: cardStack, frames: $cardStackFrames, columnIndex: columnNum, cardWidth: cardWidth, cardHeight: cardHeight, namespace: namespace) {
                draggingColumn = columnNum
              } onDragEnd: { draggingCardIndex, frame in
                let shouldAnimateReturn: Bool
                
                let bestSharedArea = cardStackFrames
                  .filter({ $0.key != columnNum })
                  .mapValues({
                    $0.sharedArea(with: frame)
                  })
                  .max(by: {
                    $0.value < $1.value
                  })
                
                if let bestSharedArea, bestSharedArea.value > 0.1, bestSharedArea.value <= 1 {
                  shouldAnimateReturn = withAnimation {
                    model.moveCards(fromColumn: columnNum, cardIndex: draggingCardIndex, toColumn: bestSharedArea.key)
                  }
                } else {
                  shouldAnimateReturn = true
                }
                
                return shouldAnimateReturn
              }
              .zIndex(draggingColumn == columnNum ? 1 : 0)
            }
            .transition(.offset(.zero))
          }
          .frame(height: cardHeight)
          
          Spacer()
          
          controls
        }
        .padding(.horizontal, outerHorizontalPadding)
      }
    }
    .onAppear {
      onGameStart()
    }
  }
}

// MARK: - Additional Views
extension GameView {
  private var stats: some View {
    HStack {
      // TODO: - Implement Score
      Text("Score\n0")
      
      Spacer()
      
      Text("Time\n\(model.formattedTime)")
      
      Spacer()
      
      Text("Moves\n\(model.state.moveCount)")
    }
    .multilineTextAlignment(.center)
    .monospaced()
    .foregroundStyle(.white)
    .padding(.horizontal, 20)
    .confirmationDialog("New Game Difficulty", isPresented: $areNewGameOptionsShown) {
      Button("One Suit") {
        model = GameViewModel(state: GameState(suits: .oneSuit))
        onGameStart()
      }
      Button("Two Suits") {
        model = GameViewModel(state: GameState(suits: .twoSuits))
        onGameStart()
      }
      Button("Four Suits") {
        model = GameViewModel(state: GameState(suits: .fourSuits))
        onGameStart()
      }
      
      Button("Cancel", role: .cancel) {}
    }
  }
  
  private var controls: some View {
    HStack {
      Button {
        // TODO: - Implement Settings (haptics, colors, default game mode, etc.)
      } label: {
        VStack {
          Image(systemName: "gear")
            .resizable()
            .scaledToFit()
            .frame(width: 30, height: 30)
          
          Text("Settings")
        }
      }
      .padding(.trailing, -8)
      
      Spacer()
      
      Button {
        // TODO: - Implement hints
      } label: {
        VStack {
          Image(systemName: "lightbulb.max.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 30, height: 30)
            .foregroundStyle(.yellow)
          
          Text("Hint")
        }
      }
      
      Spacer()
      
      #if DEBUG
      Button {
        // Ugly but useful
        print("""
GameState(
  completedSets: \(model.state.completedSets.map { 
    "CompletedSet(suit: .\($0.suit.rawValue), id: UUID(uuidString: \($0.id.uuidString))!)"
  }), 
  \(model.state.mapColumns { stack, index in
          "column\(index + 1): CardStack(cards: [\n\(stack.cards.map { "Card(value: .\($0.value), suit: .\($0.suit), id: UUID(uuidString: \"\($0.id.uuidString)\")!, isVisible: \($0.isVisible))" }.joined(separator: ", \n"))], validityIndex: \(stack.validityIndex)), \n"
  }.joined())
  draws: [\(model.state.draws.map { draw in
    "Draw(" + (0..<10).map { "column\($0 + 1): Card(value: .\(draw[$0].value), suit: .\(draw[$0].suit), id: UUID(uuidString: \"\(draw[$0].id.uuidString)\")!, isVisible: \(draw[$0].isVisible))" }.joined(separator: ", \n") + ")"
  }.joined(separator: ", \n"))],
  previousMoves: [\(model.state.previousMoves.map {
    switch $0 {
    case let .draw(id):
      ".draw(id: UUID(uuidString: \"\(id.uuidString)\")!)"
    case let .move(columnIndex, cardCount, destinationIndex, didRevealCard):
      ".move(columnIndex: \(columnIndex), cardCount: \(cardCount), destinationIndex: \(destinationIndex), didRevealCard: \(didRevealCard))"
    }
  }.joined(separator: ", \n"))]
)
""")
      } label: {
        VStack {
          Image(systemName: "ladybug.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 30, height: 30)
          
          Text("Debug")
        }
      }
      
      Spacer()
      #endif
      
      Button {
        areNewGameOptionsShown.toggle()
      } label: {
        VStack {
          ZStack {
            CardView(for: .hidden, width: 20, height: 30, isUsable: true, namespace: namespace)
              .rotationEffect(.degrees(20))
              .offset(x: 10)
            
            CardView(for: .hidden, width: 20, height: 30, isUsable: true, namespace: namespace)
              .rotationEffect(.degrees(-20))
              .offset(x: -10)
            
            CardView(for: .hidden, width: 20, height: 30, isUsable: true, namespace: namespace)
              .offset(y: -2)
          }
          .frame(width: 30, height: 30)
          .offset(y: 2)
          
          Text("Play")
        }
      }
      
      Spacer()
      
      Button {
        model.popPreviousMoveAndApply()
      } label: {
        VStack {
          Image(systemName: "arrow.uturn.backward")
            .resizable()
            .scaledToFit()
            .frame(width: 30, height: 30)
          
          Text("Undo")
        }
        .foregroundStyle(model.canUndo ? .white : .gray)
      }
    }
    .foregroundStyle(.white)
    .padding(.top, 8)
    .padding(.bottom, 4)
    .padding(.horizontal, 20)
    .background {
      RoundedRectangle(cornerRadius: 10)
        .fill(Color.black.opacity(0.5))
    }
    .padding(.horizontal, 25)
  }
}

// MARK: - View Functions
extension GameView {
  private func completedSets(width: Double, height: Double) -> some View {
    let subsequentCardOffset: Double = 30
    
    return ZStack {
      ForEach(Array(model.state.completedSets.enumerated()), id: \.element.id) { (index, set) in
        CardView(for: .completedSet(set), width: width, height: height, isUsable: true, namespace: namespace)
          .offset(x: subsequentCardOffset * Double(index))
      }
    }
    .frame(height: height)
  }
  
  private func drawStack(width: Double, height: Double) -> some View {
    let subsequentCardOffset: Double = 4
    
    return ZStack {
      ForEach(Array(model.state.draws.enumerated()), id: \.element.id) { (index, set) in
        CardView(for: .hidden, width: width, height: height, isUsable: true, namespace: namespace)
          .offset(x: -subsequentCardOffset * Double(index))
      }
    }
    .frame(height: height)
  }
}

extension GameView {
  private func onGameStart() {
    model.revealTopCardsInAllColumns()
  }
}

#Preview {
//  var gameState = GameState(suits: .oneSuit)
//  gameState.completedSets = [
    //    CompletedSet(suit: .heart),
    //    CompletedSet(suit: .heart),
    //    CompletedSet(suit: .club),
    //    CompletedSet(suit: .club),
    //    CompletedSet(suit: .diamond),
    //    CompletedSet(suit: .diamond),
    //    CompletedSet(suit: .spade),
    //    CompletedSet(suit: .spade)
//  ]
  
  //  gameState.seconds = Int(60.0 * 59.99)
  
  var gameState = GameState(
    completedSets: [],
    column1: CardStack(cards: [
  Card(value: .ace, suit: .club, id: UUID(uuidString: "3ED37672-306F-4934-8383-F0F51E41D538")!, isVisible: false),
  Card(value: .two, suit: .club, id: UUID(uuidString: "D1F723AB-8D5D-410A-AAE8-14ABEAA41F5A")!, isVisible: false),
  Card(value: .seven, suit: .club, id: UUID(uuidString: "EA16642B-4145-4F23-9698-7E6D7B8ADE9A")!, isVisible: false),
  Card(value: .jack, suit: .club, id: UUID(uuidString: "DE2FFC7D-25DE-47F7-8CB6-B056D5C0DD96")!, isVisible: false),
  Card(value: .jack, suit: .club, id: UUID(uuidString: "45700152-76FC-45C4-8B4C-2D780544290D")!, isVisible: false),
  Card(value: .ten, suit: .club, id: UUID(uuidString: "C73C4484-E655-47E5-ACDD-FE54BCC5376B")!, isVisible: true),
  Card(value: .nine, suit: .club, id: UUID(uuidString: "CFD51E0F-6A4C-49A4-B3EE-F65475FED4E0")!, isVisible: true)], validityIndex: 4),
  column2: CardStack(cards: [
  Card(value: .five, suit: .club, id: UUID(uuidString: "D5CBB561-980E-497D-8E6F-F521B57254EC")!, isVisible: false),
  Card(value: .six, suit: .club, id: UUID(uuidString: "4E00BB1E-2C4E-4666-8BFF-49D69519CE7C")!, isVisible: true),
  Card(value: .five, suit: .club, id: UUID(uuidString: "E74BACB2-6592-48EE-BDB3-3B7858D91F2C")!, isVisible: true),
  Card(value: .four, suit: .club, id: UUID(uuidString: "35F053AD-89A5-439E-A152-982C1D1E63A4")!, isVisible: true),
  Card(value: .three, suit: .club, id: UUID(uuidString: "45C54523-6FF7-418F-B0F0-05B6A872AE97")!, isVisible: true)], validityIndex: 1),
  column3: CardStack(cards: [
  Card(value: .seven, suit: .club, id: UUID(uuidString: "A62AADB5-2C5A-4314-A6FE-508ECA72E5ED")!, isVisible: false),
  Card(value: .seven, suit: .club, id: UUID(uuidString: "F77D1307-B1FA-4870-B33E-0A82AB71B457")!, isVisible: false),
  Card(value: .ace, suit: .club, id: UUID(uuidString: "3A8C8786-5301-4667-9BFA-466FE532002A")!, isVisible: false),
  Card(value: .ten, suit: .club, id: UUID(uuidString: "220B777B-614B-45CD-B19D-18ECC96EA8BE")!, isVisible: false),
  Card(value: .three, suit: .club, id: UUID(uuidString: "7196A810-611E-4591-963A-9A415E4E9F78")!, isVisible: false),
  Card(value: .queen, suit: .club, id: UUID(uuidString: "A2F775E6-CADF-4B0B-8CD8-58379D9C9993")!, isVisible: true)], validityIndex: 9223372036854775807),
  column4: CardStack(cards: [
  Card(value: .two, suit: .club, id: UUID(uuidString: "97AC4240-33A8-4D34-B5A1-8EA5704797E8")!, isVisible: false),
  Card(value: .three, suit: .club, id: UUID(uuidString: "144E4CBD-A401-4225-B5D4-FEF4D00C2D2A")!, isVisible: false),
  Card(value: .king, suit: .club, id: UUID(uuidString: "56D7F509-6A3F-4954-BB04-CD755D8BF8EC")!, isVisible: false),
  Card(value: .nine, suit: .club, id: UUID(uuidString: "9122B428-6EC6-4A44-A687-41A2205F31F1")!, isVisible: false),
  Card(value: .ten, suit: .club, id: UUID(uuidString: "6BF8E0F5-E1F9-49D0-8078-5E3FB7BE1322")!, isVisible: false),
  Card(value: .nine, suit: .club, id: UUID(uuidString: "316FFF02-F2DA-426C-A895-5265FA43E643")!, isVisible: true)], validityIndex: 9223372036854775807),
  column5: CardStack(cards: [

  Card(value: .three, suit: .club, id: UUID(uuidString: "5B1BB6A1-E739-49F2-9607-907375D15916")!, isVisible: false),
  Card(value: .seven, suit: .club, id: UUID(uuidString: "262B8CAD-7683-4488-B29C-EBC39721247E")!, isVisible: false),
  Card(value: .nine, suit: .club, id: UUID(uuidString: "09C3EAF9-0D10-4A9A-9A43-7934112E3C94")!, isVisible: false),
  Card(value: .four, suit: .club, id: UUID(uuidString: "B63C5978-BB93-4A44-9617-0FC2DDB2B8E1")!, isVisible: false),
  Card(value: .ten, suit: .club, id: UUID(uuidString: "4F6E9C6A-655B-4A87-B5BA-43640E7A21DB")!, isVisible: true),
  Card(value: .nine, suit: .club, id: UUID(uuidString: "7C315484-59B7-4002-945C-77B6CEFCDD7C")!, isVisible: true),
  Card(value: .eight, suit: .club, id: UUID(uuidString: "84A283ED-9178-4579-AD30-3A49FD2D40E2")!, isVisible: true)], validityIndex: 4),
  column6: CardStack(cards: [
  Card(value: .three, suit: .club, id: UUID(uuidString: "7A56EA62-1D3C-485E-A923-E4FC167B4F0A")!, isVisible: false),
  Card(value: .eight, suit: .club, id: UUID(uuidString: "904BEE4C-EBC4-4517-BE12-CDE7769F3906")!, isVisible: false),
  Card(value: .two, suit: .club, id: UUID(uuidString: "5C5E48B6-94E3-4EB1-ABCB-91C348A3BEF2")!, isVisible: false),
  Card(value: .six, suit: .club, id: UUID(uuidString: "7024F785-076C-4D0F-8D9D-298DC540914A")!, isVisible: false),
  Card(value: .two, suit: .club, id: UUID(uuidString: "B03A53F2-431D-4BB7-BAF9-A50CD64E682D")!, isVisible: true),
  Card(value: .ace, suit: .club, id: UUID(uuidString: "4A56CC40-21E4-4EE1-9224-60768B575C52")!, isVisible: true)], validityIndex: 4),
  column7: CardStack(cards: [
  Card(value: .four, suit: .club, id: UUID(uuidString: "08C59613-F8DD-41B7-80F4-D79C534DCD4B")!, isVisible: false),
  Card(value: .six, suit: .club, id: UUID(uuidString: "CBFB795F-882F-487C-85B4-F73B9ABC74A7")!, isVisible: false),
  Card(value: .six, suit: .club, id: UUID(uuidString: "DFF7B5F2-17C0-4F7F-8264-0BB5C6AA8204")!, isVisible: false),
  Card(value: .nine, suit: .club, id: UUID(uuidString: "3B8BD3AC-BD75-4C38-A8A0-14B42DF1CA4C")!, isVisible: true)], validityIndex: 3),
  column8: CardStack(cards: [
  Card(value: .eight, suit: .club, id: UUID(uuidString: "6558F265-4400-4CEC-AD7F-823761836D3A")!, isVisible: false),
  Card(value: .eight, suit: .club, id: UUID(uuidString: "38CD1E0A-CC23-4019-8BFF-6520384509ED")!, isVisible: false),
  Card(value: .six, suit: .club, id: UUID(uuidString: "2AC3ECBB-C3E5-403D-A3E6-1537A5BBEF71")!, isVisible: false),
  Card(value: .nine, suit: .club, id: UUID(uuidString: "4DE4687B-CD1E-4914-846F-21478C8E953A")!, isVisible: true)], validityIndex: 3),
  column9: CardStack(cards: [
  Card(value: .jack, suit: .club, id: UUID(uuidString: "A6734A3A-BA8F-4FF1-BCBC-825E799EEFAF")!, isVisible: false),
  Card(value: .king, suit: .club, id: UUID(uuidString: "F57002CB-0503-4CF3-BBFA-C15ADCB5CBDB")!, isVisible: false),
  Card(value: .three, suit: .club, id: UUID(uuidString: "24174E39-5F23-40E2-8436-F8D0688C32AA")!, isVisible: false),
  Card(value: .four, suit: .club, id: UUID(uuidString: "22C7D7F0-9EE2-4BCC-BAC2-4BE64E24A237")!, isVisible: false),
  Card(value: .jack, suit: .club, id: UUID(uuidString: "9CB79D00-6FCE-41E4-A3F1-DB4F790AF591")!, isVisible: true)], validityIndex: 9223372036854775807),
  column10: CardStack(cards: [
  Card(value: .five, suit: .club, id: UUID(uuidString: "8136DB50-9A18-4D99-B738-EB95D5F783BD")!, isVisible: false),
  Card(value: .ace, suit: .club, id: UUID(uuidString: "50AA3451-698C-4E3F-A899-5F5F3FF275EE")!, isVisible: false),
  Card(value: .jack, suit: .club, id: UUID(uuidString: "C4213EF7-E1D2-4A97-AE8B-81F65765880F")!, isVisible: false),
  Card(value: .four, suit: .club, id: UUID(uuidString: "34985755-C973-4FFD-A68B-FCE329B2CC29")!, isVisible: true)], validityIndex: 3),

    draws: [Draw(column1: Card(value: .three, suit: .club, id: UUID(uuidString: "2359BC56-F328-4C11-B70B-9929675514BB")!, isVisible: false),
  column2: Card(value: .ten, suit: .club, id: UUID(uuidString: "2101226D-C461-46F1-B1B0-522099140690")!, isVisible: false),
  column3: Card(value: .two, suit: .club, id: UUID(uuidString: "810340A0-E75B-4FF3-BCE9-5914AC84689A")!, isVisible: false),
  column4: Card(value: .two, suit: .club, id: UUID(uuidString: "235042C8-BC0F-4B5D-80BE-F16A587EF91E")!, isVisible: false),
  column5: Card(value: .king, suit: .club, id: UUID(uuidString: "66055767-E4A1-417F-B359-51062444A767")!, isVisible: false),
  column6: Card(value: .seven, suit: .club, id: UUID(uuidString: "0D448F9F-B7E5-4E86-8933-15E26B1D4334")!, isVisible: false),
  column7: Card(value: .queen, suit: .club, id: UUID(uuidString: "9934249C-B218-4B7E-8D5F-A39C7461F9A2")!, isVisible: false),
  column8: Card(value: .six, suit: .club, id: UUID(uuidString: "509A123E-EC3B-4ECC-889D-83808CDB29E5")!, isVisible: false),
  column9: Card(value: .king, suit: .club, id: UUID(uuidString: "7A0364FC-6BD9-446D-90CD-D6FCF1174657")!, isVisible: false),
  column10: Card(value: .queen, suit: .club, id: UUID(uuidString: "C284FBD6-85C7-481A-A31E-18771D722FB8")!, isVisible: false)),
  Draw(column1: Card(value: .eight, suit: .club, id: UUID(uuidString: "9282C457-404D-4FB4-A63B-51BF50FF6EB1")!, isVisible: false),
  column2: Card(value: .six, suit: .club, id: UUID(uuidString: "396BE39E-BFEB-461B-BC74-134E55788869")!, isVisible: false),
  column3: Card(value: .queen, suit: .club, id: UUID(uuidString: "660C898C-D000-427B-B6D4-4B64F1D2C95A")!, isVisible: false),
  column4: Card(value: .seven, suit: .club, id: UUID(uuidString: "77CA3367-B651-4EBA-B667-639FAACF4FBA")!, isVisible: false),
  column5: Card(value: .ace, suit: .club, id: UUID(uuidString: "6BC443AC-EB2A-4A0A-9C9F-15E8303B5F62")!, isVisible: false),
  column6: Card(value: .jack, suit: .club, id: UUID(uuidString: "7BE1BCA1-4F02-46DA-A28A-3A8D075A89B9")!, isVisible: false),
  column7: Card(value: .ten, suit: .club, id: UUID(uuidString: "499F10F8-B0B3-4FF5-AFC9-B25F04F232F2")!, isVisible: false),
  column8: Card(value: .six, suit: .club, id: UUID(uuidString: "D1285361-BB34-448F-91D0-D70B3DD7CA7C")!, isVisible: false),
  column9: Card(value: .four, suit: .club, id: UUID(uuidString: "785D5587-F931-46D6-8B66-F68763D99F14")!, isVisible: false),
  column10: Card(value: .queen, suit: .club, id: UUID(uuidString: "435F03BA-337B-40BC-A4D1-B1AF4C6B0AA9")!, isVisible: false)),
  Draw(column1: Card(value: .five, suit: .club, id: UUID(uuidString: "FA7D7DE6-C879-49EC-91AE-767AFE6A7F58")!, isVisible: false),
  column2: Card(value: .eight, suit: .club, id: UUID(uuidString: "2C995FEA-4770-44DC-8F57-9A68267DA4C7")!, isVisible: false),
  column3: Card(value: .three, suit: .club, id: UUID(uuidString: "5CAAC903-2046-4890-B818-A75CD3FE5C80")!, isVisible: false),
  column4: Card(value: .ace, suit: .club, id: UUID(uuidString: "CCB1ABD7-15FA-4626-B3B1-E5DAC7429C29")!, isVisible: false),
  column5: Card(value: .ace, suit: .club, id: UUID(uuidString: "CB3DD4A3-8475-43AA-93A8-03C88600F8D6")!, isVisible: false),
  column6: Card(value: .king, suit: .club, id: UUID(uuidString: "BF93920A-5362-4EFB-A87A-CE9A25370BEC")!, isVisible: false),
  column7: Card(value: .eight, suit: .club, id: UUID(uuidString: "501CA040-45A6-4E3D-9975-0D2CB45A4001")!, isVisible: false),
  column8: Card(value: .five, suit: .club, id: UUID(uuidString: "0D180ACB-572F-4913-8CFC-FA7C8442DA76")!, isVisible: false),
  column9: Card(value: .ten, suit: .club, id: UUID(uuidString: "8078E598-8F30-441E-BDC9-DF78599C3032")!, isVisible: false),
  column10: Card(value: .ten, suit: .club, id: UUID(uuidString: "5CED855C-0DA7-4DED-9A95-534861FF1967")!, isVisible: false)),
  Draw(column1: Card(value: .king, suit: .club, id: UUID(uuidString: "5D9CEE8E-3603-4155-A7FC-44C37028FC71")!, isVisible: false),
  column2: Card(value: .two, suit: .club, id: UUID(uuidString: "93F0BFD5-8CFC-40E9-9209-725B7E68569F")!, isVisible: false),
  column3: Card(value: .nine, suit: .club, id: UUID(uuidString: "620F2707-07B6-4322-A7DF-D124F2FAB6E8")!, isVisible: false),
  column4: Card(value: .jack, suit: .club, id: UUID(uuidString: "9FB1BF9F-8DE3-4851-9FC1-E91DB58CA9AD")!, isVisible: false),
  column5: Card(value: .five, suit: .club, id: UUID(uuidString: "D894C546-DF18-4150-A2B6-EF0AADD706A1")!, isVisible: false),
  column6: Card(value: .four, suit: .club, id: UUID(uuidString: "AEF04C9E-C03E-436E-B686-9DA9E3F446C7")!, isVisible: false),
  column7: Card(value: .queen, suit: .club, id: UUID(uuidString: "E8917294-3864-4CFB-9EA2-3338A51CCC65")!, isVisible: false),
  column8: Card(value: .queen, suit: .club, id: UUID(uuidString: "65B585AC-AADA-47B1-911F-DEFEC0ECC126")!, isVisible: false),
  column9: Card(value: .seven, suit: .club, id: UUID(uuidString: "112177BF-1689-401B-A827-93F78E7FE9A7")!, isVisible: false),
  column10: Card(value: .jack, suit: .club, id: UUID(uuidString: "BED3702E-B513-498B-9A84-283100ACED73")!, isVisible: false)),
  Draw(column1: Card(value: .five, suit: .club, id: UUID(uuidString: "39EC50A7-45AE-436E-8495-A2C963477735")!, isVisible: false),
  column2: Card(value: .queen, suit: .club, id: UUID(uuidString: "69959983-F554-482C-9F98-D318E4AF67B4")!, isVisible: false),
  column3: Card(value: .four, suit: .club, id: UUID(uuidString: "1581535B-B6E9-4972-8253-E9E862649EDF")!, isVisible: false),
  column4: Card(value: .eight, suit: .club, id: UUID(uuidString: "8AF26AF8-64F7-4706-A031-2D9AEB7D349D")!, isVisible: false),
  column5: Card(value: .two, suit: .club, id: UUID(uuidString: "BC0B436E-4069-412B-835B-815B253E93BB")!, isVisible: false),
  column6: Card(value: .seven, suit: .club, id: UUID(uuidString: "F7929F02-3DC7-4B2F-B93B-0D80B7B648DB")!, isVisible: false),
  column7: Card(value: .king, suit: .club, id: UUID(uuidString: "FF893842-FB37-4F91-9B3A-45D563139E29")!, isVisible: false),
  column8: Card(value: .five, suit: .club, id: UUID(uuidString: "0B5DCF80-ED2C-4202-9466-54A86E40301A")!, isVisible: false),
  column9: Card(value: .ace, suit: .club, id: UUID(uuidString: "0B8B303B-9B43-40EA-A050-4530F418F6AC")!, isVisible: false),
  column10: Card(value: .king, suit: .club, id: UUID(uuidString: "D8E62208-489D-4490-9EE4-847641AB3E02")!, isVisible: false))],
    previousMoves: [.move(columnIndex: 6, cardCount: 1, destinationIndex: 5, didRevealCard: true),
  .move(columnIndex: 1, cardCount: 1, destinationIndex: 9, didRevealCard: true),
  .move(columnIndex: 1, cardCount: 1, destinationIndex: 4, didRevealCard: true),
  .move(columnIndex: 1, cardCount: 1, destinationIndex: 9, didRevealCard: true),
  .move(columnIndex: 7, cardCount: 1, destinationIndex: 4, didRevealCard: true),
  .move(columnIndex: 1, cardCount: 1, destinationIndex: 0, didRevealCard: true),
  .move(columnIndex: 9, cardCount: 3, destinationIndex: 1, didRevealCard: true)]
  )
  
  return GameView(gameState: gameState)
}

enum CardData {
  case card(Card)
  case hidden
  case completedSet(CompletedSet)
  
  var card: Card {
    switch self {
    case .card(let card):
      return card
    case .hidden:
      return Card(value: .ace, suit: .club, isVisible: false)
    case .completedSet(let set):
      return Card(value: .king, suit: set.suit, isVisible: true)
    }
  }
}
