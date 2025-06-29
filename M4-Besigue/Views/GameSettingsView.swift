import SwiftUI

struct GameSettingsView: View {
    @ObservedObject var gameRules: GameRules
    @Environment(\.dismiss) private var dismiss
    @State private var showingStartGame = false
    let onSave: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Custom Navigation Bar
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                
                Spacer()
                
                Text("Game Settings")
                    .font(.headline)
                
                Spacer()
                
                Button("Save") {
                    onSave()
                    dismiss()
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .shadow(radius: 1)
            
            // Content - Remove .scrollIndicators and use showsIndicators instead
            ScrollView(showsIndicators: true) {
                VStack(spacing: 20) {
                    // Game Rules Section
                    SettingsSection(title: "Game Rules") {
                        VStack(spacing: 12) {
                            SettingsRow(title: "Number of Players", value: "\(gameRules.playerCount)") {
                                Stepper("", value: $gameRules.playerCount, in: 2...4)
                            }
                            
                            SettingsRow(title: "Hand Size", value: "\(gameRules.handSize)") {
                                Stepper("", value: $gameRules.handSize, in: 6...12)
                            }
                            
                            Picker("Play Direction", selection: $gameRules.playDirection) {
                                Text("Right (Counterclockwise)").tag(PlayDirection.right)
                                Text("Left (Clockwise)").tag(PlayDirection.left)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            
                            Picker("Game Level", selection: $gameRules.gameLevel) {
                                Text("Novice (Hints Enabled)").tag(GameLevel.novice)
                                Text("Pro (No Hints)").tag(GameLevel.pro)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        .padding(.horizontal)
                    }
                    
                    // Scoring Section
                    SettingsSection(title: "Scoring") {
                        VStack(spacing: 12) {
                            SettingsRow(title: "Winning Score", value: "\(gameRules.winningScore)") {
                                Stepper("", value: $gameRules.winningScore, in: 100...2000, step: 10)
                            }
                            
                            SettingsRow(title: "Final Trick Bonus", value: "\(gameRules.finalTrickBonus)") {
                                Stepper("", value: $gameRules.finalTrickBonus, in: 0...100, step: 1)
                            }
                            
                            SettingsRow(title: "Trick with Seven Trump", value: "\(gameRules.trickWithSevenTrumpPoints)") {
                                Stepper("", value: $gameRules.trickWithSevenTrumpPoints, in: 0...100, step: 1)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Meld Points Section
                    SettingsSection(title: "Meld Points") {
                        VStack(spacing: 12) {
                            SettingsRow(title: "Bésigue", value: "\(gameRules.besiguePoints)") {
                                Stepper("", value: $gameRules.besiguePoints, in: 10...100, step: 5)
                            }
                            
                            SettingsRow(title: "Royal Marriage", value: "\(gameRules.royalMarriagePoints)") {
                                Stepper("", value: $gameRules.royalMarriagePoints, in: 10...100, step: 5)
                            }
                            
                            SettingsRow(title: "Common Marriage", value: "\(gameRules.commonMarriagePoints)") {
                                Stepper("", value: $gameRules.commonMarriagePoints, in: 5...50, step: 5)
                            }
                            
                            SettingsRow(title: "Four Aces", value: "\(gameRules.fourAcesPoints)") {
                                Stepper("", value: $gameRules.fourAcesPoints, in: 50...200, step: 10)
                            }
                            
                            SettingsRow(title: "Four Kings", value: "\(gameRules.fourKingsPoints)") {
                                Stepper("", value: $gameRules.fourKingsPoints, in: 40...150, step: 10)
                            }
                            
                            SettingsRow(title: "Four Queens", value: "\(gameRules.fourQueensPoints)") {
                                Stepper("", value: $gameRules.fourQueensPoints, in: 30...120, step: 10)
                            }
                            
                            SettingsRow(title: "Four Jacks", value: "\(gameRules.fourJacksPoints)") {
                                Stepper("", value: $gameRules.fourJacksPoints, in: 20...100, step: 10)
                            }
                            
                            SettingsRow(title: "Four Jokers", value: "\(gameRules.fourJokersPoints)") {
                                Stepper("", value: $gameRules.fourJokersPoints, in: 100...500, step: 25)
                            }
                            
                            SettingsRow(title: "Sequence", value: "\(gameRules.sequencePoints)") {
                                Stepper("", value: $gameRules.sequencePoints, in: 100...500, step: 25)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Trump Multipliers Section
                    SettingsSection(title: "Trump Multipliers") {
                        VStack(spacing: 12) {
                            SettingsRow(title: "Four Aces Multiplier", value: "\(gameRules.trumpFourAcesMultiplier)x") {
                                Stepper("", value: $gameRules.trumpFourAcesMultiplier, in: 1...5)
                            }
                            
                            SettingsRow(title: "Four Kings Multiplier", value: "\(gameRules.trumpFourKingsMultiplier)x") {
                                Stepper("", value: $gameRules.trumpFourKingsMultiplier, in: 1...5)
                            }
                            
                            SettingsRow(title: "Four Queens Multiplier", value: "\(gameRules.trumpFourQueensMultiplier)x") {
                                Stepper("", value: $gameRules.trumpFourQueensMultiplier, in: 1...5)
                            }
                            
                            SettingsRow(title: "Four Jacks Multiplier", value: "\(gameRules.trumpFourJacksMultiplier)x") {
                                Stepper("", value: $gameRules.trumpFourJacksMultiplier, in: 1...5)
                            }
                            
                            SettingsRow(title: "Sequence Multiplier", value: "\(gameRules.trumpSequenceMultiplier)x") {
                                Stepper("", value: $gameRules.trumpSequenceMultiplier, in: 1...5)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Brisques Section
                    SettingsSection(title: "Brisques") {
                        VStack(spacing: 12) {
                            SettingsRow(title: "Brisque Value", value: "\(gameRules.brisqueValue)") {
                                Stepper("", value: $gameRules.brisqueValue, in: 1...100)
                            }
                            
                            SettingsRow(title: "Minimum Brisques", value: "\(gameRules.minBrisques)") {
                                Stepper("", value: $gameRules.minBrisques, in: 1...20)
                            }
                            
                            SettingsRow(title: "Brisque Cutoff Score", value: "\(gameRules.brisqueCutoff)") {
                                Stepper("", value: $gameRules.brisqueCutoff, in: 100...2000, step: 10)
                            }
                            
                            SettingsRow(title: "Min Score for Brisques", value: "\(gameRules.minScoreForBrisques)") {
                                Stepper("", value: $gameRules.minScoreForBrisques, in: 0...2000, step: 10)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Penalties Section
                    SettingsSection(title: "Penalties") {
                        VStack(spacing: 12) {
                            SettingsRow(title: "General Penalty", value: "\(gameRules.penalty)") {
                                Stepper("", value: $gameRules.penalty, in: -100...0, step: 1)
                            }
                            
                            SettingsRow(title: "Penalty Below 100", value: "\(gameRules.penaltyBelow100)") {
                                Stepper("", value: $gameRules.penaltyBelow100, in: -100...0, step: 1)
                            }
                            
                            SettingsRow(title: "Penalty Few Brisques", value: "\(gameRules.penaltyFewBrisques)") {
                                Stepper("", value: $gameRules.penaltyFewBrisques, in: -100...0, step: 1)
                            }
                            
                            SettingsRow(title: "Penalty Out of Turn", value: "\(gameRules.penaltyOutOfTurn)") {
                                Stepper("", value: $gameRules.penaltyOutOfTurn, in: -100...0, step: 1)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Global Card Size Section
                    SettingsSection(title: "Global Card Size") {
                        Picker("Card Size", selection: $gameRules.globalCardSize) {
                            Text("Small (1.5x)").tag(CardSizeMultiplier.small)
                            Text("Medium (2x)").tag(CardSizeMultiplier.medium)
                            Text("Large (2.5x)").tag(CardSizeMultiplier.large)
                            Text("Extra Large (3x)").tag(CardSizeMultiplier.extraLarge)
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(.horizontal)
                    }
                    
                    // Animation Timing Section
                    SettingsSection(title: "Animation Timing") {
                        VStack(spacing: 12) {
                            Picker("Card Play Delay", selection: $gameRules.cardPlayDelay) {
                                Text("Fast (0.3s)").tag(AnimationTiming.fast)
                                Text("Normal (0.5s)").tag(AnimationTiming.normal)
                                Text("Slow (0.8s)").tag(AnimationTiming.slow)
                            }
                            .pickerStyle(MenuPickerStyle())
                            
                            Picker("Card Play Duration", selection: $gameRules.cardPlayDuration) {
                                Text("Fast (0.3s)").tag(AnimationTiming.fast)
                                Text("Normal (0.5s)").tag(AnimationTiming.normal)
                                Text("Slow (0.8s)").tag(AnimationTiming.slow)
                            }
                            .pickerStyle(MenuPickerStyle())
                            
                            SettingsRow(title: "Dealer Determination Delay", value: String(format: "%.1fs", gameRules.dealerDeterminationDelay)) {
                                Stepper("", value: $gameRules.dealerDeterminationDelay, in: 1.0...5.0, step: 0.5)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Start Game Button
                    VStack {
                        Button("Start Game") {
                            showingStartGame = true
                        }
                        .buttonStyle(.borderedProminent)
                        .font(.headline)
                        .padding()
                    }
                    .padding(.top, 20)
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .clipped() // Add this to ensure proper clipping
        }
        .alert("Start New Game", isPresented: $showingStartGame) {
            Button("Start") {
                onSave()
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Start a new game with these settings?")
        }
    }
} 