//
//  Avatar+Properties.swift
//  TangemUI
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets

// MARK: - Public types

public extension Avatar {
    enum Size: CaseIterable, Hashable, Sendable {
        case size16
        case size40
        case size44
        case size72
    }

    enum Content {
        case icon(ImageType, appearance: IconAppearance = .neutral)
        case transaction(TransactionKind, status: TransactionStatus)
        case user(User)
        case address(Image?)
        case asset(Image)
        case account(ImageType, fill: Color)
    }

    enum User {
        case initial(String, fill: Color)
        case fallback
    }

    enum IconAppearance: CaseIterable, Hashable, Sendable {
        case neutral
        case success
        case error
        case warning
        case info
    }

    enum TransactionKind: CaseIterable, Hashable, Sendable {
        case send
        case receive
        case swap
        case topUp
        case staking
        case delivery
        case pack
    }

    enum TransactionStatus: CaseIterable, Hashable, Sendable {
        case progress
        case pending
        case finished
        case failed
    }
}

// MARK: - Content

extension Avatar.Content {
    var isAccount: Bool {
        if case .account = self { true } else { false }
    }

    var hasHighlight: Bool {
        switch self {
        case .user(.initial), .account: true
        case .icon, .transaction, .user(.fallback), .address, .asset: false
        }
    }
}

// MARK: - Sizes

extension Avatar.Size {
    var metrics: Avatar.Metrics {
        switch self {
        case .size16: Avatar.Metrics(side: 16, glyph: 12, accountCornerRadius: 4)
        case .size40: Avatar.Metrics(side: 40, glyph: 20, accountCornerRadius: 12)
        case .size44: Avatar.Metrics(side: 44, glyph: 20, accountCornerRadius: 12)
        case .size72: Avatar.Metrics(side: 72, glyph: 32, accountCornerRadius: 20)
        }
    }

    var initialFont: TangemTypographyToken {
        switch self {
        case .size16: DesignSystem.Font.captionMediumToken
        case .size40, .size44: DesignSystem.Font.bodyMediumToken
        case .size72: DesignSystem.Font.headingSmallToken
        }
    }

    var fallbackGlyph: ImageType {
        Avatar.Glyph(
            small: DesignSystem.Icons.User.regular12,
            medium: DesignSystem.Icons.User.regular20,
            large: DesignSystem.Icons.User.regular32
        )[self]
    }
}

// MARK: - Appearance

extension Avatar.IconAppearance {
    var background: Color {
        switch self {
        case .neutral: DesignSystem.Color.bgTransparentPrimary
        case .success: DesignSystem.Color.bgStatusSuccessSubtle
        case .error: DesignSystem.Color.bgStatusErrorSubtle
        case .warning: DesignSystem.Color.bgStatusWarningSubtle
        case .info: DesignSystem.Color.bgStatusInfoSubtle
        }
    }

    var tint: Color {
        switch self {
        case .neutral: DesignSystem.Color.iconSecondary
        case .success: DesignSystem.Color.iconStatusSuccess
        case .error: DesignSystem.Color.iconStatusError
        case .warning: DesignSystem.Color.iconStatusWarning
        case .info: DesignSystem.Color.iconStatusInfo
        }
    }
}

extension Avatar.TransactionStatus {
    var background: Color {
        switch self {
        case .progress: DesignSystem.Color.bgStatusInfoSubtle
        case .pending: DesignSystem.Color.bgStatusWarningSubtle
        case .finished: DesignSystem.Color.bgTransparentPrimary
        case .failed: DesignSystem.Color.bgStatusErrorSubtle
        }
    }

    var tint: Color {
        switch self {
        case .progress: DesignSystem.Color.iconStatusInfo
        case .pending: DesignSystem.Color.iconStatusWarning
        case .finished: DesignSystem.Color.iconSecondary
        case .failed: DesignSystem.Color.iconStatusError
        }
    }
}

extension Avatar.TransactionKind {
    func icon(for size: Avatar.Size) -> ImageType {
        glyph[size]
    }

    private var glyph: Avatar.Glyph {
        switch self {
        case .send:
            Avatar.Glyph(
                small: Icons.ArrowUp.regular12,
                medium: Icons.ArrowUp.regular20,
                large: Icons.ArrowUp.regular32
            )
        case .receive:
            Avatar.Glyph(
                small: Icons.ArrowDown.regular12,
                medium: Icons.ArrowDown.regular20,
                large: Icons.ArrowDown.regular32
            )
        case .swap:
            Avatar.Glyph(
                small: Icons.ArrowSwapHorizontal.regular12,
                medium: Icons.ArrowSwapHorizontal.regular20,
                large: Icons.ArrowSwapHorizontal.regular32
            )
        case .topUp:
            Avatar.Glyph(
                small: Icons.Card.regular12,
                medium: Icons.Card.regular20,
                large: Icons.Card.regular32
            )
        case .staking:
            Avatar.Glyph(
                small: Icons.Stack.regular12,
                medium: Icons.Stack.regular20,
                large: Icons.Stack.regular32
            )
        case .delivery:
            Avatar.Glyph(
                small: Icons.Box.regular12,
                medium: Icons.Box.regular20,
                large: Icons.Box.regular32
            )
        case .pack:
            Avatar.Glyph(
                small: Icons.CardsStar.regular12,
                medium: Icons.CardsStar.regular20,
                large: Icons.CardsStar.regular32
            )
        }
    }

    private typealias Icons = DesignSystem.Icons
}

// MARK: - Glyph

extension Avatar {
    struct Glyph {
        let small: ImageType
        let medium: ImageType
        let large: ImageType

        subscript(size: Avatar.Size) -> ImageType {
            switch size {
            case .size16: small
            case .size40, .size44: medium
            case .size72: large
            }
        }
    }
}

// MARK: - Metrics

extension Avatar {
    struct Metrics {
        static let highlightOpacity: Double = 0.2

        let side: CGFloat
        let glyph: CGFloat
        let accountCornerRadius: CGFloat

        func scaled(by factor: CGFloat) -> Metrics {
            Metrics(
                side: side * factor,
                glyph: glyph * factor,
                accountCornerRadius: accountCornerRadius * factor
            )
        }
    }
}
