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
            let deviceType = getDeviceType(from: geometry.size)
            let isLandscape = geometry.size.width > geometry.size.height
            
            ZStack {
                // Card back background (responsive to orientation and device)
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
                    VStack(alignment: .center, spacing: getSpacing(for: deviceType, geometry: geometry)) {
                        Spacer()
                            .frame(height: getTopSpacing(for: deviceType, geometry: geometry))
                        
                        // Title and tagline section
                        titleSection(deviceType: deviceType, geometry: geometry, isLandscape: isLandscape)
                        
                        // Marriage cards section
                        marriageCardsSection(deviceType: deviceType, geometry: geometry)
                        
                        // Button tokens section
                        buttonTokensSection(deviceType: deviceType, geometry: geometry)
                        
                        // Bottom spacer to account for footer
                        Spacer()
                            .frame(height: 100)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, getHorizontalPadding(for: deviceType, geometry: geometry))
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 20)
                }
                
                // Configuration overlay
                configurationOverlay
            }
            .overlay(footerOverlay(geometry: geometry, deviceType: deviceType), alignment: .bottom)
        }
        .sheet(isPresented: $showingConfiguration) {
            GameSettingsView(gameRules: gameRules) {
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
    
    // MARK: - Device Type Detection
    private func getDeviceType(from size: CGSize) -> DeviceType {
        let minDimension = min(size.width, size.height)
        let maxDimension = max(size.width, size.height)
        
        if maxDimension >= 1024 {
            return .iPad
        } else if minDimension >= 414 {
            return .iPhonePlus
        } else if minDimension >= 375 {
            return .iPhoneRegular
        } else {
            return .iPhoneCompact
        }
    }
    
    // MARK: - Responsive Layout Components
    @ViewBuilder
    private func titleSection(deviceType: DeviceType, geometry: GeometryProxy, isLandscape: Bool) -> some View {
        VStack(alignment: .center, spacing: getTitleSpacing(for: deviceType)) {
            Text("Bésigue")
                .font(.system(
                    size: getTitleFontSize(for: deviceType, geometry: geometry, isLandscape: isLandscape),
                    weight: .black,
                    design: .serif
                ))
                .fontWeight(.bold)
                .foregroundColor(Color(red: 241/255, green: 181/255, blue: 23/255))
                .shadow(color: Color(red: 210/255, green: 16/255, blue: 52/255), radius: 4, x: 4, y: 4)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)

            Text("A Strategic Classic Card Game")
                .font(.custom("Cinzel Decorative", size: getSubtitleFontSize(for: deviceType, geometry: geometry)))
                .foregroundColor(.white)
                .shadow(color: Color(red: 0/255, green: 32/255, blue: 159/255), radius: 2, x: 1, y: 1)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder
    private func marriageCardsSection(deviceType: DeviceType, geometry: GeometryProxy) -> some View {
        let cardSize = getMarriageCardSize(for: deviceType)
        let spacing = getMarriageCardSpacing(for: deviceType, geometry: geometry)
        
        if deviceType == .iPad {
            // iPad: Single row layout
            HStack(spacing: spacing) {
                MarriageCardView(suit: .hearts, angle: 10, cardSize: cardSize)
                MarriageCardView(suit: .clubs, angle: 20, cardSize: cardSize)
                MarriageCardView(suit: .diamonds, angle: -10, cardSize: cardSize)
                MarriageCardView(suit: .spades, angle: -20, cardSize: cardSize)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, getHorizontalPadding(for: deviceType, geometry: geometry))
        } else {
            // iPhone: Two rows layout for better fit
            VStack(spacing: spacing / 2) {
                HStack(spacing: spacing) {
                    MarriageCardView(suit: .hearts, angle: 10, cardSize: cardSize)
                    MarriageCardView(suit: .clubs, angle: 20, cardSize: cardSize)
                }
                HStack(spacing: spacing) {
                    MarriageCardView(suit: .diamonds, angle: -10, cardSize: cardSize)
                    MarriageCardView(suit: .spades, angle: -20, cardSize: cardSize)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, getHorizontalPadding(for: deviceType, geometry: geometry))
        }
    }
    
    @ViewBuilder
    private func buttonTokensSection(deviceType: DeviceType, geometry: GeometryProxy) -> some View {
        let buttonSize = getButtonSize(for: deviceType)
        let iconSize = getButtonIconSize(for: deviceType)
        let labelFontSize = getButtonLabelFontSize(for: deviceType)
        let spacing = getButtonSpacing(for: deviceType, geometry: geometry)
        
        if deviceType == .iPad {
            // iPad: Single row layout
            HStack(spacing: spacing) {
                buttonColumn("play.fill", "Play", .black, { startGame() }, buttonSize, iconSize, labelFontSize)
                buttonColumn("gearshape.fill", "Settings", .red, { showingConfiguration = true }, buttonSize, iconSize, labelFontSize)
                buttonColumn("questionmark", "How to Play", .black, { showingHowToPlay = true }, buttonSize, iconSize, labelFontSize)
                buttonColumn("info.circle.fill", "About", .red, { showingAbout = true }, buttonSize, iconSize, labelFontSize)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, getHorizontalPadding(for: deviceType, geometry: geometry))
        } else {
            // iPhone: Two rows layout
            VStack(spacing: spacing / 2) {
                HStack(spacing: spacing) {
                    buttonColumn("play.fill", "Play", .black, { startGame() }, buttonSize, iconSize, labelFontSize)
                    buttonColumn("gearshape.fill", "Settings", .red, { showingConfiguration = true }, buttonSize, iconSize, labelFontSize)
                }
                HStack(spacing: spacing) {
                    buttonColumn("questionmark", "How to Play", .black, { showingHowToPlay = true }, buttonSize, iconSize, labelFontSize)
                    buttonColumn("info.circle.fill", "About", .red, { showingAbout = true }, buttonSize, iconSize, labelFontSize)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, getHorizontalPadding(for: deviceType, geometry: geometry))
        }
    }
    
    @ViewBuilder
    private func buttonColumn(_ icon: String, _ label: String, _ color: Color, _ action: @escaping () -> Void, _ buttonSize: CGFloat, _ iconSize: CGFloat, _ labelFontSize: CGFloat) -> some View {
        VStack(spacing: 8) {
            CircularButtonView(
                icon: icon,
                outlineColor: color,
                action: action,
                buttonSize: buttonSize,
                iconFontSize: iconSize
            )
            Text(label)
                .font(.system(size: labelFontSize, weight: .bold, design: .serif))
                .foregroundColor(Color(red: 241/255, green: 181/255, blue: 23/255))
                .shadow(color: Color(red: 210/255, green: 16/255, blue: 52/255), radius: 2, x: 1, y: 1)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
                .lineLimit(2)
        }
        .layoutPriority(1)
    }
    
    @ViewBuilder
    private var configurationOverlay: some View {
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
        }
    }
    
    @ViewBuilder
    private func footerOverlay(geometry: GeometryProxy, deviceType: DeviceType) -> some View {
        HStack(spacing: getFooterSpacing(for: deviceType, geometry: geometry)) {
            Button("Privacy Policy") {
                showingPrivacyPolicy = true
            }
            .font(getFooterFont(for: deviceType))
            .foregroundColor(.white)
            .underline()
            
            Button("Restore Purchase") {
                restorePurchase()
            }
            .font(getFooterFont(for: deviceType))
            .foregroundColor(.white)
            .underline()
        }
        .padding(.horizontal, getHorizontalPadding(for: deviceType, geometry: geometry))
        .padding(.vertical, getFooterVerticalPadding(for: deviceType))
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.6))
        .padding(.bottom, geometry.safeAreaInsets.bottom + 5)
    }
    
    // MARK: - Responsive Sizing Functions
    private func getSpacing(for deviceType: DeviceType, geometry: GeometryProxy) -> CGFloat {
        switch deviceType {
        case .iPad:
            return geometry.size.height * 0.06
        case .iPhonePlus:
            return geometry.size.height * 0.045
        case .iPhoneRegular:
            return geometry.size.height * 0.04
        case .iPhoneCompact:
            return geometry.size.height * 0.035
        }
    }
    
    private func getTopSpacing(for deviceType: DeviceType, geometry: GeometryProxy) -> CGFloat {
        switch deviceType {
        case .iPad:
            return geometry.size.height * 0.08
        case .iPhonePlus:
            return geometry.size.height * 0.06
        case .iPhoneRegular:
            return geometry.size.height * 0.05
        case .iPhoneCompact:
            return geometry.size.height * 0.04
        }
    }
    
    private func getHorizontalPadding(for deviceType: DeviceType, geometry: GeometryProxy) -> CGFloat {
        switch deviceType {
        case .iPad:
            return geometry.size.width * 0.08
        case .iPhonePlus:
            return geometry.size.width * 0.06
        case .iPhoneRegular:
            return geometry.size.width * 0.05
        case .iPhoneCompact:
            return geometry.size.width * 0.04
        }
    }
    
    private func getTitleFontSize(for deviceType: DeviceType, geometry: GeometryProxy, isLandscape: Bool) -> CGFloat {
        let baseSizeMultiplier: CGFloat = isLandscape ? 0.35 : 0.3
        let maxSize: CGFloat
        
        switch deviceType {
        case .iPad:
            maxSize = isLandscape ? 200 : 160
        case .iPhonePlus:
            maxSize = isLandscape ? 140 : 110
        case .iPhoneRegular:
            maxSize = isLandscape ? 120 : 95
        case .iPhoneCompact:
            maxSize = isLandscape ? 100 : 80
        }
        
        return min(geometry.size.width * baseSizeMultiplier, maxSize)
    }
    
    private func getSubtitleFontSize(for deviceType: DeviceType, geometry: GeometryProxy) -> CGFloat {
        let maxSize: CGFloat
        let multiplier: CGFloat = 0.04
        
        switch deviceType {
        case .iPad:
            maxSize = 36
        case .iPhonePlus:
            maxSize = 28
        case .iPhoneRegular:
            maxSize = 24
        case .iPhoneCompact:
            maxSize = 20
        }
        
        return min(geometry.size.width * multiplier, maxSize)
    }
    
    private func getTitleSpacing(for deviceType: DeviceType) -> CGFloat {
        switch deviceType {
        case .iPad:
            return 16
        case .iPhonePlus:
            return 12
        case .iPhoneRegular:
            return 10
        case .iPhoneCompact:
            return 8
        }
    }
    
    private func getMarriageCardSize(for deviceType: DeviceType) -> CGSize {
        switch deviceType {
        case .iPad:
            return CGSize(width: 140, height: 196)
        case .iPhonePlus:
            return CGSize(width: 100, height: 140)
        case .iPhoneRegular:
            return CGSize(width: 85, height: 119)
        case .iPhoneCompact:
            return CGSize(width: 70, height: 98)
        }
    }
    
    private func getMarriageCardSpacing(for deviceType: DeviceType, geometry: GeometryProxy) -> CGFloat {
        switch deviceType {
        case .iPad:
            return geometry.size.width * 0.04
        case .iPhonePlus:
            return geometry.size.width * 0.03
        case .iPhoneRegular:
            return geometry.size.width * 0.025
        case .iPhoneCompact:
            return geometry.size.width * 0.02
        }
    }
    
    private func getButtonSize(for deviceType: DeviceType) -> CGFloat {
        switch deviceType {
        case .iPad:
            return 120
        case .iPhonePlus:
            return 90
        case .iPhoneRegular:
            return 80
        case .iPhoneCompact:
            return 70
        }
    }
    
    private func getButtonIconSize(for deviceType: DeviceType) -> CGFloat {
        switch deviceType {
        case .iPad:
            return 48
        case .iPhonePlus:
            return 36
        case .iPhoneRegular:
            return 32
        case .iPhoneCompact:
            return 28
        }
    }
    
    private func getButtonLabelFontSize(for deviceType: DeviceType) -> CGFloat {
        switch deviceType {
        case .iPad:
            return 32
        case .iPhonePlus:
            return 24
        case .iPhoneRegular:
            return 20
        case .iPhoneCompact:
            return 18
        }
    }
    
    private func getButtonSpacing(for deviceType: DeviceType, geometry: GeometryProxy) -> CGFloat {
        switch deviceType {
        case .iPad:
            return geometry.size.width * 0.06
        case .iPhonePlus:
            return geometry.size.width * 0.08
        case .iPhoneRegular:
            return geometry.size.width * 0.06
        case .iPhoneCompact:
            return geometry.size.width * 0.05
        }
    }
    
    private func getFooterSpacing(for deviceType: DeviceType, geometry: GeometryProxy) -> CGFloat {
        switch deviceType {
        case .iPad:
            return geometry.size.width * 0.12
        case .iPhonePlus:
            return geometry.size.width * 0.1
        case .iPhoneRegular:
            return geometry.size.width * 0.08
        case .iPhoneCompact:
            return geometry.size.width * 0.06
        }
    }
    
    private func getFooterFont(for deviceType: DeviceType) -> Font {
        switch deviceType {
        case .iPad:
            return .system(size: 16, weight: .bold)
        case .iPhonePlus:
            return .system(size: 14, weight: .bold)
        case .iPhoneRegular:
            return .footnote.bold()
        case .iPhoneCompact:
            return .system(size: 11, weight: .bold)
        }
    }
    
    private func getFooterVerticalPadding(for deviceType: DeviceType) -> CGFloat {
        switch deviceType {
        case .iPad:
            return 12
        case .iPhonePlus:
            return 10
        case .iPhoneRegular:
            return 8
        case .iPhoneCompact:
            return 6
        }
    }
    
    // MARK: - Game Functions
    private func startGame() {
        print("🎮 startGame() called")
        print("🎮 startGame - gameRules.playerCount: \(gameRules.playerCount)")
        print("🎮 startGame - gameRules.playerConfigurations.count: \(gameRules.playerConfigurations.count)")
        for (index, config) in gameRules.playerConfigurations.enumerated() {
            print("🎮 startGame - Configuration \(index): \(config.name) (\(config.type)) at position \(config.position)")
        }
        
        isConfiguringGame = true
        configurationMessage = "Configuring game for \(gameRules.playerCount) players..."
        
        if game == nil {
            game = Game(gameRules: gameRules)
            print("🎮 Game created: \(game != nil)")
            print("🎮 Game object ID: \(ObjectIdentifier(game!))")
        }
        
        game?.initializeFromConfiguration()
        print("🎮 Game initialized from configuration")
        
        game?.startNewGame()
        print("🎮 Game started")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isConfiguringGame = false
            isGameActive = true
            print("🎮 isGameActive set to true")
            print("🎮 Game still exists: \(game != nil)")
        }
    }
    
    private func restorePurchase() {
        print("Restore Purchase tapped")
    }
}

