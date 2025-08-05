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
                            .frame(height: deviceType == .iPad ? 150 : 100)  // More space for iPad to separate from footer
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, getHorizontalPadding(for: deviceType, geometry: geometry))
                    .padding(.bottom, geometry.safeAreaInsets.bottom + 20)
                    .offset(y: deviceType == .iPad ? -40 : 0)  // Move all iPad content up by 40 points
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
                .presentationDetents(getSheetDetents(for: getDeviceType(from: UIScreen.main.bounds.size)))
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
                .presentationDetents(getSheetDetents(for: getDeviceType(from: UIScreen.main.bounds.size)))
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .fullScreenCover(isPresented: $isGameActive) {
            if let game = game {
                GameBoardView2(
                    game: game,
                    settings: settings,
                    gameRules: gameRules,
                    onEndGame: { isGameActive = false }
                )
                .onAppear {
                    print("🎮 fullScreenCover triggered - isGameActive: \(isGameActive)")
                    print("🎮 Game object: exists")
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
            
            // Add spacing between subtitle and cards for iPhone portrait only
            if deviceType != .iPad && !isLandscape {
                Spacer()
                    .frame(height: getSubtitleToCardsSpacing(for: deviceType))
            }
        }
    }
    
    @ViewBuilder
    private func marriageCardsSection(deviceType: DeviceType, geometry: GeometryProxy) -> some View {
        let cardSize = getMarriageCardSize(for: deviceType)
        let spacing = getMarriageCardSpacing(for: deviceType, geometry: geometry)
        
        // Single row layout for all devices
        HStack(spacing: spacing) {
            MarriageCardView(suit: .hearts, angle: 10, cardSize: cardSize)
            MarriageCardView(suit: .clubs, angle: 20, cardSize: cardSize)
            MarriageCardView(suit: .diamonds, angle: -10, cardSize: cardSize)
            MarriageCardView(suit: .spades, angle: -20, cardSize: cardSize)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, getHorizontalPadding(for: deviceType, geometry: geometry))
    }
    
    @ViewBuilder
    private func buttonTokensSection(deviceType: DeviceType, geometry: GeometryProxy) -> some View {
        let buttonSize = getButtonSize(for: deviceType)
        let iconSize = getButtonIconSize(for: deviceType)
        let labelFontSize = getButtonLabelFontSize(for: deviceType)
        let spacing = getButtonSpacing(for: deviceType, geometry: geometry)
        
        // Single row layout for all devices
        HStack(spacing: spacing) {
            buttonColumn("play.fill", "Play", Color(hex: "016A16"), { startGame() }, buttonSize, iconSize, labelFontSize)
            buttonColumn("gearshape.fill", "Settings", Color(hex: "D21034"), { showingConfiguration = true }, buttonSize, iconSize, labelFontSize)
            buttonColumn("questionmark", "Help", Color(hex: "00209F"), { showingHowToPlay = true }, buttonSize, iconSize, labelFontSize)
            buttonColumn("info.circle.fill", "About", Color(hex: "F1B517"), { showingAbout = true }, buttonSize, iconSize, labelFontSize)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, getHorizontalPadding(for: deviceType, geometry: geometry))
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
        .offset(y: deviceType == .iPad ? -30 : -50)  // Move iPad footer up by 30 points, iPhone by 50 points
        .padding(.bottom, geometry.safeAreaInsets.bottom + 5)
    }
    
    // MARK: - Responsive Sizing Functions
    private func getSpacing(for deviceType: DeviceType, geometry: GeometryProxy) -> CGFloat {
        switch deviceType {
        case .iPad:
            return geometry.size.height * 0.06
        case .iPhonePlus:
            return geometry.size.height * 0.035  // Reduced for single-line layout
        case .iPhoneRegular:
            return geometry.size.height * 0.03   // Reduced for single-line layout
        case .iPhoneCompact:
            return geometry.size.height * 0.025  // Reduced for single-line layout
        }
    }
    
    private func getTopSpacing(for deviceType: DeviceType, geometry: GeometryProxy) -> CGFloat {
        switch deviceType {
        case .iPad:
            return geometry.size.height * 0.06  // Reduced from 0.08 to move title up and make room
        case .iPhonePlus:
            return geometry.size.height * 0.04   // Reduced for more content space
        case .iPhoneRegular:
            return geometry.size.height * 0.035  // Reduced for more content space
        case .iPhoneCompact:
            return geometry.size.height * 0.03   // Reduced for more content space
        }
    }
    
    private func getHorizontalPadding(for deviceType: DeviceType, geometry: GeometryProxy) -> CGFloat {
        switch deviceType {
        case .iPad:
            return geometry.size.width * 0.08
        case .iPhonePlus:
            return geometry.size.width * 0.04   // Reduced for more content space
        case .iPhoneRegular:
            return geometry.size.width * 0.035  // Reduced for more content space
        case .iPhoneCompact:
            return geometry.size.width * 0.03   // Reduced for more content space
        }
    }
    
    private func getTitleFontSize(for deviceType: DeviceType, geometry: GeometryProxy, isLandscape: Bool) -> CGFloat {
        let baseSizeMultiplier: CGFloat = isLandscape ? 0.35 : (deviceType == .iPad ? 0.3 : 0.22)  // Original for iPad, reduced for iPhone portrait
        let maxSize: CGFloat
        
        switch deviceType {
        case .iPad:
            maxSize = isLandscape ? 200 : 160
        case .iPhonePlus:
            maxSize = isLandscape ? 140 : 85   // Significantly reduced for portrait
        case .iPhoneRegular:
            maxSize = isLandscape ? 120 : 75   // Significantly reduced for portrait
        case .iPhoneCompact:
            maxSize = isLandscape ? 100 : 65   // Significantly reduced for portrait
        }
        
        return min(geometry.size.width * baseSizeMultiplier, maxSize)
    }
    
    private func getSubtitleFontSize(for deviceType: DeviceType, geometry: GeometryProxy) -> CGFloat {
        let maxSize: CGFloat
        let multiplier: CGFloat = deviceType == .iPad ? 0.04 : 0.03  // Original for iPad, reduced for iPhone
        
        switch deviceType {
        case .iPad:
            maxSize = 36
        case .iPhonePlus:
            maxSize = 20   // Reduced for better fit
        case .iPhoneRegular:
            maxSize = 18   // Reduced for better fit
        case .iPhoneCompact:
            maxSize = 16   // Reduced for better fit
        }
        
        return min(geometry.size.width * multiplier, maxSize)
    }
    
    private func getTitleSpacing(for deviceType: DeviceType) -> CGFloat {
        switch deviceType {
        case .iPad:
            return 16
        case .iPhonePlus:
            return 8   // Reduced spacing
        case .iPhoneRegular:
            return 6   // Reduced spacing
        case .iPhoneCompact:
            return 5   // Reduced spacing
        }
    }
    
    private func getMarriageCardSize(for deviceType: DeviceType) -> CGSize {
        switch deviceType {
        case .iPad:
            return CGSize(width: 140, height: 196)
        case .iPhonePlus:
            return CGSize(width: 70, height: 98)    // Reduced for single-line fit
        case .iPhoneRegular:
            return CGSize(width: 65, height: 91)    // Reduced for single-line fit
        case .iPhoneCompact:
            return CGSize(width: 55, height: 77)    // Reduced for single-line fit
        }
    }
    
    private func getMarriageCardSpacing(for deviceType: DeviceType, geometry: GeometryProxy) -> CGFloat {
        switch deviceType {
        case .iPad:
            return geometry.size.width * 0.04
        case .iPhonePlus:
            return geometry.size.width * 0.015  // Reduced for single-line fit
        case .iPhoneRegular:
            return geometry.size.width * 0.012  // Reduced for single-line fit
        case .iPhoneCompact:
            return geometry.size.width * 0.01   // Reduced for single-line fit
        }
    }
    
    private func getButtonSize(for deviceType: DeviceType) -> CGFloat {
        switch deviceType {
        case .iPad:
            return 120
        case .iPhonePlus:
            return 65   // Reduced for single-line fit
        case .iPhoneRegular:
            return 60   // Reduced for single-line fit
        case .iPhoneCompact:
            return 55   // Reduced for single-line fit
        }
    }
    
    private func getButtonIconSize(for deviceType: DeviceType) -> CGFloat {
        switch deviceType {
        case .iPad:
            return 48
        case .iPhonePlus:
            return 24   // Reduced for single-line fit
        case .iPhoneRegular:
            return 22   // Reduced for single-line fit
        case .iPhoneCompact:
            return 20   // Reduced for single-line fit
        }
    }
    
    private func getButtonLabelFontSize(for deviceType: DeviceType) -> CGFloat {
        switch deviceType {
        case .iPad:
            return 32
        case .iPhonePlus:
            return 16   // Reduced for single-line fit
        case .iPhoneRegular:
            return 14   // Reduced for single-line fit
        case .iPhoneCompact:
            return 12   // Reduced for single-line fit
        }
    }
    
    private func getButtonSpacing(for deviceType: DeviceType, geometry: GeometryProxy) -> CGFloat {
        switch deviceType {
        case .iPad:
            return geometry.size.width * 0.06
        case .iPhonePlus:
            return geometry.size.width * 0.02   // Reduced for single-line fit
        case .iPhoneRegular:
            return geometry.size.width * 0.015  // Reduced for single-line fit
        case .iPhoneCompact:
            return geometry.size.width * 0.01   // Reduced for single-line fit
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
    
    private func getSubtitleToCardsSpacing(for deviceType: DeviceType) -> CGFloat {
        switch deviceType {
        case .iPad:
            return 0    // Not used for iPad
        case .iPhonePlus:
            return 20   // More spacing for larger iPhone
        case .iPhoneRegular:
            return 16   // Medium spacing
        case .iPhoneCompact:
            return 12   // Less spacing for smaller iPhone
        }
    }
    
    private func getSheetDetents(for deviceType: DeviceType) -> Set<PresentationDetent> {
        switch deviceType {
        case .iPad:
            return [.large, .medium] // Larger sheet for iPad
        default:
            return [.medium] // Standard size for iPhone
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
    
    private var deviceType: DeviceType {
        // Detect device type based on screen size
        let screenSize = UIScreen.main.bounds.size
        let minDimension = min(screenSize.width, screenSize.height)
        let maxDimension = max(screenSize.width, screenSize.height)
        
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
    
    private func getTitleFontSize() -> CGFloat {
        switch deviceType {
        case .iPad:
            return 32
        default:
            return 28
        }
    }
    
    private func getHeadlineFontSize() -> CGFloat {
        switch deviceType {
        case .iPad:
            return 24
        default:
            return 20
        }
    }
    
    private func getBodyFontSize() -> CGFloat {
        switch deviceType {
        case .iPad:
            return 18
        default:
            return 16
        }
    }
    
    private func getSubheadlineFontSize() -> CGFloat {
        switch deviceType {
        case .iPad:
            return 16
        default:
            return 14
        }
    }
    
    private func getCaptionFontSize() -> CGFloat {
        switch deviceType {
        case .iPad:
            return 14
        default:
            return 12
        }
    }
    
    private func getSpacing() -> CGFloat {
        switch deviceType {
        case .iPad:
            return 30
        default:
            return 20
        }
    }
    
    private func getSectionSpacing() -> CGFloat {
        switch deviceType {
        case .iPad:
            return 15
        default:
            return 10
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: getSpacing()) {
                    // Header
                    Text("How to Play Haitian Bésigue")
                        .font(.system(size: getTitleFontSize(), weight: .bold))
                        .foregroundColor(Color(hex: "00209F"))
                        .padding(.bottom, 10)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
                    // Objective
                    VStack(alignment: .leading, spacing: getSectionSpacing()) {
                        Text("🎯 Objective")
                            .font(.system(size: getHeadlineFontSize(), weight: .semibold))
                            .foregroundColor(Color(hex: "00209F"))
                        
                        Text("Score points by winning tricks containing Aces and 10s (called 'brisques') and by declaring valuable card combinations known as melds. The first player to reach the target score wins!")
                            .font(.system(size: getBodyFontSize()))
                    }
                    
                    // Deck Information
                    VStack(alignment: .leading, spacing: getSectionSpacing()) {
                        Text("🃏 Game Deck: 132 Cards")
                            .font(.system(size: getHeadlineFontSize(), weight: .semibold))
                            .foregroundColor(Color(hex: "00209F"))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Four 32-card Piquet decks + 4 Jokers")
                                .font(.system(size: getSubheadlineFontSize()))
                                .padding(8)
                                .background(Color(hex: "F1B517").opacity(0.2))
                                .cornerRadius(8)
                            
                            HStack {
                                ForEach(["A", "10", "K", "Q", "J", "9", "8", "7"], id: \.self) { rank in
                                    SimpleCardView(rank: rank, suit: "♠", isRed: false, isJoker: false)
                                }
                            }
                            
                            HStack {
                                ForEach(["A", "10", "K", "Q"], id: \.self) { rank in
                                    SimpleCardView(rank: rank, suit: "♥", isRed: true, isJoker: false)
                                }
                                SimpleCardView(rank: "🃏", suit: "", isRed: false, isJoker: true)
                            }
                            
                            Text("Card Ranking: A (high), 10, K, Q, J, 9, 8, 7 (low)")
                                .font(.system(size: getCaptionFontSize()))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Setup
                    VStack(alignment: .leading, spacing: getSectionSpacing()) {
                        Text("🎲 Setup")
                            .font(.system(size: getHeadlineFontSize(), weight: .semibold))
                            .foregroundColor(Color(hex: "00209F"))
                        
                        Text("• Players draw cards until someone draws a Jack - that player becomes the dealer\n• Each player receives 9 cards, dealt in groups of 3\n• Gameplay proceeds to the right")
                            .font(.system(size: getBodyFontSize()))
                    }
                    
                    // Trump Suit
                    VStack(alignment: .leading, spacing: getSectionSpacing()) {
                        Text("♠️ Trump Suit")
                            .font(.system(size: getHeadlineFontSize(), weight: .semibold))
                            .foregroundColor(Color(hex: "00209F"))
                        
                        Text("The trump suit is determined by the first Royal Marriage played (King and Queen of the same suit)")
                            .font(.system(size: getBodyFontSize()))
                            .padding(12)
                            .background(Color(hex: "F1B517").opacity(0.2))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color(hex: "F1B517"), lineWidth: 2)
                            )
                    }
                    
                    // Melds Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("🏆 Melds & Scoring")
                            .font(.system(size: getHeadlineFontSize(), weight: .semibold))
                            .foregroundColor(Color(hex: "00209F"))
                        
                        Text("⚠️ Important: Melds can only be declared AFTER a Royal Marriage establishes the trump suit!")
                            .font(.system(size: getSubheadlineFontSize(), weight: .medium))
                            .foregroundColor(Color(hex: "D21034"))
                        
                        // Bésigue
                        MeldView(
                            title: "Bésigue",
                            points: "40 pts",
                            description: "Queen of Spades + Jack of Diamonds",
                            cards: [
                                ("Q", "♠", false),
                                ("J", "♦", true)
                            ]
                        )
                        
                        // Royal Marriage
                        MeldView(
                            title: "Royal Marriage",
                            points: "40 pts",
                            description: "King + Queen of Trump Suit",
                            cards: [
                                ("K", "♠", false),
                                ("Q", "♠", false)
                            ]
                        )
                        
                        // Common Marriage
                        MeldView(
                            title: "Common Marriage",
                            points: "20 pts",
                            description: "King + Queen of Non-Trump Suit",
                            cards: [
                                ("K", "♥", true),
                                ("Q", "♥", true)
                            ]
                        )
                        
                        // Four Aces
                        MeldView(
                            title: "Four Aces",
                            points: "100 pts",
                            description: "All four Aces (doubles to 200 if trump suit)",
                            cards: [
                                ("A", "♠", false),
                                ("A", "♥", true),
                                ("A", "♦", true),
                                ("A", "♣", false)
                            ]
                        )
                        
                        // Four Kings
                        MeldView(
                            title: "Four Kings",
                            points: "80 pts",
                            description: "All four Kings (doubles to 160 if trump suit)",
                            cards: [
                                ("K", "♠", false),
                                ("K", "♥", true),
                                ("K", "♦", true),
                                ("K", "♣", false)
                            ]
                        )
                        
                        // Four Queens
                        MeldView(
                            title: "Four Queens",
                            points: "60 pts",
                            description: "All four Queens (doubles to 120 if trump suit)",
                            cards: [
                                ("Q", "♠", false),
                                ("Q", "♥", true),
                                ("Q", "♦", true),
                                ("Q", "♣", false)
                            ]
                        )
                        
                        // Four Jacks
                        MeldView(
                            title: "Four Jacks",
                            points: "40 pts",
                            description: "All four Jacks (doubles to 80 if trump suit)",
                            cards: [
                                ("J", "♠", false),
                                ("J", "♥", true),
                                ("J", "♦", true),
                                ("J", "♣", false)
                            ]
                        )
                        
                        // Four Jokers
                        MeldView(
                            title: "Four Jokers",
                            points: "200 pts",
                            description: "All four Jokers",
                            cards: [
                                ("🃏", "", false),
                                ("🃏", "", false),
                                ("🃏", "", false),
                                ("🃏", "", false)
                            ],
                            isJokerMeld: true
                        )
                        
                        // Sequence
                        MeldView(
                            title: "Sequence (Trump Suit)",
                            points: "250 pts",
                            description: "A, 10, K, Q, J of Trump Suit",
                            cards: [
                                ("A", "♠", false),
                                ("10", "♠", false),
                                ("K", "♠", false),
                                ("Q", "♠", false),
                                ("J", "♠", false)
                            ]
                        )
                    }
                    
                    // Joker Rules
                    VStack(alignment: .leading, spacing: 10) {
                        Text("🃏 Joker Rules")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "00209F"))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Jokers can substitute for any card to complete Four of a Kind melds")
                            Text("• Example: 3 Kings + 1 Joker = Four Kings meld")
                        }
                        .font(.body)
                        .padding(12)
                        .background(Color(hex: "F1B517").opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    // Gameplay
                    VStack(alignment: .leading, spacing: 10) {
                        Text("🎮 Gameplay")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "00209F"))
                        
                        Text("• Players take turns leading cards\n• Others must follow suit if possible\n• Highest card of led suit or highest trump wins\n• Trick winner draws first, then others in sequence\n• Players must maintain 8-9 cards while draw pile has cards")
                            .font(.body)
                    }
                    
                    // Scoring System
                    VStack(alignment: .leading, spacing: 10) {
                        Text("📊 Scoring System")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "00209F"))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Brisques (Aces & 10s)")
                                Spacer()
                                Text("10 pts each")
                                    .foregroundColor(Color(hex: "016A16"))
                                    .fontWeight(.semibold)
                            }
                            
                            HStack {
                                Text("Insufficient Brisques")
                                Spacer()
                                Text("-20 pts")
                                    .foregroundColor(Color(hex: "D21034"))
                                    .fontWeight(.semibold)
                            }
                            
                            HStack {
                                Text("7 of Trump Suit")
                                Spacer()
                                Text("+10 pts")
                                    .foregroundColor(Color(hex: "016A16"))
                                    .fontWeight(.semibold)
                            }
                            
                            Text("Note: Need minimum 5 brisques to count")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(12)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    // The Dog Rules
                    VStack(alignment: .leading, spacing: 10) {
                        Text("🐕 'The Dog' Special Rules")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "00209F"))
                        
                        Text("The player with the lowest score becomes 'The Dog':")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("• Starts next game at -20 points")
                            Text("• Cannot speak without King's permission")
                            Text("• Must bark when Bésigue meld is played")
                            Text("• Must say 'Man, this game is so hard for me!' when 7 of trump is played")
                            Text("• Counts to 10 for each player's turn")
                            Text("• Cannot place the first Royal Marriage")
                        }
                        .font(.body)
                        .padding(12)
                        .background(Color(hex: "D21034").opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    // Winning
                    VStack(alignment: .leading, spacing: 10) {
                        Text("🏁 Winning the Game")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "00209F"))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("4 Players:")
                                Spacer()
                                Text("750 points")
                                    .foregroundColor(Color(hex: "016A16"))
                                    .fontWeight(.semibold)
                            }
                            
                            HStack {
                                Text("2-3 Players:")
                                Spacer()
                                Text("1000 points")
                                    .foregroundColor(Color(hex: "016A16"))
                                    .fontWeight(.semibold)
                            }
                            
                            Text("Note: In 4-player games, brisques don't count after 600 points")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(12)
                        .background(Color(hex: "016A16").opacity(0.1))
                        .cornerRadius(10)
                    }
                    
                    // Table Rankings
                    VStack(alignment: .leading, spacing: 10) {
                        Text("👑 Table Rankings")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "00209F"))
                        
                        Text("King: Highest scorer, gets +20 points next game\n2nd Place: Sits to King's right\n3rd Place: May be replaced by standby players\nThe Dog: Lowest scorer, follows special rules")
                            .font(.body)
                    }
                    
                    // Strategy Tips
                    VStack(alignment: .leading, spacing: 10) {
                        Text("💡 Strategy Tips")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(hex: "00209F"))
                        
                        Text("• Early Game: Focus on establishing trump suit with Royal Marriage\n• Mid Game: Collect cards for high-value melds\n• Late Game: Count brisques and avoid becoming The Dog\n• Trump Management: Control trump cards for critical tricks")
                            .font(.body)
                            .padding(12)
                            .background(Color(hex: "F1B517").opacity(0.1))
                            .cornerRadius(10)
                    }
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

