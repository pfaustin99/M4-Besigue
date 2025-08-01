import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

    /// The "card_back" asset catalog image resource.
    static let cardBack = DeveloperToolsSupport.ImageResource(name: "card_back", bundle: resourceBundle)

    /// The "clubs_10" asset catalog image resource.
    static let clubs10 = DeveloperToolsSupport.ImageResource(name: "clubs_10", bundle: resourceBundle)

    /// The "clubs_7" asset catalog image resource.
    static let clubs7 = DeveloperToolsSupport.ImageResource(name: "clubs_7", bundle: resourceBundle)

    /// The "clubs_8" asset catalog image resource.
    static let clubs8 = DeveloperToolsSupport.ImageResource(name: "clubs_8", bundle: resourceBundle)

    /// The "clubs_9" asset catalog image resource.
    static let clubs9 = DeveloperToolsSupport.ImageResource(name: "clubs_9", bundle: resourceBundle)

    /// The "clubs_ace" asset catalog image resource.
    static let clubsAce = DeveloperToolsSupport.ImageResource(name: "clubs_ace", bundle: resourceBundle)

    /// The "clubs_jack" asset catalog image resource.
    static let clubsJack = DeveloperToolsSupport.ImageResource(name: "clubs_jack", bundle: resourceBundle)

    /// The "clubs_king" asset catalog image resource.
    static let clubsKing = DeveloperToolsSupport.ImageResource(name: "clubs_king", bundle: resourceBundle)

    /// The "clubs_queen" asset catalog image resource.
    static let clubsQueen = DeveloperToolsSupport.ImageResource(name: "clubs_queen", bundle: resourceBundle)

    /// The "diamonds_10" asset catalog image resource.
    static let diamonds10 = DeveloperToolsSupport.ImageResource(name: "diamonds_10", bundle: resourceBundle)

    /// The "diamonds_7" asset catalog image resource.
    static let diamonds7 = DeveloperToolsSupport.ImageResource(name: "diamonds_7", bundle: resourceBundle)

    /// The "diamonds_8" asset catalog image resource.
    static let diamonds8 = DeveloperToolsSupport.ImageResource(name: "diamonds_8", bundle: resourceBundle)

    /// The "diamonds_9" asset catalog image resource.
    static let diamonds9 = DeveloperToolsSupport.ImageResource(name: "diamonds_9", bundle: resourceBundle)

    /// The "diamonds_ace" asset catalog image resource.
    static let diamondsAce = DeveloperToolsSupport.ImageResource(name: "diamonds_ace", bundle: resourceBundle)

    /// The "diamonds_jack" asset catalog image resource.
    static let diamondsJack = DeveloperToolsSupport.ImageResource(name: "diamonds_jack", bundle: resourceBundle)

    /// The "diamonds_king" asset catalog image resource.
    static let diamondsKing = DeveloperToolsSupport.ImageResource(name: "diamonds_king", bundle: resourceBundle)

    /// The "diamonds_queen" asset catalog image resource.
    static let diamondsQueen = DeveloperToolsSupport.ImageResource(name: "diamonds_queen", bundle: resourceBundle)

    /// The "hearts_10" asset catalog image resource.
    static let hearts10 = DeveloperToolsSupport.ImageResource(name: "hearts_10", bundle: resourceBundle)

    /// The "hearts_7" asset catalog image resource.
    static let hearts7 = DeveloperToolsSupport.ImageResource(name: "hearts_7", bundle: resourceBundle)

    /// The "hearts_8" asset catalog image resource.
    static let hearts8 = DeveloperToolsSupport.ImageResource(name: "hearts_8", bundle: resourceBundle)

    /// The "hearts_9" asset catalog image resource.
    static let hearts9 = DeveloperToolsSupport.ImageResource(name: "hearts_9", bundle: resourceBundle)

    /// The "hearts_ace" asset catalog image resource.
    static let heartsAce = DeveloperToolsSupport.ImageResource(name: "hearts_ace", bundle: resourceBundle)

    /// The "hearts_jack" asset catalog image resource.
    static let heartsJack = DeveloperToolsSupport.ImageResource(name: "hearts_jack", bundle: resourceBundle)

    /// The "hearts_king" asset catalog image resource.
    static let heartsKing = DeveloperToolsSupport.ImageResource(name: "hearts_king", bundle: resourceBundle)

    /// The "hearts_queen" asset catalog image resource.
    static let heartsQueen = DeveloperToolsSupport.ImageResource(name: "hearts_queen", bundle: resourceBundle)

    /// The "joker_black_1" asset catalog image resource.
    static let jokerBlack1 = DeveloperToolsSupport.ImageResource(name: "joker_black_1", bundle: resourceBundle)

    /// The "joker_black_2" asset catalog image resource.
    static let jokerBlack2 = DeveloperToolsSupport.ImageResource(name: "joker_black_2", bundle: resourceBundle)

    /// The "joker_red_1" asset catalog image resource.
    static let jokerRed1 = DeveloperToolsSupport.ImageResource(name: "joker_red_1", bundle: resourceBundle)

    /// The "joker_red_2" asset catalog image resource.
    static let jokerRed2 = DeveloperToolsSupport.ImageResource(name: "joker_red_2", bundle: resourceBundle)

    /// The "spades_10" asset catalog image resource.
    static let spades10 = DeveloperToolsSupport.ImageResource(name: "spades_10", bundle: resourceBundle)

    /// The "spades_7" asset catalog image resource.
    static let spades7 = DeveloperToolsSupport.ImageResource(name: "spades_7", bundle: resourceBundle)

    /// The "spades_8" asset catalog image resource.
    static let spades8 = DeveloperToolsSupport.ImageResource(name: "spades_8", bundle: resourceBundle)

    /// The "spades_9" asset catalog image resource.
    static let spades9 = DeveloperToolsSupport.ImageResource(name: "spades_9", bundle: resourceBundle)

    /// The "spades_ace" asset catalog image resource.
    static let spadesAce = DeveloperToolsSupport.ImageResource(name: "spades_ace", bundle: resourceBundle)

    /// The "spades_jack" asset catalog image resource.
    static let spadesJack = DeveloperToolsSupport.ImageResource(name: "spades_jack", bundle: resourceBundle)

    /// The "spades_king" asset catalog image resource.
    static let spadesKing = DeveloperToolsSupport.ImageResource(name: "spades_king", bundle: resourceBundle)

    /// The "spades_queen" asset catalog image resource.
    static let spadesQueen = DeveloperToolsSupport.ImageResource(name: "spades_queen", bundle: resourceBundle)

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    /// The "card_back" asset catalog image.
    static var cardBack: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .cardBack)
