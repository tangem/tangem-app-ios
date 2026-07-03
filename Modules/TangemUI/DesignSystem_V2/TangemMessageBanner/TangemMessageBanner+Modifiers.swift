//
//  TangemMessageBanner+Modifiers.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

// MARK: - Public types

/// Visual appearance of a ``TangemMessageBanner`` — background color paired with a glow-ring palette.
public enum TangemMessageBannerVariant: Sendable, Hashable, CaseIterable {
    /// Neutral opaque background with the multi-color "magic" glow ring.
    case `default`
    /// Neutral tertiary (filled) background with the multi-color "magic" glow ring.
    case solid
    /// Subtle success-green background and matching glow ring.
    case success
    /// Subtle error-red background and matching glow ring.
    case error
    /// Subtle warning-yellow background and matching glow ring.
    case warning
    /// Subtle info-blue background and matching glow ring.
    case info
}

/// Horizontal alignment of the banner's text block.
public enum TangemMessageBannerContentAlign: Sendable, Hashable, CaseIterable {
    /// Leading layout: `slotStart · text · slotEnd`, text aligned to the leading edge.
    case start
    /// Centered layout: text is centered and reserves equal insets; slots float in the top corners.
    case center

    var textStackAlignment: HorizontalAlignment {
        switch self {
        case .start: .leading
        case .center: .center
        }
    }

    var textAlignment: TextAlignment {
        switch self {
        case .start: .leading
        case .center: .center
        }
    }
}

/// An action button rendered in the banner's button row.
public struct TangemMessageBannerButton {
    public let title: String
    public let action: () -> Void
    public var iconStart: ImageType?
    public var iconEnd: ImageType?
    public var isEnabled: Bool
    public var isLoading: Bool
    public var accessibilityLabel: String?

    public init(
        title: String,
        iconStart: ImageType? = nil,
        iconEnd: ImageType? = nil,
        isEnabled: Bool = true,
        isLoading: Bool = false,
        accessibilityLabel: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.iconStart = iconStart
        self.iconEnd = iconEnd
        self.isEnabled = isEnabled
        self.isLoading = isLoading
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }
}

struct TangemMessageBannerConfiguration {
    var variant: TangemMessageBannerVariant = .default
    var contentAlign: TangemMessageBannerContentAlign = .start
    var showsGlowRing: Bool = true
    var secondaryButton: TangemMessageBannerButton?
    var primaryButton: TangemMessageBannerButton?
    var accessibilityLabel: String?
}

public extension TangemMessageBanner {
    typealias Variant = TangemMessageBannerVariant
    typealias ContentAlign = TangemMessageBannerContentAlign
    typealias Button = TangemMessageBannerButton
}

// MARK: - Entry point

public extension TangemMessageBanner where
    SlotStart == EmptyView,
    SlotEnd == EmptyView,
    ExtraBottom == EmptyView {
    init(title: String, description: String? = nil) {
        self.init(
            title: title,
            description: description,
            slotStart: EmptyView(),
            slotEnd: EmptyView(),
            extraBottom: EmptyView()
        )
    }
}

// MARK: - Config modifiers (Setupable, same-type)

public extension TangemMessageBanner {
    func variant(_ variant: Variant) -> Self {
        map { $0.config.variant = variant }
    }

    func contentAlign(_ contentAlign: ContentAlign) -> Self {
        map { $0.config.contentAlign = contentAlign }
    }

    func showGlowRing(_ show: Bool = true) -> Self {
        map { $0.config.showsGlowRing = show }
    }

    func secondaryButton(_ button: Button?) -> Self {
        map { $0.config.secondaryButton = button }
    }

    func primaryButton(_ button: Button?) -> Self {
        map { $0.config.primaryButton = button }
    }

    func accessibilityLabel(_ label: String?) -> Self {
        map { $0.config.accessibilityLabel = label }
    }
}

// MARK: - Slot transforms (type-changing, no AnyView)

public extension TangemMessageBanner {
    func slotStart<V: View>(
        @ViewBuilder _ content: () -> V
    ) -> TangemMessageBanner<V, SlotEnd, ExtraBottom> {
        TangemMessageBanner<V, SlotEnd, ExtraBottom>(
            title: title,
            description: description,
            slotStart: content(),
            slotEnd: slotEndContent,
            extraBottom: extraBottomContent,
            config: config
        )
    }

    func slotEnd<V: View>(
        @ViewBuilder _ content: () -> V
    ) -> TangemMessageBanner<SlotStart, V, ExtraBottom> {
        TangemMessageBanner<SlotStart, V, ExtraBottom>(
            title: title,
            description: description,
            slotStart: slotStartContent,
            slotEnd: content(),
            extraBottom: extraBottomContent,
            config: config
        )
    }

    func extraBottom<V: View>(
        @ViewBuilder _ content: () -> V
    ) -> TangemMessageBanner<SlotStart, SlotEnd, V> {
        TangemMessageBanner<SlotStart, SlotEnd, V>(
            title: title,
            description: description,
            slotStart: slotStartContent,
            slotEnd: slotEndContent,
            extraBottom: content(),
            config: config
        )
    }
}

// MARK: - Close button convenience

public extension TangemMessageBanner {
    /// Places the standard dismiss affordance (a filled cross-circle) in the trailing slot.
    func closeButton(
        accessibilityLabel: String? = nil,
        action: @escaping () -> Void
    ) -> TangemMessageBanner<SlotStart, TangemMessageBannerCloseButton, ExtraBottom> {
        slotEnd {
            TangemMessageBannerCloseButton(accessibilityLabel: accessibilityLabel, action: action)
        }
    }
}

/// Dismiss button preset for ``TangemMessageBanner`` — a filled cross-circle sized for the trailing slot.
public struct TangemMessageBannerCloseButton: View {
    private let accessibilityLabel: String?
    private let action: () -> Void

    public init(accessibilityLabel: String? = nil, action: @escaping () -> Void) {
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    public var body: some View {
        SwiftUI.Button(action: action) {
            DesignSystem.Icons.CrossCircle.filled20.image
                .renderingMode(.template)
                .resizable()
                .frame(width: TangemMessageBannerMetrics.closeButtonSize, height: TangemMessageBannerMetrics.closeButtonSize)
                .foregroundStyle(DesignSystem.Color.iconSecondary)
        }
        .buttonStyle(.plain)
        .ifLet(accessibilityLabel) { view, label in
            view.accessibilityLabel(label)
        }
    }
}
