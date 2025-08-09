import Foundation
import AVFoundation
import SwiftUI

// MARK: - Sound Categories
enum SoundCategory: String, CaseIterable {
    case ui = "ui"
    case game = "game"
    case music = "music"
}

// MARK: - Sound Types
enum SoundType: String, CaseIterable {
    // UI Sounds
    case buttonTap = "button_tap"
    case cardSelect = "card_select"
    case menuNavigate = "menu_navigate"
    
    // Game Sounds
    case cardDeal = "card_deal"
    case cardPlay = "card_play"
    case trickWin = "trick_win"
    case gameStart = "game_start"
    case gameEnd = "game_end"
    case shuffle = "shuffle"
    
    // Meld Sounds
    case meld100 = "meld_100"
    case meld80 = "meld_80"
    case meld60 = "meld_60"
    case royalMarriage = "royal_marriage"
    case meld40 = "meld_40"
    case meld20 = "meld_20"
    case meld10 = "meld_10"
    case meld250 = "meld_250"
    case besigueMeld = "besigue_meld"
    
    // Dog Sounds (for last place person)
    case dog1 = "dog1"
    case dog2 = "dog2"
    case dog3 = "dog3"
    case dog4 = "dog4"
    
    // Player Count Sounds
    case twoPlayers = "2players"
    case threePlayers = "3players"
    case fourPlayers = "4players"
    
    // Background Music
    case backgroundMusic = "background_music"
    
    var category: SoundCategory {
        switch self {
        case .buttonTap, .cardSelect, .menuNavigate:
            return .ui
        case .cardDeal, .cardPlay, .trickWin, .gameStart, .gameEnd, .shuffle:
            return .game
        case .meld100, .meld80, .meld60, .royalMarriage, .meld40, .meld20, .meld10, .meld250, .besigueMeld:
            return .game
        case .dog1, .dog2, .dog3, .dog4, .twoPlayers, .threePlayers, .fourPlayers:
            return .game
        case .backgroundMusic:
            return .music
        }
    }
    
    var filename: String {
        return "\(self.rawValue).mp3"
    }
}

// MARK: - Audio Manager
class AudioManager: ObservableObject {
    static let shared = AudioManager()
    
    // MARK: - Properties
    @Published var isSoundEnabled: Bool = true
    @Published var isMusicEnabled: Bool = true
    @Published var isDogSoundsEnabled: Bool = true
    @Published var soundVolume: Float = 0.7
    @Published var musicVolume: Float = 0.5
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private var backgroundMusicPlayer: AVAudioPlayer?
    
    // MARK: - Initialization
    private init() {
        setupAudioSession()
        loadUserPreferences()
    }
    