#else
        .init()
#endif
    }

    /// The "clubs_10" asset catalog image.
    static var clubs10: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .clubs10)
#else
        .init()
#endif
    }

    /// The "clubs_7" asset catalog image.
    static var clubs7: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .clubs7)
#else
        .init()
#endif
    }

    /// The "clubs_8" asset catalog image.
    static var clubs8: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .clubs8)
#else
        .init()
#endif
    }

    /// The "clubs_9" asset catalog image.
    static var clubs9: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .clubs9)
#else
        .init()
#endif
    }

    /// The "clubs_ace" asset catalog image.
    static var clubsAce: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .clubsAce)
#else
        .init()
#endif
    }

    /// The "clubs_jack" asset catalog image.
    static var clubsJack: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .clubsJack)
#else
        .init()
#endif
    }

    /// The "clubs_king" asset catalog image.
    static var clubsKing: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .clubsKing)
#else
        .init()
#endif
    }

    /// The "clubs_queen" asset catalog image.
    static var clubsQueen: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .clubsQueen)
#else
        .init()
#endif
    }

    /// The "diamonds_10" asset catalog image.
    static var diamonds10: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .diamonds10)
#else
        .init()
#endif
    }

    /// The "diamonds_7" asset catalog image.
    static var diamonds7: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .diamonds7)
#else
        .init()
#endif
    }

    /// The "diamonds_8" asset catalog image.
    static var diamonds8: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .diamonds8)
