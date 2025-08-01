import SwiftUI

struct HomePageView: View {
    @StateObject private var gameRules = GameRules()
    @StateObject private var settings = GameSettings()
    @State private var game: Game?
    @State private var showingConfiguration = false
    @State private var showingHowToPlay = false
    @State private var showingAbout = false
    @State private var isGameActive = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Card back background
                Image("card_back")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .opacity(0.1)
                    .ignoresSafeArea(.all, edges: .all)
                
                            // Black overlay for better readability
            Color.black.opacity(0.05)
                .ignoresSafeArea(.all, edges: .all)
                
                VStack(spacing: 40) {
                    Spacer()
                        .frame(height: geometry.size.height * 0.1)
                // BÉSIGUE Title - Movie Style
                Text("BÉSIGUE")
                    .font(.custom("Copperplate", size: 120))
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                    .overlay(
                        Text("BÉSIGUE")
                            .font(.custom("Copperplate", size: 120))
                            .fontWeight(.bold)
                            .foregroundColor(.yellow)
                            .offset(x: 5, y: 5)
                    )
                    .shadow(color: .black.opacity(0.3), radius: 8, x: 3, y: 3)
                    .padding(.top, 40)
                
                // 4 Marriages
                HStack(spacing: 40) {
                    // Hearts Marriage (15°)
                    MarriageCardView(suit: .hearts, angle: 15)
                    
                    // Clubs Marriage (30°)
                    MarriageCardView(suit: .clubs, angle: 30)
                    
                    // Diamonds Marriage (-15°)
                    MarriageCardView(suit: .diamonds, angle: -15)
                    
                    // Spades Marriage (0°)
                    MarriageCardView(suit: .spades, angle: 0)
                }
                .padding(.horizontal, 60)
                
                // 4 Circular Button Tokens
                HStack(spacing: 50) {
                    // Play Button
                    CircularButtonView(
                        icon: "play.fill",
                        outlineColor: .black,
                        action: { startGame() }
                    )
                    
                    // Configuration Button
                    CircularButtonView(
                        icon: "gearshape.fill",
                        outlineColor: .red,
                        action: { showingConfiguration = true }
                    )
                    
                    // How to Play Button
                    CircularButtonView(
                        icon: "questionmark",
                        outlineColor: .black,
                        action: { showingHowToPlay = true }
                    )
                    
                    // About Button
                    CircularButtonView(
                        icon: "info.circle.fill",
                        outlineColor: .red,
                        action: { showingAbout = true }
                    )
                }
                .padding(.horizontal, 60)
                
                Spacer()
                
                // Bottom Zone: Privacy Policy
                VStack(spacing: 15) {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                        .padding(.horizontal, 60)
                    
                    Button("Privacy Policy") {
                        // Open privacy policy (could be a sheet or web view)
                        print("Privacy Policy tapped")
                    }
                    .font(.body)
                    .foregroundColor(.gray)
                    .underline()
                }
                .padding(.bottom, 20)
                
                Spacer()
                    .frame(height: geometry.size.height * 0.15)
            }
        }
        .sheet(isPresented: $showingConfiguration) {
            GameSettingsView(gameRules: gameRules) {
                // Save configuration
                print("Configuration saved")
            }
        }
        .sheet(isPresented: $showingHowToPlay) {
            HowToPlayView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .fullScreenCover(isPresented: $isGameActive) {
            if let game = game {
                GameBoardView(
                    game: game, 
                    settings: settings, 
                    gameRules: gameRules,
                    onEndGame: { isGameActive = false }
                )
            }
        }
        .onAppear {
            setupDefaultConfiguration()
        }
        }
    }
    
    private func setupDefaultConfiguration() {
        // Set up default 2-player configuration
        gameRules.playerCount = 2
        gameRules.playerConfigurations = [
            PlayerConfiguration(name: "Player 1", type: .human, position: 0),
            PlayerConfiguration(name: "Player 2", type: .human, position: 1)
        ]
    }
    
    private func startGame() {
        // Create new game with current configuration
        game = Game(gameRules: gameRules)
        if let game = game {
            game.updatePlayersFromConfiguration()
            game.startNewGame()
        }
        isGameActive = true
    }
}