// MARK: - Supporting Views

struct MeldView: View {
    let title: String
    let points: String
    let description: String
    let cards: [(String, String, Bool)]
    var isJokerMeld: Bool = false
    
    private var deviceType: DeviceType {
        let screenSize = UIScreen.main.bounds.size
        let minDimension = min(screenSize.width, screenSize.height)
        let maxDimension = max(screenSize.width, screenSize.height)
        
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
    
    private func getSubheadlineFontSize() -> CGFloat {
        switch deviceType {
        case .iPad:
            return 18
        default:
            return 14
        }
    }
    
    private func getCaptionFontSize() -> CGFloat {
        switch deviceType {
        case .iPad:
            return 14
        default:
            return 12
        }
    }
    
    private func getPadding() -> CGFloat {
        switch deviceType {
        case .iPad:
            return 16
        default:
            return 12
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: getSubheadlineFontSize(), weight: .semibold))
                    .foregroundColor(Color(hex: "00209F"))
                
                Spacer()
                
                Text(points)
                    .font(.system(size: getCaptionFontSize(), weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(hex: "016A16"))
                    .cornerRadius(12)
            }
            
            HStack(spacing: 4) {
                ForEach(Array(cards.enumerated()), id: \.offset) { index, card in
                    SimpleCardView(
                        rank: card.0,
                        suit: card.1,
                        isRed: card.2,
                        isJoker: isJokerMeld || card.0 == "🃏"
                    )
                }
            }
            
            Text(description)
                .font(.system(size: getCaptionFontSize()))
                .foregroundColor(.gray)
        }
        .padding(getPadding())
        .background(Color.white)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Simple Card View for HomePage
struct SimpleCardView: View {
    let rank: String
    let suit: String
    let isRed: Bool
    let isJoker: Bool
    
