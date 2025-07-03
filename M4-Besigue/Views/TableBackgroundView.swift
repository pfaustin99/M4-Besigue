import SwiftUI

struct TableBackgroundView: View {
    var color: Color
    var body: some View {
        Rectangle()
            .fill(color)
            .edgesIgnoringSafeArea(.all)
    }
} 