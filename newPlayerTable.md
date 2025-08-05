
# 🃏 New PlayerTable Layout Integration (for Cursor)

This guide explains how to integrate the new `PlayerTable`-based player layout system into the `GameBoard2` UI architecture in Cursor.

---

## 🎯 Objective

Replace old player rendering logic with a unified `PlayerTable` system that:
- Rotates player views inward toward the center of the table
- Supports floating, upright player name labels
- Automatically adjusts layout for 2, 3, or 4 players

---

## 📁 Required Files

Ensure these files are added to your project:

| File                         | Folder         |
|------------------------------|----------------|
| `PlayerTable.swift`          | `Components/`  |
| `GamePlayersCircleView.swift`| `Components/`  |
| `GamePlayerComponents.swift` | `Components/`  |
| `MeldRowView.swift`          | `Components/`  |

---

## 🧩 Step-by-Step Instructions

### 1. Replace Content in `GamePlayersCircleView.swift`

Ensure the view body looks like this:

```swift
ZStack {
    ForEach(Array(zip(game.players.indices, tablePositions)), id: \.0) { (index, position) in
        let player = game.players[index]
        PlayerTable(
            player: player,
            position: position,
            isCurrentTurn: player.isCurrentPlayer,
            isHumanPlayer: index == 0
        )
        .frame(width: geometry.size.width, height: geometry.size.height)
        .position(anchorPoint(for: position, in: geometry.size))
    }
}
```

And define this function:

```swift
private func anchorPoint(for position: TablePosition, in size: CGSize) -> CGPoint {
    switch position {
    case .bottom: return CGPoint(x: size.width / 2, y: size.height * 0.95)
    case .top:    return CGPoint(x: size.width / 2, y: size.height * 0.05)
    case .left:   return CGPoint(x: size.width * 0.05, y: size.height / 2)
    case .right:  return CGPoint(x: size.width * 0.95, y: size.height / 2)
    }
}
```

---

### 2. Confirm Usage in `GameBoardContentView.swift`

Ensure this line exists in the layout stack:

```swift
GameBoardCenterSection(game: game, viewState: viewState, settings: settings)
```

This ensures the center section will render the new `GamePlayersCircleView`.

---

### 3. Clean & Rebuild

In Cursor or Xcode:
- Use `⇧ + ⌘ + K` to clean the build
- Restart preview or rebuild if the UI seems unchanged

---

### 4. Optional Debug Aid

To confirm layout is rendering:
Open `PlayerTable.swift` and add:

```swift
.background(Color.red.opacity(0.2))
```

This will show a red-tinted zone where each player table is rendered.

---

## ✅ Result

You should see:
- Player zones correctly placed at bottom, right, top, and left
- Player names always upright
- Cards facing inward toward the center
- Meld placeholder visible or “No Melds” text

---