    private var imageName: String {
        if isJoker {
            return "joker_red_1" // Use a joker image
        }
        
        // Convert Unicode suit symbols to asset names
        let suitName: String
        switch suit {
        case "♠":
            suitName = "spades"
        case "♥":
            suitName = "hearts"
        case "♦":
            suitName = "diamonds"
        case "♣":
            suitName = "clubs"
        default:
            return "card_back" // Fallback for unknown suit
        }
        
        // Handle special cases for rank
        switch rank {
        case "A":
            return "\(suitName)_ace"
        case "K":
            return "\(suitName)_king"
        case "Q":
            return "\(suitName)_queen"
        case "J":
            return "\(suitName)_jack"
        case "10":
            return "\(suitName)_10"
        case "9":
            return "\(suitName)_9"
        case "8":
            return "\(suitName)_8"
        case "7":
            return "\(suitName)_7"
        default:
            return "card_back" // Fallback
        }
    }
    
    var body: some View {
        Image(imageName)
            .resizable()
            .aspectRatio(2.5/3.5, contentMode: .fit)
            .frame(width: 40, height: 56) // Smaller size for help section
            .background(Color.white)
            .cornerRadius(4)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
    }
}

// MARK: - Color Extension
// Note: Color hex extension is defined in GameBoardView.swift to avoid duplication

// MARK: - About View
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showEasterEgg = false
    