    // MARK: - Audio Session Setup
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ Failed to setup audio session: \(error)")
        }
    }
    
    // MARK: - User Preferences
    private func loadUserPreferences() {
        // Load from UserDefaults or other storage
        isSoundEnabled = UserDefaults.standard.bool(forKey: "AudioManager.isSoundEnabled")
        isMusicEnabled = UserDefaults.standard.bool(forKey: "AudioManager.isMusicEnabled")
        isDogSoundsEnabled = UserDefaults.standard.bool(forKey: "AudioManager.isDogSoundsEnabled")
        soundVolume = UserDefaults.standard.float(forKey: "AudioManager.soundVolume")
        musicVolume = UserDefaults.standard.float(forKey: "AudioManager.musicVolume")
        
        // Set defaults if not previously saved
        if UserDefaults.standard.object(forKey: "AudioManager.isSoundEnabled") == nil {
            isSoundEnabled = true
            UserDefaults.standard.set(true, forKey: "AudioManager.isSoundEnabled")
        }
        if UserDefaults.standard.object(forKey: "AudioManager.isMusicEnabled") == nil {
            isMusicEnabled = true
            UserDefaults.standard.set(true, forKey: "AudioManager.isMusicEnabled")
        }
        if UserDefaults.standard.object(forKey: "AudioManager.soundVolume") == nil {
            soundVolume = 0.7
            UserDefaults.standard.set(0.7, forKey: "AudioManager.soundVolume")
        }
        if UserDefaults.standard.object(forKey: "AudioManager.musicVolume") == nil {
            musicVolume = 0.5
            UserDefaults.standard.set(0.5, forKey: "AudioManager.musicVolume")
        }
    }
    
    private func saveUserPreferences() {
        UserDefaults.standard.set(isSoundEnabled, forKey: "AudioManager.isSoundEnabled")
        UserDefaults.standard.set(isMusicEnabled, forKey: "AudioManager.isMusicEnabled")
        UserDefaults.standard.set(isDogSoundsEnabled, forKey: "AudioManager.isDogSoundsEnabled")
        UserDefaults.standard.set(soundVolume, forKey: "AudioManager.soundVolume")
        UserDefaults.standard.set(musicVolume, forKey: "AudioManager.musicVolume")
    }
    
    // MARK: - Sound Playback
    func playSound(_ soundType: SoundType) {
        guard isSoundEnabled else { return }
        
        // Check if dog sounds are disabled for dog sound types
        if [.dog1, .dog2, .dog3, .dog4].contains(soundType) && !isDogSoundsEnabled {
            return
        }
        
        let key = soundType.rawValue
        
        // Check if player already exists
        if let player = audioPlayers[key] {
            player.currentTime = 0
            player.volume = soundVolume
            player.play()
            return
        }
        
        // Create new player
        guard let url = Bundle.main.url(forResource: soundType.rawValue, withExtension: "mp3") else {
            print("❌ Sound file not found: \(soundType.filename)")
            return
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.volume = soundVolume
            audioPlayers[key] = player
            player.play()
        } catch {
            print("❌ Failed to play sound \(soundType.rawValue): \(error)")
        }
    }
    
    // MARK: - Background Music
    func playBackgroundMusic() {
        guard isMusicEnabled else { return }
        
        let soundType = SoundType.backgroundMusic
        guard let url = Bundle.main.url(forResource: soundType.rawValue, withExtension: "mp3") else {
            print("❌ Background music file not found: \(soundType.filename)")
            return
        }
        
        do {
            backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url)
            backgroundMusicPlayer?.numberOfLoops = -1 // Loop indefinitely
            backgroundMusicPlayer?.volume = musicVolume
            backgroundMusicPlayer?.play()
        } catch {
            print("❌ Failed to play background music: \(error)")
        }
    }
    
    func stopBackgroundMusic() {
        backgroundMusicPlayer?.stop()
        backgroundMusicPlayer = nil
    }
    
    func pauseBackgroundMusic() {
        backgroundMusicPlayer?.pause()
    }
    
    func resumeBackgroundMusic() {
        guard isMusicEnabled else { return }
        backgroundMusicPlayer?.play()
    }
    
    // MARK: - Volume Control
    func setSoundVolume(_ volume: Float) {
        soundVolume = max(0.0, min(1.0, volume))
        saveUserPreferences()
        
        // Update all active players
        for player in audioPlayers.values {
            player.volume = soundVolume
        }
    }
    
    func setMusicVolume(_ volume: Float) {
        musicVolume = max(0.0, min(1.0, volume))
        saveUserPreferences()
        backgroundMusicPlayer?.volume = musicVolume
    }
    
    // MARK: - Toggle Functions
    func toggleSound() {
        isSoundEnabled.toggle()
        saveUserPreferences()
        
        if !isSoundEnabled {
            // Stop all sound players
            for player in audioPlayers.values {
                player.stop()
            }
        }
    }
    
    func toggleMusic() {
        isMusicEnabled.toggle()
        saveUserPreferences()
        
        if isMusicEnabled {
            if backgroundMusicPlayer != nil {
                resumeBackgroundMusic()
            } else {
                playBackgroundMusic()
            }
        } else {
            pauseBackgroundMusic()
        }
    }
    
    func toggleDogSounds() {
        isDogSoundsEnabled.toggle()
        saveUserPreferences()
    }
    
    // MARK: - Convenience Methods
    func playButtonTap() {
        playSound(.buttonTap)
    }
    
    func playCardSelect() {
        playSound(.cardSelect)
    }
    
    func playCardDeal() {
        playSound(.cardDeal)
    }
    
    func playCardPlay() {
        playSound(.cardPlay)
    }
    
    func playTrickWin() {
        playSound(.trickWin)
    }
    
    func playGameStart() {
        playSound(.gameStart)
    }
    
    func playGameEnd() {
        playSound(.gameEnd)
    }
    
    func playShuffle() {
        playSound(.shuffle)
    }
    
    // MARK: - Meld Sound Methods
    func playMeld100() {
        playSound(.meld100)
    }
    
    func playMeld80() {
        playSound(.meld80)
    }
    
    func playMeld60() {
        playSound(.meld60)
    }
    
    func playRoyalMarriage() {
        playSound(.royalMarriage)
    }
    
    func playMeld40() {
        playSound(.meld40)
    }
    
    func playMeld20() {
        playSound(.meld20)
    }
    
    func playMeld10() {
        playSound(.meld10)
    }
    
    func playMeld250() {
        playSound(.meld250)
    }
    
    func playBesigueMeld() {
        playSound(.besigueMeld)
    }
    
    // MARK: - Dog Sound Methods
    func playDog1() {
        playSound(.dog1)
    }
    
    func playDog2() {
        playSound(.dog2)
    }
    
    func playDog3() {
        playSound(.dog3)
    }
    
    func playDog4() {
        playSound(.dog4)
    }
    
    // MARK: - Player Count Specific Sound Methods
    func playGameStart2Players() {
        playSound(.twoPlayers)
    }
    
    func playGameStart3Players() {
        playSound(.threePlayers)
    }
    
    func playGameStart4Players() {
        playSound(.fourPlayers)
    }
    
    // MARK: - Cleanup
    func cleanup() {
        for player in audioPlayers.values {
            player.stop()
        }
        audioPlayers.removeAll()
        stopBackgroundMusic()
    }
}

// MARK: - Audio Manager Environment Key
struct AudioManagerKey: EnvironmentKey {
    static let defaultValue = AudioManager.shared
}

extension EnvironmentValues {
    var audioManager: AudioManager {
        get { self[AudioManagerKey.self] }
        set { self[AudioManagerKey.self] = newValue }
    }
} 