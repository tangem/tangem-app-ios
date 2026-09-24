//
//  TangemMessageBubble.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemLocalization
import TangemUIUtils

public struct TangemMessageBubble: View, Setupable {
    private let text: String
    private var trailingAccessory: TrailingAccessory?
    private var variant: Variant = .neutral
    private var icon: ImageType?
    private var textLineLimit: Int? = Metrics.textLineLimit
    private var accessibilityIdentifier: String?

    @ScaledMetric private var iconSize: CGFloat = Metrics.iconSize
    @ScaledMetric private var tipSize: CGFloat = Metrics.tipSize
    @ScaledMetric private var cornerRadius: CGFloat = Metrics.cornerRadius
    @ScaledMetric private var tipLeadingInset: CGFloat = Metrics.tipLeadingInset

    public init(text: String) {
        self.text = text
    }

    public init(text: String, onClose: @escaping () -> Void) {
        self.text = text
        trailingAccessory = .close(action: onClose)
    }

    public var body: some View {
        HStack(alignment: .top, spacing: Metrics.itemSpacing) {
            if let icon {
                tintedIcon(icon)
                    .accessibilityHidden(true)
            }

            Text(text)
                .style(DesignSystem.Font.captionMediumToken, color: variant.palette.text)
                .lineLimit(textLineLimit)
                .ifLet(accessibilityIdentifier) { view, identifier in
                    view.accessibilityIdentifier(identifier)
                }

            switch trailingAccessory {
            case .close(let action): closeButton(action: action)
            case .icon(let icon, let action): trailingIcon(icon, action: action)
            case .none: EmptyView()
            }
        }
        .padding(.top, Metrics.paddingTop)
        .padding(.bottom, Metrics.paddingBottom)
        .padding(.leading, Metrics.paddingLeading)
        .padding(.trailing, Metrics.paddingTrailing)
        .background(variant.palette.background, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(alignment: .topLeading) { tip }
    }

    private func tintedIcon(_ icon: ImageType) -> some View {
        icon.image
            .renderingMode(.template)
            .resizable()
            .frame(width: iconSize, height: iconSize)
            .foregroundStyle(variant.palette.icon)
    }

    private func iconButton(_ icon: ImageType, action: @escaping () -> Void) -> some View {
        SwiftUI.Button(action: action) {
            tintedIcon(icon)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func trailingIcon(_ icon: ImageType, action: (() -> Void)?) -> some View {
        if let action {
            iconButton(icon, action: action)
                .padding(.leading, Metrics.trailingAccessoryLeadingPadding)
        } else {
            tintedIcon(icon)
                .accessibilityHidden(true)
                .padding(.leading, Metrics.trailingAccessoryLeadingPadding)
        }
    }

    private func closeButton(action: @escaping () -> Void) -> some View {
        iconButton(DesignSystem.Icons.CrossCircle.filled16, action: action)
            .padding(.leading, Metrics.trailingAccessoryLeadingPadding)
            .accessibilityLabel(Text(Localization.commonClose))
            .ifLet(closeAccessibilityIdentifier) { view, identifier in
                view.accessibilityIdentifier(identifier)
            }
    }

    private var closeAccessibilityIdentifier: String? {
        accessibilityIdentifier.map { "\($0)CloseButton" }
    }

    private var tip: some View {
        TipShape()
            .fill(variant.palette.background)
            .frame(width: tipSize, height: tipSize)
            .offset(x: tipLeadingInset, y: -tipSize)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

// MARK: - Setupable

public extension TangemMessageBubble {
    func variant(_ variant: Variant) -> Self {
        map { $0.variant = variant }
    }

    func trailingAccessory(_ trailingAccessory: TrailingAccessory?) -> Self {
        map { $0.trailingAccessory = trailingAccessory }
    }

    func icon(_ icon: ImageType?) -> Self {
        map { $0.icon = icon }
    }

    func lineLimit(_ lineLimit: Int?) -> Self {
        map { $0.textLineLimit = lineLimit }
    }

    func accessibilityIdentifier(_ accessibilityIdentifier: String) -> Self {
        map { $0.accessibilityIdentifier = accessibilityIdentifier }
    }
}

// MARK: - Geometry

public extension TangemMessageBubble {
    static let tipLeadingInset: CGFloat = Metrics.tipLeadingInset
}

// MARK: - Public Type

public extension TangemMessageBubble {
    enum Variant: Hashable, Sendable, CaseIterable {
        case neutral
        case success
        case error
        case warning
        case info
    }

    enum TrailingAccessory: Equatable {
        case close(action: () -> Void)
        case icon(ImageType, action: (() -> Void)? = nil)

        public static var chevron: Self {
            .icon(DesignSystem.Icons.ChevronRight.regular16)
        }

        public static func == (lhs: Self, rhs: Self) -> Bool {
            switch (lhs, rhs) {
            case (.close, .close): true
            case (.icon(let lhsIcon, let lhsAction), .icon(let rhsIcon, let rhsAction)): lhsIcon == rhsIcon && (lhsAction == nil) == (rhsAction == nil)
            default: false
            }
        }
    }
}

// MARK: - Palette

private struct MessageBubblePalette {
    let background: Color
    let text: Color
    let icon: Color
}

private extension TangemMessageBubble.Variant {
    var palette: MessageBubblePalette {
        switch self {
        case .neutral:
            MessageBubblePalette(
                background: DesignSystem.Color.bgTertiary,
                text: DesignSystem.Color.textSecondary,
                icon: DesignSystem.Color.iconSecondary
            )
        case .success:
            MessageBubblePalette(
                background: DesignSystem.Color.bgStatusSuccessSubtle,
                text: DesignSystem.Color.textStatusSuccess,
                icon: DesignSystem.Color.iconStatusSuccess
            )
        case .error:
            MessageBubblePalette(
                background: DesignSystem.Color.bgStatusErrorSubtle,
                text: DesignSystem.Color.textStatusError,
                icon: DesignSystem.Color.iconStatusError
            )
        case .warning:
            MessageBubblePalette(
                background: DesignSystem.Color.bgStatusWarningSubtle,
                text: DesignSystem.Color.textStatusWarning,
                icon: DesignSystem.Color.iconStatusWarning
            )
        case .info:
            MessageBubblePalette(
                background: DesignSystem.Color.bgStatusInfoSubtle,
                text: DesignSystem.Color.textStatusInfo,
                icon: DesignSystem.Color.iconStatusInfo
            )
        }
    }
}

// MARK: - Tip

private struct TipShape: Shape {
    func path(in rect: CGRect) -> Path {
        func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: x / 8 * rect.width, y: y / 8 * rect.height)
        }

        var path = Path()
        path.move(to: point(8, 8))
        path.addLine(to: point(0, 8))
        path.addLine(to: point(0, 0))
        path.addCurve(to: point(8, 8), control1: point(0, 0), control2: point(2, 6))
        path.closeSubpath()
        return path
    }
}

// MARK: - Metrics

private extension TangemMessageBubble {
    enum Metrics {
        static let cornerRadius: CGFloat = 12
        static let iconSize: CGFloat = 16
        static let textLineLimit: Int = 3
        static let itemSpacing: CGFloat = 4
        static let paddingTop: CGFloat = 4
        static let paddingBottom: CGFloat = 4
        static let paddingLeading: CGFloat = 8
        static let paddingTrailing: CGFloat = 4
        static let trailingAccessoryLeadingPadding: CGFloat = 4
        static let tipSize: CGFloat = 8
        static let tipLeadingInset: CGFloat = 16
    }
}
