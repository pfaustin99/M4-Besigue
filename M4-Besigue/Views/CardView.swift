import SwiftUI

struct CardView: View {
    let card: PlayerCard
    let isSelected: Bool
    let isPlayable: Bool
    let showHint: Bool
    let isDragTarget: Bool
    let onTap: () -> Void
    
    // Computed property to calculate card size based on screen width
    private var size: CGSize {
        let screenWidth = UIScreen.main.bounds.width
        let width = min(max(screenWidth * 0.12, 70), 120)
        let height = width * (112.0 / 80.0)
        return CGSize(width: width, height: height)
    }
    
    // Removed size parameter from initializer
    init(card: PlayerCard, isSelected: Bool = false, isPlayable: Bool = true, showHint: Bool = false, isDragTarget: Bool = false, onTap: @escaping () -> Void) {
        self.card = card
        self.isSelected = isSelected
        self.isPlayable = isPlayable
        self.showHint = showHint
        self.isDragTarget = isDragTarget
        self.onTap = onTap
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                Image(card.imageName)
                    .resizable()
                    .aspectRatio(2.5/3.5, contentMode: .fit)
                    .frame(width: size.width, height: size.height)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isSelected ? Color.blue : 
                                (isDragTarget ? Color.green : 
                                 (showHint ? Color.yellow : Color.clear)), 
                                lineWidth: isSelected ? 3 : (isDragTarget ? 4 : (showHint ? 4 : 0))
                            )
                    )
                    .scaleEffect(isSelected ? 1.1 : (isDragTarget ? 1.05 : 1.0))
                    .shadow(
                        color: isSelected ? .blue.opacity(0.5) : 
                               (isDragTarget ? .green.opacity(0.6) : .clear), 
                        radius: isSelected ? 8 : (isDragTarget ? 6 : 0)
                    )
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
                    .animation(.easeInOut(duration: 0.15), value: isDragTarget)
            }
        }
        .disabled(!isPlayable)
        .opacity(isPlayable ? 1.0 : 0.5)
    }
}

struct CardBackView: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Image("card_back")
                .resizable()
                .aspectRatio(2.5/3.5, contentMode: .fit)
                .frame(width: 80, height: 112)
                .background(Color.white)
                .cornerRadius(8)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
        }
    }
}

struct HandView: View {
    let cards: [PlayerCard]
    let playableCards: [PlayerCard]
    let selectedCards: [PlayerCard]
    let showHintFor: Set<UUID>
    let onCardTap: (PlayerCard) -> Void
    let onDoubleTap: (PlayerCard) -> Void
    let onReorder: (([PlayerCard]) -> Void)?
    let onDragEnd: () -> Void
    
