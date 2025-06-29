import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: GameSettings
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 0) {
                    // Card Sizes Section
                    SettingsSection(title: "Card Sizes") {
                        VStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Trick Area Card Size")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Picker("Trick Area Card Size", selection: $settings.trickAreaCardSize) {
                                    Text("Small (1.5x)").tag(CardSizeMultiplier.small)
                                    Text("Medium (2x)").tag(CardSizeMultiplier.medium)
                                    Text("Large (2.5x)").tag(CardSizeMultiplier.large)
                                    Text("Extra Large (3x)").tag(CardSizeMultiplier.extraLarge)
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Player Hand Card Size")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Picker("Player Hand Card Size", selection: $settings.playerHandCardSize) {
                                    Text("Small (1.5x)").tag(CardSizeMultiplier.small)
                                    Text("Medium (2x)").tag(CardSizeMultiplier.medium)
                                    Text("Large (2.5x)").tag(CardSizeMultiplier.large)
                                    Text("Extra Large (3x)").tag(CardSizeMultiplier.extraLarge)
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // UI Configuration Section
                    SettingsSection(title: "UI Configuration") {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Draw Pile Position")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Picker("Draw Pile Position", selection: $settings.drawPilePosition) {
                                Text("Center Left").tag(DrawPilePosition.centerLeft)
                                Text("Center Right").tag(DrawPilePosition.centerRight)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 20)
            }
            .scrollIndicators(.visible)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
} 