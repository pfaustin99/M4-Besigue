import Foundation
import SwiftUI

class Settings: ObservableObject, Codable {
    @Published var playerCount: Int = 2
    @Published var handSize: Int = 8
    @Published var playDirection: String = "clockwise"
    @Published var gameLevel: String = "standard"
    // Add other settings as needed
    
    enum CodingKeys: CodingKey {
        case playerCount, handSize, playDirection, gameLevel
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        playerCount = try container.decode(Int.self, forKey: .playerCount)
        handSize = try container.decode(Int.self, forKey: .handSize)
        playDirection = try container.decode(String.self, forKey: .playDirection)
        gameLevel = try container.decode(String.self, forKey: .gameLevel)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(playerCount, forKey: .playerCount)
        try container.encode(handSize, forKey: .handSize)
        try container.encode(playDirection, forKey: .playDirection)
        try container.encode(gameLevel, forKey: .gameLevel)
    }
    
    init() {}
} 