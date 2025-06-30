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
            
            // Content - Test with simplified components and more content
            ScrollView(showsIndicators: true) {
                VStack(spacing: 20) {
                    // Game Rules Section - Simplified
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Game Rules")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("Number of Players")
                                Spacer()
                                Text("\(gameRules.playerCount)")
                                Stepper("", value: $gameRules.playerCount, in: 2...4)
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
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Dealer Determination")
                                    .font(.headline)
                                    .padding(.horizontal)
                                Picker("Dealer Determination Method", selection: $gameRules.dealerDeterminationMethod) {
                                    ForEach(DealerDeterminationMethod.allCases) { method in
                                        Text(method.displayName).tag(method)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Scoring Section - Simplified
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Scoring")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("Winning Score")
                                Spacer()
                                Text("\(gameRules.winningScore)")
                                Stepper("", value: $gameRules.winningScore, in: 100...2000, step: 10)
                            }
                            
                            HStack {
                                Text("Final Trick Bonus")
                                Spacer()
                                Text("\(gameRules.finalTrickBonus)")
                                Stepper("", value: $gameRules.finalTrickBonus, in: 0...100, step: 1)
                            }
                            
                            HStack {
                                Text("Trick with Seven Trump")
                                Spacer()
                                Text("\(gameRules.trickWithSevenTrumpPoints)")
                                Stepper("", value: $gameRules.trickWithSevenTrumpPoints, in: 0...100, step: 1)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Brisques Section - Simplified
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Brisques")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("Brisque Value")
                                Spacer()
                                Text("\(gameRules.brisqueValue)")
                                Stepper("", value: $gameRules.brisqueValue, in: 1...100)
                            }
                            
                            HStack {
                                Text("Minimum Brisques")
                                Spacer()
                                Text("\(gameRules.minBrisques)")
                                Stepper("", value: $gameRules.minBrisques, in: 1...20)
                            }
                            
                            HStack {
                                Text("Brisque Cutoff Score")
                                Spacer()
                                Text("\(gameRules.brisqueCutoff)")
                                Stepper("", value: $gameRules.brisqueCutoff, in: 100...2000, step: 10)
                            }
                            
                            HStack {
                                Text("Min Score for Brisques")
                                Spacer()
                                Text("\(gameRules.minScoreForBrisques)")
                                Stepper("", value: $gameRules.minScoreForBrisques, in: 0...2000, step: 10)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Penalties Section - Simplified
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Penalties")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("General Penalty")
                                Spacer()
                                Text("\(gameRules.penalty)")
                                Stepper("", value: $gameRules.penalty, in: -100...0, step: 1)
                            }
                            
                            HStack {
                                Text("Penalty Below 100")
                                Spacer()
                                Text("\(gameRules.penaltyBelow100)")
                                Stepper("", value: $gameRules.penaltyBelow100, in: -100...0, step: 1)
                            }
                            
                            HStack {
                                Text("Penalty Few Brisques")
                                Spacer()
                                Text("\(gameRules.penaltyFewBrisques)")
                                Stepper("", value: $gameRules.penaltyFewBrisques, in: -100...0, step: 1)
                            }
                            
                            HStack {
                                Text("Penalty Out of Turn")
                                Spacer()
                                Text("\(gameRules.penaltyOutOfTurn)")
                                Stepper("", value: $gameRules.penaltyOutOfTurn, in: -100...0, step: 1)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Global Card Size Section - Simplified
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Global Card Size")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Picker("Card Size", selection: $gameRules.globalCardSize) {
                            Text("Small (1.5x)").tag(CardSizeMultiplier.small)
                            Text("Medium (2x)").tag(CardSizeMultiplier.medium)
                            Text("Large (2.5x)").tag(CardSizeMultiplier.large)
                            Text("Extra Large (3x)").tag(CardSizeMultiplier.extraLarge)
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Trick Area Size Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Trick Area Size")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Picker("Trick Area Size", selection: $gameRules.trickAreaSize) {
                            Text("Small").tag(TrickAreaSize.small)
                            Text("Medium").tag(TrickAreaSize.medium)
                            Text("Large").tag(TrickAreaSize.large)
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    
                    // Animation Timing Section - Simplified
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Animation Timing")
                            .font(.headline)
                            .padding(.horizontal)
                        
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
                            
                            HStack {
                                Text("Dealer Determination Delay")
                                Spacer()
                                Text(String(format: "%.1fs", gameRules.dealerDeterminationDelay))
                                Stepper("", value: $gameRules.dealerDeterminationDelay, in: 1.0...5.0, step: 0.5)
                            }
                            
                            HStack {
                                Text("Winning Card Animation Delay")
                                Spacer()
                                Text(String(format: "%.1fs", gameRules.winningCardAnimationDelay))
                                Stepper("", value: $gameRules.winningCardAnimationDelay, in: 0.5...3.0, step: 0.1)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
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
            .clipped()
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