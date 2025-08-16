import Foundation
import Combine

final class AIResponseCoordinator: ObservableObject {
    // MARK: - Dependencies
    private let game: Game
    private let aiService: AIService

    // MARK: - Coordination
    private let aiQueue = DispatchQueue(label: "ai.response.coordinator", qos: .userInitiated)
    private var cancellables = Set<AnyCancellable>()
    private var isMonitoring = false

    // MARK: - Init
    init(game: Game, aiService: AIService) {
        self.game = game
        self.aiService = aiService
    }

    // MARK: - Monitoring
    func startMonitoring() {
        guard !isMonitoring else {
            print("🤖 AI Response Coordinator: Monitoring already active, skipping")
            return
        }

        print("🤖 AI Response Coordinator: Starting minimal monitoring (handoff only)")

        // --- Build lightweight, type-erased publishers to help the compiler ---
        let drawEvents: AnyPublisher<(Int, Int), Never> = game.$trickEpoch
            .combineLatest(game.$currentDrawIndex)
            .map { trickEpoch, drawIndex -> (Int, Int) in (trickEpoch, drawIndex) }
            .removeDuplicates(by: { lhs, rhs in (lhs.0 == rhs.0) && (lhs.1 == rhs.1) })
            .eraseToAnyPublisher()

        // Unified PLAY or WINNER: if a winner exists for the trick, emit WINNER; otherwise emit PLAY
        let playOrWinnerEvents: AnyPublisher<(String, Int, Int), Never> = game.$trickEpoch
            .combineLatest(game.$currentPlayIndex, game.$winningCardIndex)
            .map { trickEpoch, playIndex, winnerOpt -> (String, Int, Int) in
                if let w = winnerOpt { return ("WINNER", trickEpoch, w) }
                return ("PLAY", trickEpoch, playIndex)
            }
            .removeDuplicates(by: { lhs, rhs in (lhs.0 == rhs.0) && (lhs.1 == rhs.1) && (lhs.2 == rhs.2) })
            .eraseToAnyPublisher()

        // --- Subscriptions ---
        drawEvents
            .receive(on: aiQueue)
            .sink { [weak self] (trickEpoch: Int, index: Int) in
                self?.handleEventHandoff(tag: "DRAW", trickNumber: trickEpoch, index: index)
            }
            .store(in: &cancellables)

        playOrWinnerEvents
            .receive(on: aiQueue)
            .sink { [weak self] (tag: String, trickEpoch: Int, index: Int) in
                self?.handleEventHandoff(tag: tag, trickNumber: trickEpoch, index: index)
            }
            .store(in: &cancellables)

        isMonitoring = true
        print("🤖 AI Response Coordinator: Minimal monitoring active (handoff only)")
    }

    func stopMonitoring() {
        guard isMonitoring else { return }
        cancellables.removeAll()
        isMonitoring = false
        print("🤖 AI Response Coordinator: Monitoring stopped")
    }

    // MARK: - Handoff
    private func handleEventHandoff(tag: String, trickNumber: Int, index: Int) {
        guard index >= 0 && index < game.players.count else {
            print("🤖 ERROR [\(tag)]: index \(index) out of bounds (0-\(game.players.count-1))")
            return
        }
        let player = game.players[index]
        guard player.type == .ai else { return }
        print("🤖 AI \(player.name) [\(tag)] event at trick \(trickNumber), index \(index) → handoff")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            player.makeAIDecision(in: self.game, aiService: self.aiService)
        }
    }
}
