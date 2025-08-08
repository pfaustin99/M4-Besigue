import SwiftUI
import AVFoundation

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
    
    // Animation states
    @State private var titleScale: CGFloat = 0.8
    @State private var titleOpacity: Double = 0
    @State private var cardsOffset: CGFloat = 100
    @State private var cardsOpacity: Double = 0
    
    // Background animation states
    @State private var animatedGradientRotation: Double = 0
    @State private var animatedGradientScale: CGFloat = 1.0
    
    // Animation states for entrance effects
    @State private var entranceIndex = 0
    @State private var isEntranceComplete = false
    @State private var entranceTimer: Timer?
    
    // Ripple effect state
    @State private var rippleOrigin: CGPoint? = nil
    @State private var rippleRadius: CGFloat = 0
    
    // Shimmer effect state
    @State private var shimmerBoost = false
    @State private var shimmerOrigin: CGPoint = .zero
    
    var body: some View {
        GeometryReader { geometry in
            let deviceType = getDeviceType(from: geometry.size)
            let isLandscape = geometry.size.width > geometry.size.height
            
            ZStack(alignment: .center) {
                // Enhanced background (no rotation)
                backgroundView(isLandscape: isLandscape, geometry: geometry)
                
                // Gradient overlay with more depth
                enhancedOverlay
                
                // Main content with improved animations - vertically centered
                VStack(alignment: .center, spacing: getSpacing(for: deviceType, geometry: geometry)) {
                    // Flexible top spacer for vertical centering
                    Spacer()
                    
                    // Enhanced title section
                    enhancedTitleSection(deviceType: deviceType, geometry: geometry, isLandscape: isLandscape)
                        .scaleEffect(titleScale)
                        .opacity(titleOpacity)
                    
                    // Enhanced marriage cards section
                    enhancedMarriageCardsSection(deviceType: deviceType, geometry: geometry)
                        .offset(y: cardsOffset)
                        .opacity(cardsOpacity)
                    
                    // Enhanced button tokens section
                    enhancedButtonTokensSection(deviceType: deviceType, geometry: geometry)
                    // Remove global animations - individual buttons handle their own entrance
                    // .scaleEffect(buttonsScale)
                    // .opacity(buttonsOpacity)
                    
                    // Flexible bottom spacer for vertical centering
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .padding(.horizontal, getHorizontalPadding(for: deviceType, geometry: geometry))
                .padding(.top, geometry.safeAreaInsets.top + 20)
                .padding(.bottom, geometry.safeAreaInsets.bottom + 20)
                
                // Enhanced configuration overlay
                enhancedConfigurationOverlay
                
                // Global ripple effect overlay
                if let origin = rippleOrigin {
                    RippleEffectView(origin: origin, maxRadius: rippleRadius)
                        .transition(.opacity)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                rippleOrigin = nil
                            }
                        }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
           // .overlay(enhancedFooterOverlay(geometry: geometry, deviceType: deviceType), alignment: .bottom)
            .overlay(enhancedFooterOverlay(geometry: geometry, deviceType: deviceType)
                    .padding(.bottom, geometry.safeAreaInsets.bottom), // Position ABOVE safe area
                     alignment: .bottom
            )
            .onAppear {
                startEntranceAnimations()
            }
            .onDisappear {
                // Clean up timer
                entranceTimer?.invalidate()
                entranceTimer = nil
            }
        }
        .sheet(isPresented: $showingConfiguration) {
            GameSettingsView(gameRules: gameRules) {
                print("🎮 Configuration saved")
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
            }
        }
    }
    
    @ViewBuilder
    private var animatedGradientBackground: some View {
        ZStack {
            // Primary gradient
            LinearGradient(
                colors: [
                    Color(red: 241/255, green: 181/255, blue: 23/255).opacity(0.1),
                    Color.clear,
                    Color(red: 210/255, green: 16/255, blue: 52/255).opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            .rotationEffect(.degrees(animatedGradientRotation))
            .animation(.linear(duration: 20).repeatForever(autoreverses: false), value: animatedGradientRotation)

            // Secondary gradient
            RadialGradient(
                colors: [
                    Color.clear,
                    Color(red: 0/255, green: 106/255, blue: 22/255).opacity(0.05),
                    Color.clear
                ],
                center: .center,
                startRadius: 100,
                endRadius: 600
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .scaleEffect(animatedGradientScale)
            .animation(.easeInOut(duration: 15).repeatForever(autoreverses: true), value: animatedGradientScale)

            // 🔥 REACTIVE SHIMMER BOOST
            if shimmerBoost {
                GeometryReader { proxy in
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "F1B517").opacity(0.5),
                                    Color(hex: "F1B517").opacity(0.2),
                                    .clear
                                ]),
                                center: .center,
                                startRadius: 10,
                                endRadius: 400
                            )
                        )
                        .frame(width: shimmerBoost ? 800 : 0, height: shimmerBoost ? 800 : 0)
                        .position(x: shimmerOrigin.x, y: shimmerOrigin.y)
                        .scaleEffect(shimmerBoost ? 1.0 : 0.1)
                        .blendMode(.screen)
                        .animation(.easeOut(duration: 0.8), value: shimmerBoost)
                        .transition(.opacity)
                }
            }
        }
    }
    
    // MARK: - Enhanced Visual Components
    
    @ViewBuilder
    private func backgroundView(isLandscape: Bool, geometry: GeometryProxy) -> some View {
        animatedBackgroundView(geometry: geometry)
    }
    
    @ViewBuilder
    private func animatedBackgroundView(geometry: GeometryProxy) -> some View {
        let isLandscape = geometry.size.width > geometry.size.height
        
        ZStack {
            // Static base image
            Image(isLandscape ? "card_back_landscape" : "card_back_portrait")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .ignoresSafeArea(.all)
            
            // Animated gradient overlay
            animatedGradientBackground
                .opacity(0.3)
            
            // Enhanced particle system
            EnhancedParticleView(geometry: geometry)
                .opacity(0.4)
        }
    }
    
    @ViewBuilder
    private var enhancedOverlay: some View {
        ZStack {
            // Base dark overlay fills entire screen
            Color.black.opacity(0.25)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea(.all)
            
            // Dynamic gradient overlay fills entire screen
            RadialGradient(
                colors: [
                    Color.clear,
                    Color.black.opacity(0.1),
                    Color.black.opacity(0.3)
                ],
                center: .center,
                startRadius: 100,
                endRadius: 800
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(.all)
            
            // Subtle color accent gradients fill entire screen
            LinearGradient(
                colors: [
                    Color(red: 241/255, green: 181/255, blue: 23/255).opacity(0.05),
                    Color.clear,
                    Color(red: 210/255, green: 16/255, blue: 52/255).opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(.all)
        }
    }
    
    @ViewBuilder
    private func enhancedTitleSection(deviceType: DeviceType, geometry: GeometryProxy, isLandscape: Bool) -> some View {
        VStack(alignment: .center, spacing: getTitleSpacing(for: deviceType)) {
            // Enhanced main title with gradient and glow effects
            HStack(spacing: 2) {
                ForEach(Array("Bésigue".enumerated()), id: \.offset) { index, character in
                    Text(String(character))
                .font(.system(
                    size: getTitleFontSize(for: deviceType, geometry: geometry, isLandscape: isLandscape),
                    weight: .black,
                    design: .serif
                ))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(red: 241/255, green: 181/255, blue: 23/255),
                                    Color(red: 255/255, green: 215/255, blue: 0/255),
                                    Color(red: 241/255, green: 181/255, blue: 23/255)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color(red: 210/255, green: 16/255, blue: 52/255).opacity(0.8), radius: 8, x: 4, y: 4)
                        .shadow(color: Color(red: 241/255, green: 181/255, blue: 23/255).opacity(0.6), radius: 16, x: 0, y: 0)
                        .animation(.spring(response: 1.0, dampingFraction: 0.8).delay(Double(index) * 0.1), value: titleOpacity)
                }
            }
                .minimumScaleFactor(0.5)
            .lineLimit(1)

            // Enhanced subtitle with refined styling
            Text("A Strategic Classic Card Game")
                .font(.custom("Cinzel Decorative", size: getSubtitleFontSize(for: deviceType, geometry: geometry)))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.white, Color.white.opacity(0.9)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color(red: 0/255, green: 32/255, blue: 159/255).opacity(0.8), radius: 4, x: 2, y: 2)
                .shadow(color: Color.black.opacity(0.5), radius: 8, x: 0, y: 2)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .tracking(2.0)
            
            if deviceType != .iPad && !isLandscape {
                Spacer()
                    .frame(height: getSubtitleToCardsSpacing(for: deviceType))
            }
        }
    }
    
    @ViewBuilder
    private func enhancedMarriageCardsSection(deviceType: DeviceType, geometry: GeometryProxy) -> some View {
        let cardSize = getMarriageCardSize(for: deviceType)
        let spacing = getMarriageCardSpacing(for: deviceType, geometry: geometry)
        
        HStack(spacing: spacing) {
            ForEach(Array([CardSuit.hearts, .clubs, .diamonds, .spades].enumerated()), id: \.offset) { index, suit in
                EnhancedMarriageCardView(
                    suit: suit,
                    angle: [10, 20, -10, -20][index],
                    cardSize: cardSize
                )
                .animation(.spring(response: 1.2, dampingFraction: 0.7).delay(Double(index) * 0.2), value: cardsOpacity)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, getHorizontalPadding(for: deviceType, geometry: geometry))
    }
    
    @ViewBuilder
    private func enhancedButtonTokensSection(deviceType: DeviceType, geometry: GeometryProxy) -> some View {
        let buttonSize = getButtonSize(for: deviceType)
        let iconSize = getButtonIconSize(for: deviceType)
        let labelFontSize = getButtonLabelFontSize(for: deviceType)
        let spacing = getButtonSpacing(for: deviceType, geometry: geometry)
        
        HStack(spacing: spacing) {
            ForEach(Array([
                ("play.fill", "Play", Color(hex: "016A16"), { startGame() }),
                ("gearshape.fill", "Settings", Color(hex: "D21034"), { showingConfiguration = true }),
                ("questionmark", "Help", Color(hex: "00209F"), { showingHowToPlay = true }),
                ("info.circle.fill", "About", Color(hex: "F1B517"), { showingAbout = true })
            ].enumerated()), id: \.offset) { index, button in
                enhancedButtonColumn(
                    button.0, button.1, button.2, button.3,
                    buttonSize, iconSize, labelFontSize, index
                )
                .animation(.spring(response: 1.0, dampingFraction: 0.8).delay(Double(index) * 0.15), value: entranceIndex)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, getHorizontalPadding(for: deviceType, geometry: geometry))
    }
    
    @ViewBuilder
    private func enhancedButtonColumn(_ icon: String, _ label: String, _ color: Color, _ action: @escaping () -> Void, _ buttonSize: CGFloat, _ iconSize: CGFloat, _ labelFontSize: CGFloat, _ buttonIndex: Int) -> some View {
        VStack(spacing: 12) {
                            EnhancedCircularButtonView(
                icon: icon,
                outlineColor: color,
                action: action,
                buttonSize: buttonSize,
                    iconFontSize: iconSize,
                    buttonIndex: buttonIndex,
                    entranceIndex: entranceIndex,
                    onRippleTrigger: {
                        // entrance ripple size — tweak multiplier if you want more/less splash
                        rippleRadius = buttonSize * 4.0
                    },
                    onGlobalRipple: { globalOrigin in
                        rippleOrigin = nil
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                            // Use the actual global coordinates from the button
                            rippleOrigin = globalOrigin
                            shimmerOrigin = globalOrigin
                            shimmerBoost = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            shimmerBoost = false
                        }
                    }
                )
            
            Text(label)
                .font(.system(size: labelFontSize, weight: .bold, design: .serif))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 241/255, green: 181/255, blue: 23/255),
                            Color(red: 255/255, green: 215/255, blue: 0/255)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: Color(red: 210/255, green: 16/255, blue: 52/255).opacity(0.8), radius: 3, x: 2, y: 2)
                .shadow(color: Color.black.opacity(0.3), radius: 6, x: 0, y: 2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
                .lineLimit(2)
        }
        .layoutPriority(1)
    }
    
    @ViewBuilder
    private var enhancedConfigurationOverlay: some View {
        Group {
            if isConfiguringGame {
                ZStack {
                    // Enhanced background with blur effect
                    Color.black.opacity(0.8)
                        .background(.ultraThinMaterial)
                    
                    VStack(spacing: 30) {
                        // Animated loading indicator (no rotation)
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 4)
                                .frame(width: 80, height: 80)
                            
                            Circle()
                                .trim(from: 0, to: 0.7)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color(hex: "F1B517"), Color(hex: "016A16")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                                )
                                .frame(width: 80, height: 80)
                        }
                    
                    Text(configurationMessage)
                            .font(.title2.bold())
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                            .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 1)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity.combined(with: .scale))
            }
        }
    }
    
    @ViewBuilder
    private func enhancedFooterOverlay(geometry: GeometryProxy, deviceType: DeviceType) -> some View {
        HStack(spacing: getFooterSpacing(for: deviceType, geometry: geometry)) {
            EnhancedFooterButton(title: "Privacy Policy", action: {
                showingPrivacyPolicy = true
            }, deviceType: deviceType)
            
            EnhancedFooterButton(title: "Restore Purchase", action: {
                restorePurchase()
            }, deviceType: deviceType)
        }
        .padding(.horizontal, getHorizontalPadding(for: deviceType, geometry: geometry))
        .padding(.vertical, getFooterVerticalPadding(for: deviceType))
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.6),
                    Color.black.opacity(0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .background(.ultraThinMaterial.opacity(0.3))
        )
        .padding(.bottom, geometry.safeAreaInsets.bottom)
    }
    
    // MARK: - Animation Functions
    
    private func startEntranceAnimations() {
        // Start background animations immediately
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            animatedGradientRotation = 360
        }
        
        withAnimation(.easeInOut(duration: 15).repeatForever(autoreverses: true)) {
            animatedGradientScale = 1.2
        }
        
        // Title and cards animations
        withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
            titleScale = 1.0
            titleOpacity = 1.0
        }
        
        withAnimation(.easeOut(duration: 1.0).delay(0.3)) {
            cardsOffset = 0
            cardsOpacity = 1.0
        }
        
        // Start button entrance sequence
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            startButtonEntranceSequence()
        }
    }
    
    private func startButtonEntranceSequence() {
        guard !isEntranceComplete else { return }
        
        // Reset entrance state
        entranceIndex = 0
        
        // Create a timer that triggers every 0.15 seconds
        entranceTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { timer in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                entranceIndex += 1
            }
            
            // Stop after all buttons have entered
            if entranceIndex >= 4 {
                timer.invalidate()
                entranceTimer = nil
                isEntranceComplete = true
            }
        }
    }
    
    // MARK: - Responsive Sizing Functions
    
    private func getDeviceType(from size: CGSize) -> DeviceType {
        let minDimension = min(size.width, size.height)
        let maxDimension = max(size.width, size.height)
        
        // More robust device detection for simulators and real devices
        if maxDimension >= 1024 {
            return .iPad
        } else if minDimension >= 414 {
            return .iPhonePlus
        } else if minDimension >= 375 {
            return .iPhoneRegular
        } else if minDimension >= 320 {
            return .iPhoneCompact
        } else {
            // Fallback for very small screens
            return .iPhoneCompact
        }
    }
    
    private func getSpacing(for deviceType: DeviceType, geometry: GeometryProxy) -> CGFloat {
        switch deviceType {
        case .iPad: return geometry.size.height * 0.06
        case .iPhonePlus: return geometry.size.height * 0.035
        case .iPhoneRegular: return geometry.size.height * 0.03
        case .iPhoneCompact: return geometry.size.height * 0.025
        }
    }
    
    private func getTopSpacing(for deviceType: DeviceType, geometry: GeometryProxy) -> CGFloat {
        switch deviceType {
        case .iPad: return geometry.size.height * 0.01 // Reduced from 0.06
        case .iPhonePlus: return geometry.size.height * 0.06 // increase from 0.04
        case .iPhoneRegular: return geometry.size.height * 0.055 // increase from 0.035
        case .iPhoneCompact: return geometry.size.height * 0.05 // increase from 0.03
        }
    }
    
    private func getHorizontalPadding(for deviceType: DeviceType, geometry: GeometryProxy) -> CGFloat {
        switch deviceType {
        case .iPad: return geometry.size.width * 0.08
        case .iPhonePlus: return geometry.size.width * 0.02 // Reduced from 0.04
        case .iPhoneRegular: return geometry.size.width * 0.015 // Reduced from 0.035
        case .iPhoneCompact: return geometry.size.width * 0.01 // Reduced from 0.03
        }
    }
    
    private func getTitleFontSize(for deviceType: DeviceType, geometry: GeometryProxy, isLandscape: Bool) -> CGFloat {
        let baseSizeMultiplier: CGFloat = isLandscape ? 0.35 : (deviceType == .iPad ? 0.3 : 0.22)
        let maxSize: CGFloat
        
        switch deviceType {
        case .iPad: maxSize = isLandscape ? 200 : 160
        case .iPhonePlus: maxSize = isLandscape ? 140 : 85
        case .iPhoneRegular: maxSize = isLandscape ? 120 : 75
        case .iPhoneCompact: maxSize = isLandscape ? 100 : 65
        }
        
        return min(geometry.size.width * baseSizeMultiplier, maxSize)
    }
    
    private func getSubtitleFontSize(for deviceType: DeviceType, geometry: GeometryProxy) -> CGFloat {
        let maxSize: CGFloat
        let multiplier: CGFloat = deviceType == .iPad ? 0.04 : 0.03
        
        switch deviceType {
        case .iPad: maxSize = 36
        case .iPhonePlus: maxSize = 20
        case .iPhoneRegular: maxSize = 18
        case .iPhoneCompact: maxSize = 16
        }
        
        return min(geometry.size.width * multiplier, maxSize)
    }
    
    private func getTitleSpacing(for deviceType: DeviceType) -> CGFloat {
        switch deviceType {
        case .iPad: return 16
        case .iPhonePlus: return 8
        case .iPhoneRegular: return 6
        case .iPhoneCompact: return 5
        }
    }
    
    private func getMarriageCardSize(for deviceType: DeviceType) -> CGSize {
        switch deviceType {
        case .iPad: return CGSize(width: 140, height: 196)
        case .iPhonePlus: return CGSize(width: 70, height: 98)
        case .iPhoneRegular: return CGSize(width: 65, height: 91)
        case .iPhoneCompact: return CGSize(width: 55, height: 77)
        }
    }
    
    private func getMarriageCardSpacing(for deviceType: DeviceType, geometry: GeometryProxy) -> CGFloat {
        switch deviceType {
        case .iPad: return geometry.size.width * 0.04
        case .iPhonePlus: return geometry.size.width * 0.015
        case .iPhoneRegular: return geometry.size.width * 0.012
        case .iPhoneCompact: return geometry.size.width * 0.01
        }
    }
    
    private func getButtonSize(for deviceType: DeviceType) -> CGFloat {
        switch deviceType {
        case .iPad: return 120
        case .iPhonePlus: return 65
        case .iPhoneRegular: return 60
        case .iPhoneCompact: return 55
        }
    }
    
    private func getButtonIconSize(for deviceType: DeviceType) -> CGFloat {
        switch deviceType {
        case .iPad: return 48
        case .iPhonePlus: return 24
        case .iPhoneRegular: return 22
        case .iPhoneCompact: return 20
        }
    }
    
    private func getButtonLabelFontSize(for deviceType: DeviceType) -> CGFloat {
        switch deviceType {
        case .iPad: return 32
        case .iPhonePlus: return 16
        case .iPhoneRegular: return 14
        case .iPhoneCompact: return 12
        }
    }
    
    private func getButtonSpacing(for deviceType: DeviceType, geometry: GeometryProxy) -> CGFloat {
        switch deviceType {
        case .iPad: return geometry.size.width * 0.06
        case .iPhonePlus: return geometry.size.width * 0.02
        case .iPhoneRegular: return geometry.size.width * 0.015
        case .iPhoneCompact: return geometry.size.width * 0.01
        }
    }
    
    private func getFooterSpacing(for deviceType: DeviceType, geometry: GeometryProxy) -> CGFloat {
        switch deviceType {
        case .iPad: return geometry.size.width * 0.12
        case .iPhonePlus: return geometry.size.width * 0.1
        case .iPhoneRegular: return geometry.size.width * 0.08
        case .iPhoneCompact: return geometry.size.width * 0.06
        }
    }
    
    private func getFooterVerticalPadding(for deviceType: DeviceType) -> CGFloat {
        switch deviceType {
        case .iPad: return 12
        case .iPhonePlus: return 10
        case .iPhoneRegular: return 8
        case .iPhoneCompact: return 6
        }
    }
    
    private func getFooterFontSize(for deviceType: DeviceType) -> CGFloat {
        switch deviceType {
        case .iPad: return 18
        case .iPhonePlus: return 14
        case .iPhoneRegular: return 14
        case .iPhoneCompact: return 13
        }
    }
    
    private func getSubtitleToCardsSpacing(for deviceType: DeviceType) -> CGFloat {
        switch deviceType {
        case .iPad: return 0
        case .iPhonePlus: return 20
        case .iPhoneRegular: return 16
        case .iPhoneCompact: return 12
        }
    }
    
    private func getSheetDetents(for deviceType: DeviceType) -> Set<PresentationDetent> {
        switch deviceType {
        case .iPad: return [.large, .medium]
        default: return [.medium]
        }
    }
    
    // MARK: - Game Functions
    
    private func startGame() {
        print("🎮 startGame() called")
        isConfiguringGame = true
        configurationMessage = "Configuring game for \(gameRules.playerCount) players..."
        
        if game == nil {
            game = Game(gameRules: gameRules)
        }
        
        game?.initializeFromConfiguration()
        game?.startNewGame()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isConfiguringGame = false
            isGameActive = true
        }
    }
    
    private func restorePurchase() {
        print("Restore Purchase tapped")
    }
}

