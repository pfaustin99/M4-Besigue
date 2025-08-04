import SwiftUI

/// MeldOptionsView2 - Clean meld options selection view
struct MeldOptionsView2: View {
    @ObservedObject var game: Game
    @ObservedObject var settings: GameSettings
    @Binding var selectedCards: [PlayerCard]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if let humanPlayer = game.players.first {
                    let possibleMelds = game.getPossibleMelds(for: humanPlayer)
                        .filter { game.canDeclareMeld($0, by: humanPlayer) }
                    
                    if possibleMelds.isEmpty {
                        MeldOptionsEmptyView()
                    } else {
                        MeldOptionsListView(
                            melds: possibleMelds,
                            humanPlayer: humanPlayer,
                            game: game,
                            dismiss: dismiss
                        )
                    }
                }
            }
            .navigationTitle("Declare Melds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// MeldOptionsEmptyView - Shows when no melds are available
struct MeldOptionsEmptyView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "cards.fill")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("No melds available")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("Select 2-4 cards to create a meld")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

/// MeldOptionsListView - Lists available melds
struct MeldOptionsListView: View {
    let melds: [Meld]
    let humanPlayer: Player
    let game: Game
    let dismiss: DismissAction
    
    var body: some View {
        List(melds) { meld in
            MeldOptionRowView(
                meld: meld,
                onDeclare: {
                    let meldWithRound = Meld(
                        cardIDs: meld.cardIDs,
                        type: meld.type,
                        pointValue: meld.pointValue,
                        roundNumber: game.roundNumber
                    )
                    game.declareMeld(meldWithRound, by: humanPlayer)
                    dismiss()
                }
            )
        }
    }
}

/// MeldOptionRowView - Individual meld option row
struct MeldOptionRowView: View {
    let meld: Meld
    let onDeclare: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(meld.type.name)
                    .font(.headline)
                
                Text("\(meld.pointValue) points")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Declare") {
                onDeclare()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 4)
    }
} 