#else
        .init()
#endif
    }

    /// The "diamonds_9" asset catalog image.
    static var diamonds9: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .diamonds9)
#else
        .init()
#endif
    }

    /// The "diamonds_ace" asset catalog image.
    static var diamondsAce: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .diamondsAce)
#else
        .init()
#endif
    }

    /// The "diamonds_jack" asset catalog image.
    static var diamondsJack: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .diamondsJack)
#else
        .init()
#endif
    }

    /// The "diamonds_king" asset catalog image.
    static var diamondsKing: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .diamondsKing)
#else
        .init()
#endif
    }

    /// The "diamonds_queen" asset catalog image.
    static var diamondsQueen: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .diamondsQueen)
#else
        .init()
#endif
    }

    /// The "hearts_10" asset catalog image.
    static var hearts10: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .hearts10)
#else
        .init()
#endif
    }

    /// The "hearts_7" asset catalog image.
    static var hearts7: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .hearts7)
#else
        .init()
#endif
    }

    /// The "hearts_8" asset catalog image.
    static var hearts8: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .hearts8)
#else
        .init()
#endif
    }

    /// The "hearts_9" asset catalog image.
    static var hearts9: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .hearts9)
#else
        .init()
#endif
    }

    /// The "hearts_ace" asset catalog image.
    static var heartsAce: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .heartsAce)
#else
        .init()
#endif
    }

    /// The "hearts_jack" asset catalog image.
    static var heartsJack: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .heartsJack)
#else
        .init()
#endif
    }

    /// The "hearts_king" asset catalog image.
    static var heartsKing: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .heartsKing)
#else
        .init()
#endif
    }

    /// The "hearts_queen" asset catalog image.
    static var heartsQueen: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .heartsQueen)
#else
        .init()
#endif
    }

    /// The "joker_black_1" asset catalog image.
    static var jokerBlack1: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .jokerBlack1)
#else
        .init()
#endif
    }

    /// The "joker_black_2" asset catalog image.
    static var jokerBlack2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .jokerBlack2)
#else
        .init()
#endif
    }

    /// The "joker_red_1" asset catalog image.
    static var jokerRed1: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .jokerRed1)
#else
        .init()
#endif
    }

    /// The "joker_red_2" asset catalog image.
    static var jokerRed2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .jokerRed2)
#else
        .init()
#endif
    }

    /// The "spades_10" asset catalog image.
    static var spades10: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .spades10)
#else
        .init()
#endif
    }

    /// The "spades_7" asset catalog image.
    static var spades7: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .spades7)
#else
        .init()
#endif
    }

    /// The "spades_8" asset catalog image.
    static var spades8: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .spades8)
#else
        .init()
#endif
    }

    /// The "spades_9" asset catalog image.
    static var spades9: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .spades9)
#else
        .init()
#endif
    }

    /// The "spades_ace" asset catalog image.
    static var spadesAce: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .spadesAce)
#else
        .init()
#endif
    }

    /// The "spades_jack" asset catalog image.
    static var spadesJack: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .spadesJack)
#else
        .init()
#endif
    }

    /// The "spades_king" asset catalog image.
    static var spadesKing: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .spadesKing)
#else
        .init()
#endif
    }

    /// The "spades_queen" asset catalog image.
    static var spadesQueen: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .spadesQueen)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// The "card_back" asset catalog image.
    static var cardBack: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .cardBack)
#else
        .init()
#endif
    }

    /// The "clubs_10" asset catalog image.
    static var clubs10: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .clubs10)
#else
        .init()
#endif
    }

    /// The "clubs_7" asset catalog image.
    static var clubs7: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .clubs7)
#else
        .init()
#endif
    }

    /// The "clubs_8" asset catalog image.
    static var clubs8: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .clubs8)
#else
        .init()
#endif
    }

    /// The "clubs_9" asset catalog image.
    static var clubs9: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .clubs9)
#else
        .init()
#endif
    }

    /// The "clubs_ace" asset catalog image.
    static var clubsAce: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .clubsAce)
#else
        .init()
