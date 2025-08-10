import SwiftUI

/// BadgeLegendView2 - Clean badge legend view
struct BadgeLegendView2: View {
    @Environment(\.dismiss) private var dismiss
    let settings: GameSettings
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Meld Badge Legend")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.bottom, 8)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        BadgeLegendRow2(
                            icon: settings.badgeIcons.fourKingsIcon,
                            description: "Four Kings"
                        )
                        BadgeLegendRow2(
                            icon: settings.badgeIcons.fourQueensIcon,
                            description: "Four Queens"
                        )
                        BadgeLegendRow2(
                            icon: settings.badgeIcons.fourJacksIcon,
                            description: "Four Jacks"
                        )
                        BadgeLegendRow2(
                            icon: settings.badgeIcons.royalMarriageIcon,
                            description: "Royal Marriage"
                        )
                        BadgeLegendRow2(
                            icon: settings.badgeIcons.commonMarriageIcon,
                            description: "Marriage"
                        )
                        BadgeLegendRow2(
                            icon: settings.badgeIcons.besigueIcon,
                            description: "Bésigue"
                        )
                        BadgeLegendRow2(
                            icon: settings.badgeIcons.sequenceIcon,
                            description: "Sequence"
                        )
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Badge Legend")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// BadgeLegendRow2 - Individual badge legend row
struct BadgeLegendRow2: View {
    let icon: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.orange)
                .frame(width: 30)
            
            Text(description)
                .font(.body)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
} 