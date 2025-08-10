import SwiftUI

/// MultiplayerLobbyView provides an interface for creating and joining multiplayer games
struct MultiplayerLobbyView: View {
    
    // MARK: - State
    @StateObject private var gameSession: GameSession
    @State private var showingCreateGame = false
    @State private var selectedGameRules = GameRules()
    @State private var playerName: String = ""
    @State private var serverURL: String = "ws://localhost:8080"
    
    // MARK: - Initialization
    init() {
        let networkService = NetworkService(serverURL: URL(string: "ws://localhost:8080")!)
        let playerId = UUID()
        let playerName = "Player \(Int.random(in: 1000...9999))"
        
        self._gameSession = StateObject(wrappedValue: GameSession(
            networkService: networkService,
            playerId: playerId,
            playerName: playerName
        ))
        
        self._playerName = State(initialValue: playerName)
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                headerSection
                
                // Connection Status
                connectionStatusSection
                
                // Available Games
                if gameSession.sessionState == .connected {
                    availableGamesSection
                }
                
                // Action Buttons
                actionButtonsSection
                
                Spacer()
            }
            .padding()
            .navigationTitle("Multiplayer Lobby")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingCreateGame) {
                CreateGameView(gameSession: gameSession)
            }
        }
        .onAppear {
            setupGameSession()
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "network")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text("Multiplayer Besigue")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Connect with friends and play together")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    private var connectionStatusSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: connectionStatusIcon)
                    .foregroundColor(connectionStatusColor)
                    .font(.title2)
                
                VStack(alignment: .leading) {
                    Text(connectionStatusTitle)
                        .font(.headline)
                    Text(connectionStatusMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            if let error = gameSession.lastError {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(error.localizedDescription)
                        .font(.caption)
                        .foregroundColor(.red)
                    Spacer()
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    private var availableGamesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Available Games")
                    .font(.headline)
                Spacer()
                Button("Refresh") {
                    gameSession.refreshAvailableGames()
                }
                .font(.caption)
            }
            
            if gameSession.availableGames.isEmpty {
                Text("No games available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            } else {
                ForEach(gameSession.availableGames) { game in
                    GameLobbyRow(game: game, gameSession: gameSession)
                }
            }
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Connect/Disconnect Button
            Button(action: toggleConnection) {
                HStack {
                    Image(systemName: gameSession.sessionState == .connected ? "wifi.slash" : "wifi")
                    Text(gameSession.sessionState == .connected ? "Disconnect" : "Connect")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(gameSession.sessionState == .connected ? Color.red : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(gameSession.sessionState == .connecting || gameSession.sessionState == .reconnecting)
            
            // Create Game Button
            Button("Create New Game") {
                showingCreateGame = true
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(12)
            .disabled(gameSession.sessionState != .connected)
        }
    }
    
    // MARK: - Computed Properties
    
    private var connectionStatusIcon: String {
        switch gameSession.sessionState {
        case .disconnected:
            return "wifi.slash"
        case .connecting:
            return "wifi.exclamationmark"
        case .connected:
            return "wifi"
        case .creatingGame, .joiningGame:
            return "gamecontroller"
        case .inGame:
            return "gamecontroller.fill"
        case .reconnecting:
            return "wifi.slash"
        }
    }
    
    private var connectionStatusColor: Color {
        switch gameSession.sessionState {
        case .disconnected, .reconnecting:
            return .red
        case .connecting, .creatingGame, .joiningGame:
            return .orange
        case .connected, .inGame:
            return .green
        }
    }
    
    private var connectionStatusTitle: String {
        switch gameSession.sessionState {
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting..."
        case .connected:
            return "Connected"
        case .creatingGame:
            return "Creating Game..."
        case .joiningGame:
            return "Joining Game..."
        case .inGame:
            return "In Game"
        case .reconnecting:
            return "Reconnecting..."
        }
    }
    
    private var connectionStatusMessage: String {
        switch gameSession.sessionState {
        case .disconnected:
            return "Tap Connect to join the server"
        case .connecting:
            return "Establishing connection..."
        case .connected:
            return "Ready to create or join games"
        case .creatingGame:
            return "Setting up your game..."
        case .joiningGame:
            return "Joining the selected game..."
        case .inGame:
            return "Game in progress"
        case .reconnecting:
            return "Attempting to reconnect..."
        }
    }
    
    // MARK: - Methods
    
    private func setupGameSession() {
        // Set up any additional configuration
        print("🎮 Setting up multiplayer lobby")
    }
    
    private func toggleConnection() {
        if gameSession.sessionState == .connected {
            gameSession.leaveGame()
            gameSession.disconnect()
        } else {
            gameSession.connect()
        }
    }
}

// MARK: - Supporting Views

struct GameLobbyRow: View {
    let game: GameLobby
    let gameSession: GameSession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(game.name)
                    .font(.headline)
                Text("Host: \(game.hostName)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(game.currentPlayers)/\(game.playerCount) players")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(game.status.rawValue.capitalized)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor)
                    .foregroundColor(.white)
                    .cornerRadius(6)
                
                Button("Join") {
                    gameSession.joinGame(game)
                }
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .disabled(game.currentPlayers >= game.playerCount || game.status != .waiting)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var statusColor: Color {
        switch game.status {
        case .waiting:
            return .green
        case .starting:
            return .orange
        case .inProgress:
            return .blue
        case .finished:
            return .gray
        }
    }
}

struct CreateGameView: View {
    @ObservedObject var gameSession: GameSession
    @Environment(\.dismiss) private var dismiss
    @State private var gameName: String = ""
    @State private var selectedPlayerCount = 2
    @State private var selectedGameLevel: GameLevel = .pro
    
    var body: some View {
        NavigationView {
            Form {
                Section("Game Settings") {
                    TextField("Game Name", text: $gameName)
                    
                    Picker("Players", selection: $selectedPlayerCount) {
                        ForEach(2...4, id: \.self) { count in
                            Text("\(count) Players").tag(count)
                        }
                    }
                    
                    Picker("Game Level", selection: $selectedGameLevel) {
                        ForEach(GameLevel.allCases, id: \.self) { level in
                            Text(level.rawValue.capitalized).tag(level)
                        }
                    }
                }
                
                Section {
                    Button("Create Game") {
                        createGame()
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(gameName.isEmpty)
                }
            }
            .navigationTitle("Create Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func createGame() {
        let gameRules = GameRules()
        gameRules.playerCount = selectedPlayerCount
        gameRules.gameLevel = selectedGameLevel
        
        if gameSession.createGame(gameRules: gameRules) {
            dismiss()
        }
    }
}

// MARK: - Preview

struct MultiplayerLobbyView_Previews: PreviewProvider {
    static var previews: some View {
        MultiplayerLobbyView()
    }
} 