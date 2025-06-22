import SwiftUI

struct GameBoardView: View {
    @ObservedObject var game: Game
    @State private var selectedCards: [Card] = []
    @State private var showingMeldOptions = false
    @State private var showingTrumpSelection = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Top section - AI players and game info
                topSection
                
                // Center section - Game board and current trick
                centerSection
                    .frame(height: geometry.size.height * 0.4)
                
                // Bottom section - Human player's hand
                bottomSection
                    .frame(height: geometry.size.height * 0.3)
            }
        }
        .background(Color.green.opacity(0.3))
        .sheet(isPresented: $showingMeldOptions) {
            MeldOptionsView(game: game, selectedCards: $selectedCards)
        }
        .sheet(isPresented: $showingTrumpSelection) {
            TrumpSelectionView(game: game)
        }
    }
    
    // MARK: - Top Section
    private var topSection: some View {
        VStack(spacing: 10) {
            // Game info
            HStack {
                Text("Round \(game.roundNumber)")
                    .font(.headline)
                
                Spacer()
                
                if let trump = game.trumpSuit {
                    Text("Trump: \(trump.rawValue.capitalized)")
                        .font(.headline)
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                Text("Phase: \(phaseName)")
                    .font(.headline)
            }
            .padding(.horizontal)
            
            // AI players
            HStack(spacing: 20) {
                ForEach(game.players.dropFirst()) { player in
                    AIPlayerView(player: player, isCurrentPlayer: player.isCurrentPlayer)
                }
            }
        }
        .padding(.vertical, 10)
        .background(Color.gray.opacity(0.1))
    }
    
    // MARK: - Center Section
    private var centerSection: some View {
        VStack(spacing: 15) {
            // Current trick
            TrickView(
                cards: game.currentTrick,
                playerNames: trickPlayerNames
            )
            
            // Game controls
            gameControls
            
            // Deck info
            HStack {
                Text("Cards in deck: \(game.deck.remainingCount)")
                    .font(.caption)
                
                Spacer()
                
                if game.currentPhase == .melding {
                    Button("Declare Melds") {
                        showingMeldOptions = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Bottom Section
    private var bottomSection: some View {
        VStack(spacing: 10) {
            // Human player info
            if let humanPlayer = game.players.first {
                HStack {
                    Text("Your Hand (\(humanPlayer.hand.count) cards)")
                        .font(.headline)
                    
                    Spacer()
                    
                    Text("Score: \(humanPlayer.totalPoints)")
                        .font(.headline)
                }
                .padding(.horizontal)
                
                // Human player's hand
                HandView(
                    cards: humanPlayer.hand,
                    playableCards: game.getPlayableCards(),
                    selectedCards: selectedCards
                ) { card in
                    handleCardTap(card)
                }
            }
        }
        .background(Color.blue.opacity(0.1))
    }
    
    // MARK: - Game Controls
    private var gameControls: some View {
        HStack(spacing: 15) {
            if game.currentPhase == .setup {
                Button("Start New Game") {
                    game.startNewGame()
                }
                .buttonStyle(.borderedProminent)
            }
            
            if game.currentPhase == .melding && game.trumpSuit == nil {
                Button("Select Trump") {
                    showingTrumpSelection = true
                }
                .buttonStyle(.borderedProminent)
            }
            
            if game.currentPhase == .playing && game.currentPlayer.type == .human {
                Button("Play Selected Card") {
                    playSelectedCard()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedCards.isEmpty)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Computed Properties
    private var phaseName: String {
        switch game.currentPhase {
        case .setup: return "Setup"
        case .dealing: return "Dealing"
        case .melding: return "Melding"
        case .playing: return "Playing"
        case .scoring: return "Scoring"
        case .gameOver: return "Game Over"
        }
    }
    
    private var trickPlayerNames: [String] {
        guard !game.currentTrick.isEmpty else { return [] }
        
        var names: [String] = []
        for i in 0..<game.currentTrick.count {
            let playerIndex = (game.currentTrickLeader + i) % game.playerCount
            names.append(game.players[playerIndex].name)
        }
        return names
    }
    
    // MARK: - Actions
    private func handleCardTap(_ card: Card) {
        if game.currentPhase == .playing && game.currentPlayer.type == .human {
            // In playing phase, select card to play
            if selectedCards.contains(card) {
                selectedCards.removeAll { $0 == card }
            } else {
                selectedCards = [card]
            }
        } else if game.currentPhase == .melding {
            // In melding phase, select cards for melds
            if selectedCards.contains(card) {
                selectedCards.removeAll { $0 == card }
            } else {
                selectedCards.append(card)
            }
        }
    }
    
    private func playSelectedCard() {
        guard let card = selectedCards.first,
              let humanPlayer = game.players.first else { return }
        
        game.playCard(card, from: humanPlayer)
        selectedCards.removeAll()
    }
}

// MARK: - AI Player View
struct AIPlayerView: View {
    @ObservedObject var player: Player
    let isCurrentPlayer: Bool
    
    var body: some View {
        VStack(spacing: 5) {
            Text(player.name)
                .font(.headline)
                .foregroundColor(isCurrentPlayer ? .blue : .primary)
            
            Text("\(player.hand.count) cards")
                .font(.caption)
            
            Text("Score: \(player.totalPoints)")
                .font(.caption)
            
            // Show card backs for AI players
            HStack(spacing: 4) {
                ForEach(0..<min(player.hand.count, 3), id: \.self) { _ in
                    CardBackView {
                        // No action for AI cards
                    }
                    .frame(width: 40, height: 60)
                }
                
                if player.hand.count > 3 {
                    Text("+\(player.hand.count - 3)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(isCurrentPlayer ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Meld Options View
struct MeldOptionsView: View {
    @ObservedObject var game: Game
    @Binding var selectedCards: [Card]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack {
                if let humanPlayer = game.players.first {
                    let possibleMelds = game.getPossibleMelds(for: humanPlayer)
                    
                    if possibleMelds.isEmpty {
                        Text("No melds available")
                            .font(.headline)
                            .padding()
                    } else {
                        List(possibleMelds) { meld in
                            MeldRowView(meld: meld) {
                                game.declareMeld(meld, by: humanPlayer)
                                dismiss()
                            }
                        }
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

// MARK: - Meld Row View
struct MeldRowView: View {
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
            
            HStack(spacing: 4) {
                ForEach(meld.cards) { card in
                    Image(card.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 45)
                        .cornerRadius(4)
                }
            }
            
            Button("Declare") {
                onDeclare()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Trump Selection View
struct TrumpSelectionView: View {
    @ObservedObject var game: Game
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Select Trump Suit")
                    .font(.title)
                    .padding()
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 20) {
                    ForEach(Suit.allCases, id: \.self) { suit in
                        Button {
                            game.setTrumpSuit(suit)
                            dismiss()
                        } label: {
                            VStack {
                                Text(suit.rawValue.capitalized)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                // Show a sample card of this suit
                                Image("\(suit.rawValue)_ace")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 60, height: 90)
                                    .cornerRadius(8)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Trump Selection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    GameBoardView(game: Game())
} 