// MARK: - Device Type Enum
enum DeviceType {
    case iPad
    case iPhonePlus
    case iPhoneRegular
    case iPhoneCompact
}

// MARK: - Updated Marriage Card View
struct MarriageCardView: View {
    let suit: CardSuit
    let angle: Double
    var cardSize: CGSize = CGSize(width: 120, height: 168)
    
    var body: some View {
        ZStack {
            // King card (background)
            ZStack {
                Image(getKingImageName())
                    .resizable()
                    .aspectRatio(2.5/3.5, contentMode: .fit)
                    .frame(maxWidth: cardSize.width, maxHeight: cardSize.height)
                    .aspectRatio(2.5/3.5, contentMode: .fit)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(getSuitColor(), lineWidth: 1)
                    )
            }
            .offset(x: -cardSize.width * 0.1, y: -cardSize.height * 0.07)
            .rotationEffect(.degrees(angle))
            
            // Queen card (overlaid)
            ZStack {
                Image(getQueenImageName())
                    .resizable()
                    .aspectRatio(2.5/3.5, contentMode: .fit)
                    .frame(maxWidth: cardSize.width, maxHeight: cardSize.height)
                    .aspectRatio(2.5/3.5, contentMode: .fit)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(getSuitColor(), lineWidth: 1)
                    )
            }
            .offset(x: cardSize.width * 0.1, y: cardSize.height * 0.07)
            .rotationEffect(.degrees(-angle))
        }
        .frame(maxWidth: cardSize.width * 1.5, maxHeight: cardSize.height * 1.2)
        .aspectRatio(contentMode: .fit)
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

// MARK: - Updated Circular Button View
struct CircularButtonView: View {
    let icon: String
    let outlineColor: Color
    let action: () -> Void
    var buttonSize: CGFloat = 100
    var iconFontSize: CGFloat = 40
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
            }
            action()
        }) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .shadow(radius: 4)
                    .frame(width: buttonSize, height: buttonSize)

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

// MARK: - Privacy Policy View
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