// MARK: - Enhanced Components

struct EnhancedMarriageCardView: View {
    let suit: CardSuit
    let angle: Double
    var cardSize: CGSize = CGSize(width: 120, height: 168)
    @State private var hoverScale: CGFloat = 1.0
    @State private var shadowRadius: CGFloat = 8
    
    var body: some View {
        ZStack {
            // King card with enhanced effects
            ZStack {
                Image(getKingImageName())
                    .resizable()
                    .aspectRatio(2.5/3.5, contentMode: .fit)
                    .frame(maxWidth: cardSize.width, maxHeight: cardSize.height)
                    .background(Color.white)
                    .cornerRadius(6)
                    .shadow(color: .black.opacity(0.3), radius: shadowRadius, x: 4, y: 6)
                    .shadow(color: getSuitColor().opacity(0.2), radius: 4, x: 0, y: 0)
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(
                                LinearGradient(
                                    colors: [getSuitColor(), getSuitColor().opacity(0.5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            }
            .offset(x: -cardSize.width * 0.1, y: -cardSize.height * 0.07)
            .rotationEffect(.degrees(angle))
            .scaleEffect(hoverScale)
            
            // Queen card with enhanced effects
            ZStack {
                Image(getQueenImageName())
                    .resizable()
                    .aspectRatio(2.5/3.5, contentMode: .fit)
                    .frame(maxWidth: cardSize.width, maxHeight: cardSize.height)
                    .background(Color.white)
                    .cornerRadius(3)
                    .shadow(color: .black.opacity(0.3), radius: shadowRadius, x: 4, y: 6)
                    .shadow(color: getSuitColor().opacity(0.2), radius: 4, x: 0, y: 0)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(
                                LinearGradient(
                                    colors: [getSuitColor(), getSuitColor().opacity(0.5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            }
            .offset(x: cardSize.width * 0.1, y: cardSize.height * 0.07)
            .rotationEffect(.degrees(-angle))
            .scaleEffect(hoverScale)
        }
        .frame(maxWidth: cardSize.width * 1.5, maxHeight: cardSize.height * 1.2)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                hoverScale = 1.1
                shadowRadius = 12
            }
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.1)) {
                hoverScale = 1.0
                shadowRadius = 8
            }
        }
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
        case .spades, .clubs: return .black
        case .hearts, .diamonds: return .red
        }
    }
}

struct EnhancedCircularButtonView: View {
    let icon: String
    let outlineColor: Color
    let action: () -> Void
    var buttonSize: CGFloat = 100
    var iconFontSize: CGFloat = 40
    let buttonIndex: Int // For sequential rippling
    let entranceIndex: Int // Current entrance animation index
    let onRippleTrigger: () -> Void // Callback for ripple coordination
    let onGlobalRipple: (CGPoint) -> Void
    
    @State private var isPressed = false
    
    // Audio state
    @State private var audioPlayer: AVAudioPlayer?
    
    // Dropping animation state
    @State private var dropOffset: CGFloat = 0
    @State private var dropScale: CGFloat = 1.0
    @State private var isDropping = false
    
    // Entrance animation state
    @State private var hasEntered = false
    @State private var wobbleAngle: Double = 0
    
    var body: some View {
        GeometryReader { geo in
            Button(action: {
                let center = CGPoint(
                    x: geo.frame(in: .global).midX,
                    y: geo.frame(in: .global).midY
                )
                
                // Start dropping animation
                withAnimation(.easeIn(duration: 0.3)) {
                    isDropping = true
                    dropOffset = 20 // Fall down 20 points
                    dropScale = 0.9 // Slightly shrink as it falls
                }
                
                // Reset drop animation after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    // Reset drop animation
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        isDropping = false
                        dropOffset = 0
                        dropScale = 1.0
                    }
                }
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isPressed = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                }
                
                action()
            }) {
                ZStack {
                    // Main button background with enhanced depth
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white,
                                    Color.white.opacity(0.95),
                                    Color.white.opacity(0.9)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: buttonSize, height: buttonSize)
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                        .shadow(color: .black.opacity(0.1), radius: 16, x: 0, y: 8)
                        .shadow(color: outlineColor.opacity(0.3), radius: 6, x: 0, y: 0)
                        .shadow(color: .black.opacity(isDropping ? 0.4 : 0.15), radius: isDropping ? 12 : 8, x: 0, y: isDropping ? 8 : 4)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )

                    // Icon with enhanced styling
                    Image(systemName: icon)
                        .font(.system(size: iconFontSize, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [outlineColor, outlineColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: outlineColor.opacity(0.4), radius: 3, x: 1, y: 1)
                }
                .offset(y: dropOffset)
                .scaleEffect(dropScale)
                .rotationEffect(.degrees(wobbleAngle))
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .frame(width: buttonSize, height: buttonSize) // Limit GeometryReader to button bounds
        // Apply entrance animation based on entranceIndex
        .offset(y: entranceIndex > buttonIndex ? 0 : -50)
        .opacity(entranceIndex > buttonIndex ? 1 : 0)
        .onChange(of: entranceIndex) { newIndex in
            if newIndex == buttonIndex + 1 {
                // Button's turn to enter
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    isDropping = true
                    dropOffset = 22
                    dropScale = 0.9
                }
                
                // Trigger splash effect
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    onRippleTrigger()
                    
                    // Use relative positioning for ripple
                    let center = CGPoint(
                        x: UIScreen.main.bounds.width / 2,
                        y: UIScreen.main.bounds.height / 2 - CGFloat(buttonIndex) * 100
                    )
                    onGlobalRipple(center)
                    
                    // Wobble sequence
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.45)) {
                        isDropping = false
                        dropOffset = 0
                        dropScale = 1.0
                        wobbleAngle = 6
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) {
                            wobbleAngle = -4
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.65)) {
                                wobbleAngle = 0
                            }
                        }
                    }
                }
            }
        }
    }
    
    func playNote(for index: Int) {
        let noteFiles = ["note_g", "note_eb", "note_c", "note_b", "chord_c_minor"]
        guard index < noteFiles.count else { return }

        if let url = Bundle.main.url(forResource: noteFiles[index], withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
            } catch {
                print("❌ Failed to play note: \(error)")
            }
        }
    }
}

