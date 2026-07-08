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

public enum TangemMessageBannerVariant: Sendable, Hashable, CaseIterable {
    case `default`
    case solid
    case success
    case error
    case warning
    case info
}

public enum TangemMessageBannerContentAlign: Sendable, Hashable, CaseIterable {
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
    var titleLineLimit: Int = 3
    var descriptionLineLimit: Int = 3
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

    func titleLineLimit(_ limit: Int) -> Self {
        map { $0.config.titleLineLimit = limit }
    }

    func descriptionLineLimit(_ limit: Int) -> Self {
        map { $0.config.descriptionLineLimit = limit }
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

// MARK: - Slot transforms

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
    func closeButton(
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> TangemMessageBanner<SlotStart, TangemMessageBannerCloseButton, ExtraBottom> {
        slotEnd {
            TangemMessageBannerCloseButton(accessibilityLabel: accessibilityLabel, action: action)
        }
    }
}

public struct TangemMessageBannerCloseButton: View {
    private let accessibilityLabel: String
    private let action: () -> Void

    @ScaledMetric private var iconSize = Metrics.iconSize

    public init(accessibilityLabel: String, action: @escaping () -> Void) {
        self.accessibilityLabel = accessibilityLabel
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            DesignSystem.Icons.CrossCircle.filled20.image
                .renderingMode(.template)
                .resizable()
                .frame(width: iconSize, height: iconSize)
                .foregroundStyle(DesignSystem.Color.iconSecondary)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

private extension TangemMessageBannerCloseButton {
    enum Metrics {
        static let iconSize: CGFloat = 20
    }
}