// MARK: - Marriage Card View
struct MarriageCardView: View {
    let suit: CardSuit
    let angle: Double
    
    var body: some View {
        ZStack {
            // King card (background)
            ZStack {
                Image(getKingImageName())
                    .resizable()
                    .aspectRatio(2.5/3.5, contentMode: .fit)
                    .frame(width: 120, height: 168)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(getSuitColor(), lineWidth: 1)
                    )
            }
            .offset(x: -12, y: -12)
            .rotationEffect(.degrees(angle))
            
            // Queen card (overlaid) - opposite rotation
            ZStack {
                Image(getQueenImageName())
                    .resizable()
                    .aspectRatio(2.5/3.5, contentMode: .fit)
                    .frame(width: 120, height: 168)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(getSuitColor(), lineWidth: 1)
                    )
            }
            .offset(x: 12, y: 12)
            .rotationEffect(.degrees(-angle))
        }
        .frame(width: 180, height: 200) // Ensure enough space for the overlayed cards
    }
    
    private func getKingImageName() -> String {
        switch suit {
        case .spades: return "spades_king"
        case .hearts: return "hearts_king"
        case .diamonds: return "diamonds_king"
        case .clubs: return "clubs_king"
        }
    }
    
    private func getQueenImageName() -> String {
        switch suit {
        case .spades: return "spades_queen"
        case .hearts: return "hearts_queen"
        case .diamonds: return "diamonds_queen"
        case .clubs: return "clubs_queen"
        }
    }
    
    private func getSuitColor() -> Color {
        switch suit {
        case .spades: return .black
        case .hearts: return .red
        case .diamonds: return .red
        case .clubs: return .black
        }
    }
}

// MARK: - Circular Button View
struct CircularButtonView: View {
    let icon: String
    let outlineColor: Color
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Brief delay to show pressed state
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
            action()
        }) {
            ZStack {
                Circle()
                    .fill(isPressed ? outlineColor : Color.clear)
                    .stroke(outlineColor, lineWidth: 8)
                    .frame(width: 100, height: 100)
                
                Image(systemName: icon)
                    .font(.system(size: 40, weight: .heavy))
                    .foregroundColor(isPressed ? .white : outlineColor)
            }
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - How to Play View
struct HowToPlayView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("How to Play Bésigue")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.bottom, 10)
                    
                    Text("Bésigue is a trick-taking card game for 2-4 players. The goal is to score points by winning tricks and forming melds.")
                        .font(.body)
                    
                    Text("Game Setup:")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("• Each player is dealt 9 cards\n• The remaining cards form the draw pile\n• Players take turns playing cards and drawing new ones")
                        .font(.body)
                    
                    Text("Scoring:")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("• Win tricks to score points\n• Form melds (sets of cards) for bonus points\n• The player with the highest score at the end wins")
                        .font(.body)
                    
                    Text("Playing a Trick:")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("• Each player plays one card\n• The highest card of the led suit wins the trick\n• Trump cards beat all other cards")
                        .font(.body)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("✕") {
                dismiss()
            })
        }
    }
}

// MARK: - About View
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showEasterEgg = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("About Bésigue")
                    .font(.title)
                    .fontWeight(.bold)
                
                VStack(spacing: 15) {
                    Text("Version 1.0")
                        .font(.headline)
                    
                    Text("A modern implementation of the classic French card game Bésigue.")
                        .font(.body)
                        .multilineTextAlignment(.center)
                    
                    Text("Developed with SwiftUI")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Interactive element - tap to reveal easter egg
                Button(action: {
                    withAnimation {
                        showEasterEgg.toggle()
                    }
                }) {
                    Text("Tap for a surprise!")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(15)
                }
                
                if showEasterEgg {
                    Text("🎉 You found the easter egg! 🎉")
                        .font(.headline)
                        .foregroundColor(.purple)
                        .transition(.scale.combined(with: .opacity))
                }
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("✕") {
                dismiss()
            })
        }
    }
}

// MARK: - Card Suit Enum
enum CardSuit {
    case spades, hearts, diamonds, clubs
}

#Preview {
    HomePageView()
} 