// MARK: - Helper Extensions
extension CGRect {
    var center: CGPoint {
        CGPoint(x: self.midX, y: self.midY)
    }
}

struct EnhancedFooterButton: View {
    let title: String
    let action: () -> Void
    let deviceType: DeviceType
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: getFooterFontSize(for: deviceType), weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: isHovered ? [Color.white, Color.white.opacity(0.8)] : [Color.white.opacity(0.9), Color.white.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .underline()
                .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 1)
        }
        .scaleEffect(isHovered ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onTapGesture {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isHovered = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isHovered = false
                }
            }
            action()
        }
    }
    
    private func getFooterFontSize(for deviceType: DeviceType) -> CGFloat {
        switch deviceType {
        case .iPad: return 20
        case .iPhonePlus: return 14
        case .iPhoneRegular: return 14
        case .iPhoneCompact: return 13
        }
    }
}

// MARK: - Particle Effect View
struct EnhancedParticleView: View {
    @State private var particles: [Particle] = []
    let geometry: GeometryProxy
    
    var body: some View {
        ZStack {
            ForEach(particles, id: \.id) { particle in
                Circle()
                    .fill(particle.color.opacity(particle.opacity))
                    .frame(width: particle.size, height: particle.size)
                    .position(particle.position)
                    .blur(radius: particle.blur)
            }
        }
        .onAppear {
            createParticles()
            animateParticles()
        }
    }
    
