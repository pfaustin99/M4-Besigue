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