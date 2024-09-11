import SwiftUI
import SwiftData

struct StartMenu: View {
  @State private var existingGame: GameState?
  
  var body: some View {
    NavigationStack {
      VStack {
        Spacer()
        
        Text("Spider Solitaire")
          .font(.largeTitle)
          .foregroundStyle(.black)
        
        Spacer()
        
        if let existingGame {
          NavigationLink {
            
          } label: {
            Text("Continue Game")
          }
        }
        
        NavigationLink {
          
        } label: {
          Text("New Game")
        }
        
        Button("Settings (WIP)") {
          
        }
        
        Spacer()
        Spacer()
      }
      .buttonStyle(FullWidthButtonStyle())
      .foregroundStyle(.white)
      .padding(.horizontal)
    }
  }
}

#Preview {
  StartMenu()
    .modelContainer(for: Item.self, inMemory: true)
}
