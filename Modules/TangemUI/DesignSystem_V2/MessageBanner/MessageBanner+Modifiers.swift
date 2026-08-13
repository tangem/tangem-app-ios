//
//  MessageBanner+Modifiers.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

// MARK: - Public types

public enum MessageBannerVariant: Sendable, Hashable, CaseIterable {
    case `default`
    case solid
    case success
    case error
    case warning
    case info
}

public enum MessageBannerContentAlign: Sendable, Hashable, CaseIterable {
    case start
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

public struct MessageBannerButton {
    public let title: String
    public let action: () -> Void
    public var iconStart: ImageType?
    public var iconEnd: ImageType?
    public var isEnabled: Bool
    public var isLoading: Bool
    public var accessibilityLabel: String?
    public var accessibilityIdentifier: String?

    public init(
        title: String,
        iconStart: ImageType? = nil,
        iconEnd: ImageType? = nil,
        isEnabled: Bool = true,
        isLoading: Bool = false,
        accessibilityLabel: String? = nil,
        accessibilityIdentifier: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.iconStart = iconStart
        self.iconEnd = iconEnd
        self.isEnabled = isEnabled
        self.isLoading = isLoading
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityIdentifier = accessibilityIdentifier
        self.action = action
    }
}

struct MessageBannerConfiguration {
    var variant: MessageBannerVariant = .default
    var contentAlign: MessageBannerContentAlign = .start
    var glowRing: GlowRingAppearance?
    var titleLineLimit: Int?
    var descriptionLineLimit: Int?
    var secondaryButton: MessageBannerButton?
    var primaryButton: MessageBannerButton?
    var onTap: (() -> Void)?
    var accessibilityLabel: String?
}

public extension MessageBanner {
    typealias Variant = MessageBannerVariant
    typealias ContentAlign = MessageBannerContentAlign
    typealias Button = MessageBannerButton
}

// MARK: - Entry point

public extension MessageBanner where
    SlotStart == EmptyView,
    SlotEnd == EmptyView,
    ExtraBottom == EmptyView {
    init(title: String, description: String? = nil) {
        self.init(
            title: AttributedString(title),
            description: description.map { AttributedString($0) },
            slotStart: EmptyView(),
            slotEnd: EmptyView(),
            extraBottom: EmptyView()
        )
    }

    init(title: AttributedString, description: AttributedString? = nil) {
        self.init(
            title: title,
            description: description,
            slotStart: EmptyView(),
            slotEnd: EmptyView(),
            extraBottom: EmptyView()
        )
    }
}

// MARK: - Config modifiers

public extension MessageBanner {
    func variant(_ variant: Variant) -> Self {
        map { $0.config.variant = variant }
    }

    func contentAlign(_ contentAlign: ContentAlign) -> Self {
        map { $0.config.contentAlign = contentAlign }
    }

    func glowRing(_ appearance: GlowRingAppearance?) -> Self {
        map { $0.config.glowRing = appearance }
    }

    /// Exact match — otherwise a chain-terminal non-optional call silently resolves to the fully-defaulted `View.glowRing`.
    func glowRing(_ appearance: GlowRingAppearance) -> Self {
        glowRing(appearance as GlowRingAppearance?)
    }

    func titleLineLimit(_ limit: Int?) -> Self {
        map { $0.config.titleLineLimit = limit }
    }

    func descriptionLineLimit(_ limit: Int?) -> Self {
        map { $0.config.descriptionLineLimit = limit }
    }

    func secondaryButton(_ button: Button?) -> Self {
        map { $0.config.secondaryButton = button }
    }

    func primaryButton(_ button: Button?) -> Self {
        map { $0.config.primaryButton = button }
    }

    /// The banner is tappable only when it has no buttons — `secondaryButton`/`primaryButton` take precedence over `onTap`.
    func onTap(_ action: (() -> Void)?) -> Self {
        map { $0.config.onTap = action }
    }

    func accessibilityLabel(_ label: String?) -> Self {
        map { $0.config.accessibilityLabel = label }
    }
}

// MARK: - Slot transforms

public extension MessageBanner {
    func slotStart<V: View>(
        @ViewBuilder _ content: () -> V
    ) -> MessageBanner<V, SlotEnd, ExtraBottom> {
        MessageBanner<V, SlotEnd, ExtraBottom>(
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
    ) -> MessageBanner<SlotStart, V, ExtraBottom> {
        MessageBanner<SlotStart, V, ExtraBottom>(
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
    ) -> MessageBanner<SlotStart, SlotEnd, V> {
        MessageBanner<SlotStart, SlotEnd, V>(
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

public extension MessageBanner {
    func closeButton(
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> MessageBanner<SlotStart, MessageBannerCloseButton, ExtraBottom> {
        slotEnd {
            MessageBannerCloseButton(accessibilityLabel: accessibilityLabel, action: action)
        }
    }
}

public struct MessageBannerCloseButton: View {
    private let accessibilityLabel: String
    private let action: () -> Void

    @ScaledMetric private var iconSize = Metrics.iconSize

    public init(accessibilityLabel: String, action: @escaping () -> Void) {
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    public var body: some View {
        SwiftUI.Button(action: action) {
            DesignSystem.Icons.CrossCircle.filled20.image
                .renderingMode(.template)
                .resizable()
                .frame(width: iconSize, height: iconSize)
                .foregroundStyle(DesignSystem.Color.iconTertiary)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

private extension MessageBannerCloseButton {
    enum Metrics {
        static let iconSize: CGFloat = 20
    }
}
