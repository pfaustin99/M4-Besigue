import Foundation

// MARK: - Sound Constants
struct SoundConstants {
    
    // MARK: - File Names
    struct FileNames {
        // UI Sounds
        static let buttonTap = "button_tap.mp3"
        static let cardSelect = "card_select.mp3"
        static let menuNavigate = "menu_navigate.mp3"
        
        // Game Sounds
        static let cardDeal = "card_deal.mp3"
        static let cardPlay = "card_play.mp3"
        static let trickWin = "trick_win.mp3"
        static let gameStart = "game_start.mp3"
        static let gameEnd = "game_end.mp3"
        static let shuffle = "shuffle.mp3"
        
        // Player Count Sounds
        static let twoPlayers = "2players.mp3"
        static let threePlayers = "3players.mp3"
        static let fourPlayers = "4players.mp3"
        
        // Meld Sounds
        static let meld100 = "meld_100.mp3"
        static let meld80 = "meld_80.mp3"
        static let meld60 = "meld_60.mp3"
        static let royalMarriage = "royalMarriage.mp3"
        static let meld40 = "meld_40.mp3"
        static let meld20 = "meld_20.mp3"
        static let meld10 = "meld_10.mp3"
        static let meld250 = "meld_250.mp3"
        static let besigueMeld = "besigue_meld.mp3"
        
        // Dog Sounds
        static let dog1 = "dog1.mp3"
        static let dog2 = "dog2.mp3"
        static let dog3 = "dog3.mp3"
        static let dog4 = "dog4.mp3"
        
        // Background Music
        static let backgroundMusic = "background_music.mp3"
    }
    
    // MARK: - Volume Levels
    struct Volume {
        static let defaultSoundVolume: Float = 0.7
        static let defaultMusicVolume: Float = 0.5
        static let maxVolume: Float = 1.0
        static let minVolume: Float = 0.0
    }
    
    // MARK: - Usage Guidelines
    struct Usage {
        // When to play UI sounds
        static let buttonTapEvents = [
            "Homepage button taps",
            "Settings button taps",
            "Menu navigation",
            "Dialog button taps"
        ]
        
        // When to play game sounds
        static let cardDealEvents = [
            "Initial card dealing",
            "Drawing cards from deck"
        ]
        
        static let cardPlayEvents = [
            "Playing a card",
            "Card selection"
        ]
        
        static let trickWinEvents = [
            "Winning a trick",
            "Trick completion"
        ]
        
        static let gameEvents = [
            "Game start",
            "Game end",
            "Deck shuffling"
        ]
        
        static let meldEvents = [
            "250 point melds",
            "100 point melds",
            "80 point melds", 
            "60 point melds",
            "Royal marriages",
            "Bésigue melds (jack of diamonds + queen of spades)",
            "40 point melds",
            "20 point melds",
            "10 point melds (7 of trump suit)"
        ]
        
        static let dogSoundEvents = [
            "Player takes too long (5+ seconds)",
            "4 jacks meld",
            "7 of trump card played",
            "Last place person has to play"
        ]
    }
} 