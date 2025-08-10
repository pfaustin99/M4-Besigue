import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: GameSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.audioManager) private var audioManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(spacing: 0) {
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
                    }
                    
                    // Audio Settings Section
                    SettingsSection(title: "Audio Settings") {
                        VStack(alignment: .leading, spacing: 16) {
                            // Background Music Toggle
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Background Music")
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    Text("Play ambient background music during gameplay")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { audioManager.isMusicEnabled },
                                    set: { _ in audioManager.toggleMusic() }
                                ))
                                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "00209F")))
                            }
                            
                            // Special Effects Toggle
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Special Effects")
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    Text("Play sound effects for game actions and melds")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { audioManager.isSoundEnabled },
                                    set: { _ in audioManager.toggleSound() }
                                ))
                                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "00209F")))
                            }
                            
                            // Dog Sounds Toggle
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Dog Sounds")
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    Text("Play dog sounds for last place player events")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Toggle("", isOn: Binding(
                                    get: { audioManager.isDogSoundsEnabled },
                                    set: { _ in audioManager.toggleDogSounds() }
                                ))
                                .toggleStyle(SwitchToggleStyle(tint: Color(hex: "F1B517")))
                            }
                        }
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