#endif
    }

    /// The "clubs_jack" asset catalog image.
    static var clubsJack: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .clubsJack)
#else
        .init()
#endif
    }

    /// The "clubs_king" asset catalog image.
    static var clubsKing: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .clubsKing)
#else
        .init()
#endif
    }

    /// The "clubs_queen" asset catalog image.
    static var clubsQueen: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .clubsQueen)
#else
        .init()
#endif
    }

    /// The "diamonds_10" asset catalog image.
    static var diamonds10: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .diamonds10)
#else
        .init()
#endif
    }

    /// The "diamonds_7" asset catalog image.
    static var diamonds7: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .diamonds7)
#else
        .init()
#endif
    }

    /// The "diamonds_8" asset catalog image.
    static var diamonds8: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .diamonds8)
#else
        .init()
#endif
    }

    /// The "diamonds_9" asset catalog image.
    static var diamonds9: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .diamonds9)
#else
        .init()
#endif
    }

    /// The "diamonds_ace" asset catalog image.
    static var diamondsAce: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .diamondsAce)
#else
        .init()
#endif
    }

    /// The "diamonds_jack" asset catalog image.
    static var diamondsJack: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .diamondsJack)
#else
        .init()
#endif
    }

    /// The "diamonds_king" asset catalog image.
    static var diamondsKing: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .diamondsKing)
#else
        .init()
#endif
    }

    /// The "diamonds_queen" asset catalog image.
    static var diamondsQueen: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .diamondsQueen)
#else
        .init()
#endif
    }

    /// The "hearts_10" asset catalog image.
    static var hearts10: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .hearts10)
#else
        .init()
#endif
    }

    /// The "hearts_7" asset catalog image.
    static var hearts7: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .hearts7)
#else
        .init()
#endif
    }

    /// The "hearts_8" asset catalog image.
    static var hearts8: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .hearts8)
#else
        .init()
#endif
    }

    /// The "hearts_9" asset catalog image.
    static var hearts9: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .hearts9)
#else
        .init()
#endif
    }

    /// The "hearts_ace" asset catalog image.
    static var heartsAce: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .heartsAce)
#else
        .init()
#endif
    }

    /// The "hearts_jack" asset catalog image.
    static var heartsJack: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .heartsJack)
#else
        .init()
#endif
    }

    /// The "hearts_king" asset catalog image.
    static var heartsKing: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .heartsKing)
#else
        .init()
#endif
    }

    /// The "hearts_queen" asset catalog image.
    static var heartsQueen: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .heartsQueen)
#else
        .init()
#endif
    }

    /// The "joker_black_1" asset catalog image.
    static var jokerBlack1: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .jokerBlack1)
#else
        .init()
#endif
    }

    /// The "joker_black_2" asset catalog image.
    static var jokerBlack2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .jokerBlack2)
#else
        .init()
#endif
    }

    /// The "joker_red_1" asset catalog image.
    static var jokerRed1: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .jokerRed1)
#else
        .init()
#endif
    }

    /// The "joker_red_2" asset catalog image.
    static var jokerRed2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .jokerRed2)
#else
        .init()
#endif
    }

    /// The "spades_10" asset catalog image.
    static var spades10: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .spades10)
#else
        .init()
#endif
    }

    /// The "spades_7" asset catalog image.
    static var spades7: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .spades7)
#else
        .init()
#endif
    }

    /// The "spades_8" asset catalog image.
    static var spades8: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .spades8)
#else
        .init()
#endif
    }

    /// The "spades_9" asset catalog image.
    static var spades9: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .spades9)
#else
        .init()
#endif
    }

    /// The "spades_ace" asset catalog image.
    static var spadesAce: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .spadesAce)
#else
        .init()
#endif
    }

    /// The "spades_jack" asset catalog image.
    static var spadesJack: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .spadesJack)
#else
        .init()
#endif
    }

    /// The "spades_king" asset catalog image.
    static var spadesKing: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .spadesKing)
#else
        .init()
#endif
    }

    /// The "spades_queen" asset catalog image.
    static var spadesQueen: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .spadesQueen)
#else
        .init()
#endif
    }

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

