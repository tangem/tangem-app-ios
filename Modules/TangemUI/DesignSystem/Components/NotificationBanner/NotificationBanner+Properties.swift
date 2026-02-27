//
//  NotificationBanner+Properties.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

public extension NotificationBanner {
    enum BannerType: Equatable, Sendable {
        case status(Content)
        case critical(Content, Buttons)
        case warning(Content, Buttons)
        case promo(TextOnly, Buttons, CloseAction, Effect)
        case survey(TextOnly, Buttons, CloseAction)
        case informational(TextOnly, Buttons, CloseAction)

        var content: Content {
            switch self {
            case .status(let c), .critical(let c, _), .warning(let c, _): c
            case .promo(let text, _, _, _), .survey(let text, _, _), .informational(let text, _, _): .text(text)
            }
        }

        var buttons: Buttons {
            switch self {
            case .status: .none
            case .critical(_, let b), .warning(_, let b),
                 .promo(_, let b, _, _), .survey(_, let b, _), .informational(_, let b, _): b
            }
        }

        var closeAction: CloseAction? {
            switch self {
            case .status, .critical, .warning: nil
            case .promo(_, _, let a, _), .survey(_, _, let a), .informational(_, _, let a): a
            }
        }

        var effect: Effect {
            switch self {
            case .status, .survey, .informational: .none
            case .critical, .warning: .bannerWarning
            case .promo(_, _, _, let effect): effect
            }
        }

        var isClosable: Bool {
            isStackable
        }

        var isStackable: Bool {
            switch self {
            case .status, .critical, .warning: false
            case .promo, .survey, .informational: true
            }
        }
    }
}

public extension NotificationBanner {
    enum Content: Equatable, Sendable {
        case text(TextOnly)
        case textWithIcon(TextWithIcon)

        public var text: TextOnly {
            switch self {
            case .text(let textOnly): textOnly
            case .textWithIcon(let data): data.text
            }
        }

        public var iconSize: CGFloat {
            switch self {
            case .text: return .zero
            case .textWithIcon(let textWithIcon):
                return textWithIcon.icon.size.value
            }
        }
    }

    struct TextOnly: Equatable, Sendable {
        public let title: AttributedString
        public let subtitle: AttributedString

        public init(title: AttributedString, subtitle: AttributedString) {
            self.title = title
            self.subtitle = subtitle
        }
    }

    struct TextWithIcon: Equatable, Sendable {
        public let text: TextOnly
        public let icon: Icon

        public init(text: TextOnly, icon: Icon) {
            self.text = text
            self.icon = icon
        }
    }

    struct Icon: Equatable, Sendable {
        public enum Alignment: Equatable, Sendable {
            case top
            case center
            case bottom
        }

        public let imageType: ImageType
        public let alignment: Alignment
        public let size: SizeUnit

        public init(
            imageType: ImageType,
            alignment: Alignment = .top,
            size: SizeUnit = .x7
        ) {
            self.imageType = imageType
            self.alignment = alignment
            self.size = size
        }
    }
}

extension NotificationBanner.Icon.Alignment {
    var verticalAlignment: SwiftUI.Alignment {
        switch self {
        case .top: .top
        case .center: .center
        case .bottom: .bottom
        }
    }
}

public extension NotificationBanner {
    enum Buttons: Equatable, Sendable {
        case none
        case one(TangemButton.Model)
        case two(left: TangemButton.Model, right: TangemButton.Model)
    }

    struct CloseAction: Equatable, Sendable {
        let action: @Sendable () -> Void

        public init(_ action: @escaping @Sendable () -> Void) {
            self.action = action
        }

        func callAsFunction() { action() }

        public static func == (lhs: Self, rhs: Self) -> Bool { true }
    }
}

public extension NotificationBanner {
    typealias Effect = GlowBorderEffect
}

public extension NotificationBanner {
    enum Priority: Int, Comparable, Equatable, Sendable {
        case low = 0
        case high = 1

        public static func < (lhs: Priority, rhs: Priority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
}
