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
        case critical(Content, BannerAction)
        case warning(Content, BannerAction)
        case promo(TextOnly, BannerAction, CloseAction, Effect)
        case survey(TextOnly, BannerAction, CloseAction)
        case informational(TextOnly, BannerAction, CloseAction)

        var content: Content {
            switch self {
            case .status(let c), .critical(let c, _), .warning(let c, _): c
            case .promo(let text, _, _, _), .survey(let text, _, _), .informational(let text, _, _): .text(text)
            }
        }

        var bannerAction: BannerAction {
            switch self {
            case .status: .buttons(.none)
            case .critical(_, let a), .warning(_, let a),
                 .promo(_, let a, _, _), .survey(_, let a, _), .informational(_, let a, _): a
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

        public var iconSize: CGSize {
            switch self {
            case .text: return .zero
            case .textWithIcon(let textWithIcon):
                return CGSize(
                    width: textWithIcon.icon.width.value,
                    height: textWithIcon.icon.height.value
                )
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
        public let renderingMode: Image.TemplateRenderingMode?
        public let width: SizeUnit
        public let height: SizeUnit

        public init(
            imageType: ImageType,
            alignment: Alignment = .top,
            width: SizeUnit = .x7,
            height: SizeUnit = .x7,
            renderingMode: Image.TemplateRenderingMode? = nil
        ) {
            self.imageType = imageType
            self.renderingMode = renderingMode
            self.alignment = alignment
            self.width = width
            self.height = height
        }
    }
}

extension NotificationBanner.Icon.Alignment {
    var verticalAlignment: SwiftUI.VerticalAlignment {
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

    enum BannerAction: Equatable, Sendable {
        case buttons(Buttons)
        case tappable(Action)
    }

    struct Action: Equatable, Sendable {
        let action: @Sendable () -> Void

        public init(_ action: @escaping @Sendable () -> Void) {
            self.action = action
        }

        func callAsFunction() { action() }

        public static func == (lhs: Self, rhs: Self) -> Bool { true }
    }

    typealias CloseAction = Action
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
