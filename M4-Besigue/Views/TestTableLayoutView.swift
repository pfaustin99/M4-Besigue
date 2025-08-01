import SwiftUI

struct TestTableLayoutView: View {
    @State private var playerCount: Int = 4
    @State private var showSquareBoundaries: Bool = true

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Rectangle()
                    .fill(Color.purple.opacity(0.4))
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 0) {
                    ScoreboardAndControlsView(playerCount: $playerCount, showSquareBoundaries: $showSquareBoundaries)

                    ZStack {
                        RoundedRectangle(cornerRadius: 40)
                            .fill(Color.green.opacity(0.2))
                            .stroke(Color.green, lineWidth: 4)
                            .padding(40)

                        if showSquareBoundaries {
                            ForEach([0.85, 0.65, 0.45, 0.25], id: \.self) { size in
                                Rectangle()
                                    .stroke(getColor(for: size), lineWidth: 3)
                                    .frame(width: min(geometry.size.width, geometry.size.height) * size,
                                           height: min(geometry.size.width, geometry.size.height) * size)
                            }
                        }

                        concentricSquaresContent(playerCount: playerCount, geometry: geometry)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .preferredColorScheme(.light)
        .statusBarHidden()
    }

    private func getColor(for size: CGFloat) -> Color {
        switch size {
        case 0.85: return .red
        case 0.65: return .blue
        case 0.45: return .orange
        case 0.25: return .green
        default: return .clear
        }
    }

    private func concentricSquaresContent(playerCount: Int, geometry: GeometryProxy) -> some View {
        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        return ZStack {
            ForEach(0..<playerCount, id: \.self) { index in
                let pos = getPlayerPosition(index: index, playerCount: playerCount, center: center, geometry: geometry)

                Group {
                    playerNameView(for: index, at: pos.avatarPosition)
                    playerHandView(for: index, at: pos.handPosition, isHorizontal: pos.isHorizontal)
                    if index != 0 {
                        playerMeldView(for: index, at: pos.meldPosition, isHorizontal: pos.isHorizontal)
                    }
                }
            }

            VStack(spacing: 4) {
                Text("TRICK AREA")
                    .font(.caption).bold()
                    .foregroundColor(.green)
                Text("Cards played here")
                    .font(.caption2)
                    .foregroundColor(.green)
            }
            .frame(width: 100)
            .fixedSize()
            .position(x: center.x, y: center.y)
        }
    }

    private func playerNameView(for index: Int, at position: CGPoint) -> some View {
        Text("Player \(index + 1)")
            .font(.caption.bold())
            .foregroundColor(.white)
            .padding(6)
            .background(Color.red)
            .cornerRadius(6)
            .position(position)
    }

    private func playerHandView(for index: Int, at position: CGPoint, isHorizontal: Bool) -> some View {
        Group {
            if isHorizontal {
                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 6)
                            .fill(index == 0 ? Color.white : Color.blue)
                            .frame(width: 30, height: 42)
                    }
                }
            } else {
                VStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.blue)
                            .frame(width: 30, height: 42)
                    }
                }
            }
        }
        .position(position)
    }

    private func playerMeldView(for index: Int, at position: CGPoint, isHorizontal: Bool) -> some View {
        Group {
            if isHorizontal {
                HStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.orange)
                            .frame(width: 25, height: 35)
                    }
                }
            } else {
                VStack(spacing: 4) {
                    ForEach(0..<3, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.orange)
                            .frame(width: 25, height: 35)
                    }
                }
            }
        }
        .position(position)
    }

    private func getPlayerPosition(index: Int, playerCount: Int, center: CGPoint, geometry: GeometryProxy) -> (avatarPosition: CGPoint, handPosition: CGPoint, meldPosition: CGPoint, isHorizontal: Bool) {
        let minSide = min(geometry.size.width, geometry.size.height)
        let radiusFactors: [CGFloat] = [0.85, 0.65, 0.45]

        // Define direction vectors for bottom, right, top, left
        let directions: [(dx: CGFloat, dy: CGFloat, isHorizontal: Bool)] = [
            (0, 1, true),    // bottom
            (1, 0, false),   // right
            (0, -1, true),   // top
            (-1, 0, false)   // left
        ]

        let playerOrder: [Int]
        switch playerCount {
        case 2: playerOrder = [0, 2]  // bottom, top
        case 3: playerOrder = [0, 2, 1]  // bottom, top, right
        case 4: playerOrder = [0, 2, 1, 3]  // bottom, top, right, left
        default: playerOrder = []
        }

        let posIndex = playerOrder[index]
        let direction = directions[posIndex]

        func positionOnAxis(radiusFactor: CGFloat) -> CGPoint {
            let radius = minSide * radiusFactor / 2
            return CGPoint(
                x: center.x + direction.dx * radius,
                y: center.y + direction.dy * radius
            )
        }

        return (
            avatarPosition: positionOnAxis(radiusFactor: radiusFactors[0]),
            handPosition: positionOnAxis(radiusFactor: radiusFactors[1]),
            meldPosition: positionOnAxis(radiusFactor: radiusFactors[2]),
            isHorizontal: direction.isHorizontal
        )
    }
}

struct ScoreboardAndControlsView: View {
    @Binding var playerCount: Int
    @Binding var showSquareBoundaries: Bool

    var body: some View {
        VStack(spacing: 8) {
            Text("FIXED POSITIONING - \(playerCount) Players")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.purple)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: playerCount), spacing: 10) {
                ForEach(0..<playerCount, id: \.self) { index in
                    VStack(spacing: 4) {
                        Text("Player \(index + 1)")
                            .font(.caption)
                            .fontWeight(.medium)

                        HStack(spacing: 8) {
                            Text("Score: 0")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.yellow.opacity(0.8))
                                .cornerRadius(4)

                            Text("Brisques: 0")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.8))
                                .cornerRadius(4)
                        }
                    }
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)

            HStack(spacing: 12) {
                ForEach([2, 3, 4], id: \.self) { count in
                    Button("\(count) Players") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            playerCount = count
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .opacity(playerCount == count ? 0.6 : 1.0)
                }
            }

            Toggle("Show Square Boundaries", isOn: $showSquareBoundaries)
                .padding(.horizontal)
                .toggleStyle(.button)
                .buttonStyle(.bordered)
        }
        .padding()
        .background(Color.white.opacity(0.95))
        .shadow(radius: 2)
    }
}

#Preview {
    TestTableLayoutView()
}