    private var deviceType: DeviceType {
        let screenSize = UIScreen.main.bounds.size
        let minDimension = min(screenSize.width, screenSize.height)
        let maxDimension = max(screenSize.width, screenSize.height)
        
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
    
    private func getTitleFontSize() -> CGFloat {
        switch deviceType {
        case .iPad:
            return 32
        default:
            return 28
        }
    }
    
    private func getHeadlineFontSize() -> CGFloat {
        switch deviceType {
        case .iPad:
            return 24
        default:
            return 20
        }
    }
    
    private func getBodyFontSize() -> CGFloat {
        switch deviceType {
        case .iPad:
            return 18
        default:
            return 16
        }
    }
    
    private func getCaptionFontSize() -> CGFloat {
        switch deviceType {
        case .iPad:
            return 16
        default:
            return 12
        }
    }
    
    private func getSpacing() -> CGFloat {
        switch deviceType {
        case .iPad:
            return 40
        default:
            return 30
        }
    }
    
    private func getSectionSpacing() -> CGFloat {
        switch deviceType {
        case .iPad:
            return 20
        default:
            return 15
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: getSpacing()) {
                Text("About Bésigue")
                    .font(.system(size: getTitleFontSize(), weight: .bold))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                
                VStack(spacing: getSectionSpacing()) {
                    Text("Version 1.0")
                        .font(.system(size: getHeadlineFontSize()))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
                    Text("A modern implementation of the classic French card game Bésigue.")
                        .font(.system(size: getBodyFontSize()))
                        .multilineTextAlignment(.center)
                    
                    Text("Developed with SwiftUI")
                        .font(.system(size: getCaptionFontSize()))
                        .foregroundColor(.gray)
                }
                
                Button(action: {
                    withAnimation {
                        showEasterEgg.toggle()
                    }
                }) {
                    Text("Tap for a surprise!")
                        .font(.system(size: getCaptionFontSize()))
                        .foregroundColor(.blue)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(15)
                }
                
                if showEasterEgg {
                    Text("🎉 You found the easter egg! 🎉")
                        .font(.system(size: getHeadlineFontSize()))
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
