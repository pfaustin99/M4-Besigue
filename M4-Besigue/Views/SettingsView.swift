import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: GameSettings
    @Environment(\.dismiss) private var dismiss
    
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