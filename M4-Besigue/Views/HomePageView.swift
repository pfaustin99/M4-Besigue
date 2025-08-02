import SwiftUI

struct HomePageView: View {
    @StateObject private var gameRules = GameRules()
    @StateObject private var settings = GameSettings()
    @State private var game: Game?
    @State private var showingConfiguration = false
    @State private var showingHowToPlay = false
    @State private var showingAbout = false
    @State private var isGameActive = false
    @State private var showingPrivacyPolicy = false
    @State private var isConfiguringGame = false
    @State private var configurationMessage = ""
    
    var body: some View {
        GeometryReader { geometry in
            // TODO: Portrait support will be removed and landscape enforced once image assets are updated.
            let isLandscape = geometry.size.width > geometry.size.height
            ZStack {
                // Card back background (responsive to orientation)
                Image(isLandscape ? "card_back_landscape" : "card_back_portrait")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .ignoresSafeArea(.all)
                // Black overlay for better readability
                Color.black.opacity(0.25)
                    .ignoresSafeArea(.all, edges: .all)
                // Main scrollable content
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .center, spacing: geometry.size.height * 0.05) {
                        Spacer()
                            .frame(height: geometry.size.height * 0.1)
                        // Title and tagline, centered in VStack
                        VStack(alignment: .center) {
                            // BÉSIGUE Title - Gold with red shadow, Copperplate font (simplified)
                            // NOTE: Portrait support will be removed and landscape enforced once image assets are updated.
                            Text("BÉSIGUE")
                                .font(.system(size: min(geometry.size.width * (isLandscape ? 0.42 : 0.32), isLandscape ? 140 : 110), weight: .black, design: .serif))
                                .fontWeight(.bold)
                                .foregroundColor(Color(red: 241/255, green: 181/255, blue: 23/255)) // Gold
                                .shadow(color: Color(red: 210/255, green: 16/255, blue: 52/255), radius: 2, x: 2, y: 2) // Red
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.horizontal, isLandscape ? geometry.size.width * 0.05 : 0)
                                .padding(.top, geometry.size.height * 0.05)
                                .multilineTextAlignment(.center)

                            Text("A Strategic Classic Card Game")
                                .font(.custom("Cinzel Decorative", size: min(geometry.size.width * 0.05, 28)))
                                .foregroundColor(.white)
                                .shadow(color: Color(red: 0/255, green: 32/255, blue: 159/255), radius: 2, x: 1, y: 1)
                                .padding(.bottom, geometry.size.height * 0.01)
                                .minimumScaleFactor(0.5)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .multilineTextAlignment(.center)
                        }
                        // 4 Marriages - Centered using GeometryReader and frame
                        GeometryReader { innerGeo in
                            HStack(spacing: geometry.size.width * 0.05) {
                                // Hearts Marriage (10°)
                                MarriageCardView(suit: .hearts, angle: 10)
                                // Clubs Marriage (20°)
                                MarriageCardView(suit: .clubs, angle: 20)
                                // Diamonds Marriage (-10°)
                                MarriageCardView(suit: .diamonds, angle: -10)
                                // Spades Marriage (0°)
                                MarriageCardView(suit: .spades, angle: 0)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.horizontal, geometry.size.width * 0.05)
                        }
                        .frame(height: 200) // Enough for cards
                        // 4 Circular Button Tokens - Centered using GeometryReader and frame
                        GeometryReader { innerGeo in
                            HStack(spacing: geometry.size.width * 0.07) {
                                // Play Button
                                CircularButtonView(
                                    icon: "play.fill",
                                    outlineColor: .black,
                                    action: { startGame() },
                                    iconFontSize: min(geometry.size.width * 0.10, 40)
                                )
                                // Configuration Button
                                CircularButtonView(
                                    icon: "gearshape.fill",
                                    outlineColor: .red,
                                    action: { showingConfiguration = true },
                                    iconFontSize: min(geometry.size.width * 0.10, 40)
                                )
                                // How to Play Button
                                CircularButtonView(
                                    icon: "questionmark",
                                    outlineColor: .black,
                                    action: { showingHowToPlay = true },
                                    iconFontSize: min(geometry.size.width * 0.10, 40)
                                )
                                // About Button
                                CircularButtonView(
                                    icon: "info.circle.fill",
                                    outlineColor: .red,
                                    action: { showingAbout = true },
                                    iconFontSize: min(geometry.size.width * 0.10, 40)
                                )
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.horizontal, geometry.size.width * 0.05)
                        }
                        .frame(height: 100)
                        // Remove bottom spacers since footer is positioned as overlay
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, geometry.size.width * 0.05)
                }
                // Footer: Privacy Policy and Restore Purchase anchored to bottom
            }
            .overlay(
                HStack(spacing: geometry.size.width * 0.1) {
                    Button("Privacy Policy") {
                        showingPrivacyPolicy = true
                    }
                    .font(.footnote.bold())
                    .foregroundColor(.white)
                    .underline()
                    Button("Restore Purchase") {
                        restorePurchase()
                    }
                    .font(.footnote.bold())
                    .foregroundColor(.white)
                    .underline()
                }
                .padding(.horizontal, geometry.size.width * 0.05)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.6))
                .padding(.bottom, geometry.safeAreaInsets.bottom + 5),
                alignment: .bottom
            )
            .overlay(
                // Configuration subview
                Group {
                    if isConfiguringGame {
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            
                            Text(configurationMessage)
                                .font(.title2)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.8))
                        .transition(.opacity)
                    }
                },
                alignment: .center
            )
        }
        .sheet(isPresented: $showingConfiguration) {
            GameSettingsView(gameRules: gameRules) {
                // Configuration saved
                print("🎮 Configuration saved - gameRules.playerCount: \(gameRules.playerCount)")
                print("🎮 Configuration saved - gameRules.playerConfigurations.count: \(gameRules.playerConfigurations.count)")
                for (index, config) in gameRules.playerConfigurations.enumerated() {
                    print("🎮 Configuration \(index): \(config.name) (\(config.type)) at position \(config.position)")
                }
            }
        }
        .sheet(isPresented: $showingHowToPlay) {
            HowToPlayView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .fullScreenCover(isPresented: $isGameActive) {
            if let game = game {
                GameBoardView(
                    game: game,
                    settings: settings,
                    gameRules: gameRules,
                    onEndGame: { isGameActive = false }
                )
                .onAppear {
                    print("🎮 fullScreenCover triggered - isGameActive: \(isGameActive)")
                    print("🎮 Game object: \(game != nil ? "exists" : "nil")")
                    print("🎮 Game object ID at fullScreenCover: \(ObjectIdentifier(game))")
                    print("🎮 Presenting GameBoardView with \(game.players.count) players")
                }
            } else {
                // Fallback view if game is nil
                VStack {
                    Text("Error: Game not initialized")
                        .font(.title)
                        .foregroundColor(.red)
                        .padding()

                    Button("Back to Menu") {
                        isGameActive = false
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.8))
                .onAppear {
                    print("🎮 ERROR: Game is nil in fullScreenCover")
                }
            }
        }
    }
    
    private func startGame() {
        print("🎮 startGame() called")
        print("🎮 startGame - gameRules.playerCount: \(gameRules.playerCount)")
        print("🎮 startGame - gameRules.playerConfigurations.count: \(gameRules.playerConfigurations.count)")
        for (index, config) in gameRules.playerConfigurations.enumerated() {
            print("🎮 startGame - Configuration \(index): \(config.name) (\(config.type)) at position \(config.position)")
        }
        
        // Show configuration subview
        isConfiguringGame = true
        configurationMessage = "Configuring game for \(gameRules.playerCount) players..."
        
        // Create game if it doesn't exist
        if game == nil {
            game = Game(gameRules: gameRules)
            print("🎮 Game created: \(game != nil)")
            print("🎮 Game object ID: \(ObjectIdentifier(game!))")
        }
        
        // Initialize game from configuration
        game?.initializeFromConfiguration()
        print("🎮 Game initialized from configuration")
        
        // Start the game
        game?.startNewGame()
        print("🎮 Game started")
        
        // Wait 3 seconds before hiding configuration subview and showing game
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            isConfiguringGame = false
            isGameActive = true
            print("🎮 isGameActive set to true")
            print("🎮 Game still exists: \(game != nil)")
        }
    }
    
    private func restorePurchase() {
        // Stub for restore purchase functionality
        print("Restore Purchase tapped")
    }
}


// MARK: - Privacy Policy View (stub)
struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text("Privacy Policy content goes here.")
                    .padding()
            }
            .navigationBarTitle("Privacy Policy", displayMode: .inline)
            .navigationBarItems(trailing: Button("Close") {
                dismiss()
            })
        }
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
    var iconFontSize: CGFloat = 40
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
                    .fill(Color.white)
                    .shadow(radius: 4)
                    .frame(width: 100, height: 100)

                Image(systemName: icon)
                    .font(.system(size: iconFontSize, weight: .heavy))
                    .foregroundColor(outlineColor)
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
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
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
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                
                VStack(spacing: 15) {
                    Text("Version 1.0")
                        .font(.headline)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
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
