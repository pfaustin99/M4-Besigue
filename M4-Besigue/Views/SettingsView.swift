import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: GameSettings
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Game Level")) {
                    Picker("Game Level", selection: $settings.gameLevel) {
                        Text("Novice (Hints Enabled)").tag(GameLevel.novice)
                        Text("Pro (No Hints)").tag(GameLevel.pro)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Meld Points")) {
                    Stepper(value: $settings.besiguePoints, in: 10...200, step: 10) {
                        HStack {
                            Text("Bésigue")
                            Spacer()
                            Text("\(settings.besiguePoints)")
                        }
                    }
                    Stepper(value: $settings.royalMarriagePoints, in: 10...200, step: 10) {
                        HStack {
                            Text("Royal Marriage")
                            Spacer()
                            Text("\(settings.royalMarriagePoints)")
                        }
                    }
                    Stepper(value: $settings.commonMarriagePoints, in: 10...200, step: 10) {
                        HStack {
                            Text("Common Marriage")
                            Spacer()
                            Text("\(settings.commonMarriagePoints)")
                        }
                    }
                    Stepper(value: $settings.fourAcesPoints, in: 50...500, step: 10) {
                        HStack {
                            Text("Four Aces")
                            Spacer()
                            Text("\(settings.fourAcesPoints)")
                        }
                    }
                    Stepper(value: $settings.fourKingsPoints, in: 50...500, step: 10) {
                        HStack {
                            Text("Four Kings")
                            Spacer()
                            Text("\(settings.fourKingsPoints)")
                        }
                    }
                    Stepper(value: $settings.fourQueensPoints, in: 50...500, step: 10) {
                        HStack {
                            Text("Four Queens")
                            Spacer()
                            Text("\(settings.fourQueensPoints)")
                        }
                    }
                    Stepper(value: $settings.fourJacksPoints, in: 50...500, step: 10) {
                        HStack {
                            Text("Four Jacks")
                            Spacer()
                            Text("\(settings.fourJacksPoints)")
                        }
                    }
                    Stepper(value: $settings.fourJokersPoints, in: 100...1000, step: 50) {
                        HStack {
                            Text("Four Jokers")
                            Spacer()
                            Text("\(settings.fourJokersPoints)")
                        }
                    }
                    Stepper(value: $settings.sequencePoints, in: 100...1000, step: 50) {
                        HStack {
                            Text("Sequence")
                            Spacer()
                            Text("\(settings.sequencePoints)")
                        }
                    }
                }
                
                Section(header: Text("Trump Multipliers")) {
                    Stepper(value: $settings.trumpFourAcesMultiplier, in: 1...5) {
                        HStack {
                            Text("Trump Four Aces Multiplier")
                            Spacer()
                            Text("\(settings.trumpFourAcesMultiplier)x")
                        }
                    }
                    Stepper(value: $settings.trumpFourKingsMultiplier, in: 1...5) {
                        HStack {
                            Text("Trump Four Kings Multiplier")
                            Spacer()
                            Text("\(settings.trumpFourKingsMultiplier)x")
                        }
                    }
                    Stepper(value: $settings.trumpFourQueensMultiplier, in: 1...5) {
                        HStack {
                            Text("Trump Four Queens Multiplier")
                            Spacer()
                            Text("\(settings.trumpFourQueensMultiplier)x")
                        }
                    }
                    Stepper(value: $settings.trumpFourJacksMultiplier, in: 1...5) {
                        HStack {
                            Text("Trump Four Jacks Multiplier")
                            Spacer()
                            Text("\(settings.trumpFourJacksMultiplier)x")
                        }
                    }
                    Stepper(value: $settings.trumpSequenceMultiplier, in: 1...5) {
                        HStack {
                            Text("Trump Sequence Multiplier")
                            Spacer()
                            Text("\(settings.trumpSequenceMultiplier)x")
                        }
                    }
                }
                
                Section(header: Text("Brisques")) {
                    Stepper(value: $settings.minBrisques, in: 1...20) {
                        HStack {
                            Text("Minimum Brisques")
                            Spacer()
                            Text("\(settings.minBrisques)")
                        }
                    }
                    Stepper(value: $settings.brisqueValue, in: 1...100) {
                        HStack {
                            Text("Brisque Value")
                            Spacer()
                            Text("\(settings.brisqueValue)")
                        }
                    }
                    Stepper(value: $settings.brisqueCutoff, in: 100...2000, step: 10) {
                        HStack {
                            Text("Brisque Cutoff Score")
                            Spacer()
                            Text("\(settings.brisqueCutoff)")
                        }
                    }
                }
                
                Section(header: Text("Scoring")) {
                    Stepper(value: $settings.minScoreForBrisques, in: 0...2000, step: 10) {
                        HStack {
                            Text("Min Score for Brisques")
                            Spacer()
                            Text("\(settings.minScoreForBrisques)")
                        }
                    }
                    Stepper(value: $settings.penalty, in: -100...0, step: 1) {
                        HStack {
                            Text("Penalty (if requirements not met)")
                            Spacer()
                            Text("\(settings.penalty)")
                        }
                    }
                    Stepper(value: $settings.penaltyBelow100, in: -100...0, step: 1) {
                        HStack {
                            Text("Penalty Below 100")
                            Spacer()
                            Text("\(settings.penaltyBelow100)")
                        }
                    }
                    Stepper(value: $settings.penaltyFewBrisques, in: -100...0, step: 1) {
                        HStack {
                            Text("Penalty Few Brisques")
                            Spacer()
                            Text("\(settings.penaltyFewBrisques)")
                        }
                    }
                    Stepper(value: $settings.penaltyOutOfTurn, in: -100...0, step: 1) {
                        HStack {
                            Text("Penalty Out of Turn")
                            Spacer()
                            Text("\(settings.penaltyOutOfTurn)")
                        }
                    }
                }
                
                Section(header: Text("Winning Score")) {
                    Stepper(value: $settings.winningScore, in: 100...2000, step: 10) {
                        HStack {
                            Text("Winning Score")
                            Spacer()
                            Text("\(settings.winningScore)")
                        }
                    }
                    Stepper(value: $settings.finalTrickBonus, in: 0...100, step: 1) {
                        HStack {
                            Text("Final Trick Bonus")
                            Spacer()
                            Text("\(settings.finalTrickBonus)")
                        }
                    }
                    Stepper(value: $settings.trickWithSevenTrumpPoints, in: 0...100, step: 1) {
                        HStack {
                            Text("Trick with Seven Trump Points")
                            Spacer()
                            Text("\(settings.trickWithSevenTrumpPoints)")
                        }
                    }
                    Stepper(value: $settings.finalTrickPoints, in: 0...100, step: 1) {
                        HStack {
                            Text("Final Trick Points")
                            Spacer()
                            Text("\(settings.finalTrickPoints)")
                        }
                    }
                }
                
                Section(header: Text("Game Rules")) {
                    Picker("Play Direction", selection: $settings.playDirection) {
                        Text("Right (Counterclockwise)").tag(PlayDirection.right)
                        Text("Left (Clockwise)").tag(PlayDirection.left)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Stepper(value: $settings.handSize, in: 6...12) {
                        HStack {
                            Text("Hand Size")
                            Spacer()
                            Text("\(settings.handSize)")
                        }
                    }
                    
                    Stepper(value: $settings.playerCount, in: 2...4) {
                        HStack {
                            Text("Number of Players")
                            Spacer()
                            Text("\(settings.playerCount)")
                        }
                    }
                }
                
                Section(header: Text("UI Configuration")) {
                    Picker("Card Size", selection: $settings.cardSizeMultiplier) {
                        ForEach(CardSizeMultiplier.allCases, id: \.self) { size in
                            Text(size.displayName).tag(size)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Picker("Draw Pile Position", selection: $settings.drawPilePosition) {
                        ForEach(DrawPilePosition.allCases, id: \.self) { position in
                            Text(position.displayName).tag(position)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("Animation Settings")) {
                    Picker("Card Play Delay", selection: $settings.cardPlayDelay) {
                        ForEach(AnimationTiming.allCases, id: \.self) { timing in
                            Text(timing.displayName).tag(timing)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Picker("Animation Duration", selection: $settings.cardPlayDuration) {
                        ForEach(AnimationTiming.allCases, id: \.self) { timing in
                            Text(timing.displayName).tag(timing)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            .navigationTitle("Game Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
} 