    private func createParticles() {
        particles = (0..<15).map { _ in
            Particle(
                id: UUID(),
                position: CGPoint(
                    x: CGFloat.random(in: 0...geometry.size.width),
                    y: CGFloat.random(in: 0...geometry.size.height)
                ),
                size: CGFloat.random(in: 2...6),
                color: [Color(hex: "F1B517"), Color(hex: "D21034"), Color(hex: "016A16"), Color(hex: "00209F")].randomElement() ?? Color.white,
                opacity: Double.random(in: 0.1...0.3),
                blur: CGFloat.random(in: 1...3)
            )
        }
    }
    
    private func animateParticles() {
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            for i in 0..<particles.count {
                withAnimation(.linear(duration: 8.0)) {
                    let newX = particles[i].position.x + CGFloat.random(in: -1...1)
                    let newY = particles[i].position.y + CGFloat.random(in: -1...1)
                    
                    // Constrain particles to view bounds
                    particles[i].position.x = max(0, min(geometry.size.width, newX))
                    particles[i].position.y = max(0, min(geometry.size.height, newY))
                    particles[i].opacity = Double.random(in: 0.05...0.25)
                }
            }
        }
    }
}

struct Particle {
    let id: UUID
    var position: CGPoint
    let size: CGFloat
    let color: Color
    var opacity: Double
    let blur: CGFloat
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Device Type and other enums
enum DeviceType {
    case iPad
    case iPhonePlus
    case iPhoneRegular
    case iPhoneCompact
}

enum CardSuit {
    case spades, hearts, diamonds, clubs
}

#Preview {
    HomePageView()
}

// MARK: - Missing View Placeholders
struct HowToPlayView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("How to Play")
                .font(.title.bold())
                .foregroundColor(.white)
            
            Text("Bésigue is a trick-taking card game...")
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding()
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.9))
    }
}

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
                Text("About Bésigue")
                .font(.title.bold())
                .foregroundColor(.white)
            
            Text("A modern implementation of the classic card game...")
                .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                .padding()
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.9))
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Privacy Policy")
                .font(.title.bold())
                .foregroundColor(.white)
            
            Text("Your privacy is important to us...")
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding()
                
                Spacer()
            }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.9))
    }
}