    init(cards: [PlayerCard], playableCards: [PlayerCard], selectedCards: [PlayerCard], showHintFor: Set<UUID> = [], onCardTap: @escaping (PlayerCard) -> Void, onDoubleTap: @escaping (PlayerCard) -> Void, onReorder: (([PlayerCard]) -> Void)? = nil, onDragEnd: @escaping () -> Void = {}) {
        self.cards = cards
        self.playableCards = playableCards
        self.selectedCards = selectedCards
        self.showHintFor = showHintFor
        self.onCardTap = onCardTap
        self.onDoubleTap = onDoubleTap
        self.onReorder = onReorder
        self.onDragEnd = onDragEnd
    }
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: -24) {
                ForEach(cards) { card in
                    let isPlayable = playableCards.contains(card)
                    let isSelected = selectedCards.contains(card)
                    let showHint = showHintFor.contains(card.id)
                    CardView(
                        card: card,
                        isSelected: isSelected,
                        isPlayable: isPlayable,
                        showHint: showHint,
                        isDragTarget: false
                    ) {
                        onCardTap(card)
                    }
                    .onTapGesture(count: 2) {
                        onDoubleTap(card)
                    }
                    .onDrag {
                        // Create drag item with card ID
                        NSItemProvider(object: card.id.uuidString as NSString)
                    } preview: {
                        // Show a preview of the card being dragged
                        CardView(
                            card: card,
                            isSelected: false,
                            isPlayable: true,
                            showHint: false,
                            isDragTarget: false
                        ) {
                            // Empty action for preview
                        }
                        .scaleEffect(0.8)
                        .opacity(0.8)
                    }
                    .onDrop(of: [.text], delegate: CardDropDelegate(
                        card: card,
                        cards: cards,
                        onReorder: onReorder,
                        onDragEnd: onDragEnd
                    ))
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .shadow(color: isSelected ? .blue.opacity(0.5) : .clear, radius: isSelected ? 8 : 0)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
                    .padding(12)
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Card Drop Delegate for Drag and Drop
struct CardDropDelegate: DropDelegate {
    let card: PlayerCard
    let cards: [PlayerCard]
    let onReorder: (([PlayerCard]) -> Void)?
    let onDragEnd: () -> Void
    
    func performDrop(info: DropInfo) -> Bool {
        guard let onReorder = onReorder else { return false }
        
        // Get the dragged card ID
        guard let itemProvider = info.itemProviders(for: [.text]).first else { return false }
        
        itemProvider.loadObject(ofClass: NSString.self) { string, _ in
            guard let cardIdString = string as? String,
                  let draggedCardId = UUID(uuidString: cardIdString),
                  let draggedCard = cards.first(where: { $0.id == draggedCardId }),
                  let draggedIndex = cards.firstIndex(where: { $0.id == draggedCardId }),
                  let dropIndex = cards.firstIndex(where: { $0.id == card.id }) else { return }
            
            // Don't reorder if dropping on the same card
            guard draggedIndex != dropIndex else { return }
            
            DispatchQueue.main.async {
                // Create new order by moving the dragged card to the drop position
                var newOrder = cards
                newOrder.remove(at: draggedIndex)
                newOrder.insert(draggedCard, at: dropIndex)
                
                // Call the reorder callback
                onReorder(newOrder)
                
                // Call onDragEnd after a short delay to ensure the drop is complete
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    onDragEnd()
                }
            }
        }
        
        return true
    }
    
    func dropEntered(info: DropInfo) {
        // Visual feedback when dragging over a drop target
        // This will be handled by the view's state
    }
    
    func dropExited(info: DropInfo) {
        // Clear visual feedback when leaving drop target
        // This will be handled by the view's state
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        // Allow the drop
        return DropProposal(operation: .move)
    }
}

// MARK: - Enhanced Card Drop Delegate with Visual Feedback
struct EnhancedCardDropDelegate: DropDelegate {
    let card: PlayerCard
    let cards: [PlayerCard]
    let onReorder: (([PlayerCard]) -> Void)?
    let onDragEnter: (PlayerCard) -> Void
    let onDragExit: (PlayerCard) -> Void
    let onDragEnd: () -> Void
    
    func performDrop(info: DropInfo) -> Bool {
        guard let onReorder = onReorder else { return false }
        
        // Get the dragged card ID
        guard let itemProvider = info.itemProviders(for: [.text]).first else { return false }
        
        itemProvider.loadObject(ofClass: NSString.self) { string, _ in
            guard let cardIdString = string as? String,
                  let draggedCardId = UUID(uuidString: cardIdString),
                  let draggedCard = cards.first(where: { $0.id == draggedCardId }),
                  let draggedIndex = cards.firstIndex(where: { $0.id == draggedCardId }),
                  let dropIndex = cards.firstIndex(where: { $0.id == card.id }) else { return }
            
            // Don't reorder if dropping on the same card
            guard draggedIndex != dropIndex else { return }
            
            DispatchQueue.main.async {
                // Create new order by moving the dragged card to the drop position
                var newOrder = cards
                newOrder.remove(at: draggedIndex)
                newOrder.insert(draggedCard, at: dropIndex)
                
                // Call the reorder callback
                onReorder(newOrder)
                
                // Call onDragEnd after a short delay to ensure the drop is complete
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    onDragEnd()
                }
            }
        }
        
        return true
    }
    
    func dropEntered(info: DropInfo) {
        onDragEnter(card)
    }
    
    func dropExited(info: DropInfo) {
        onDragExit(card)
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        // Allow the drop
        return DropProposal(operation: .move)
    }
}

#Preview {
    VStack(spacing: 20) {
        CardView(
            card: PlayerCard(card: Card(suit: .hearts, value: .ace)),
            isSelected: true
        ) {
            print("Card tapped")
        }
        
        HandView(
            cards: [
                PlayerCard(card: Card(suit: .hearts, value: .ace)),
                PlayerCard(card: Card(suit: .diamonds, value: .king)),
                PlayerCard(card: Card(suit: .clubs, value: .queen))
            ],
            playableCards: [
                PlayerCard(card: Card(suit: .hearts, value: .ace)),
                PlayerCard(card: Card(suit: .diamonds, value: .king))
            ],
            selectedCards: [],
            showHintFor: [],
            onCardTap: { card in
                print("Card tapped: \(card.displayName)")
            },
            onDoubleTap: { card in
                print("Card double tapped: \(card.displayName)")
            },
            onDragEnd: {
                print("Drag ended")
            }
        )
    }
    .padding()
} 
