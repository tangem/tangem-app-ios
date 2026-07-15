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
    private let closeAction: () -> Void
    private var variant: Variant = .neutral
    private var icon: ImageType?
    private var textLineLimit: Int? = Metrics.textLineLimit
    private var accessibilityIdentifier: String?

    @Environment(\.layoutDirection) private var layoutDirection

    @ScaledMetric private var iconSize: CGFloat = Metrics.iconSize
    @ScaledMetric private var tipSize: CGFloat = Metrics.tipSize
    @ScaledMetric private var cornerRadius: CGFloat = Metrics.cornerRadius
    @ScaledMetric private var tipLeadingInset: CGFloat = Metrics.tipLeadingInset

    public init(text: String, onClose: @escaping () -> Void) {
        self.text = text
        closeAction = onClose
    }

    public var body: some View {
        HStack(alignment: .top, spacing: Metrics.itemSpacing) {
            if let icon {
                tintedIcon(icon)
            }

            Text(text)
                .style(DesignSystem.Font.captionMediumToken, color: variant.palette.text)
                .lineLimit(textLineLimit)
                .ifLet(accessibilityIdentifier) { view, identifier in
                    view.accessibilityIdentifier(identifier)
                }

            closeButton
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
            .accessibilityHidden(true)
    }

    private var closeButton: some View {
        Button(action: closeAction) {
            DesignSystem.Icons.CrossCircle.filled16.image
                .renderingMode(.template)
                .resizable()
                .frame(width: iconSize, height: iconSize)
                .foregroundStyle(variant.palette.icon)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .padding(.leading, Metrics.closeWrapperLeadingPadding)
        .accessibilityLabel(Text(Localization.commonClose))
        .ifLet(closeAccessibilityIdentifier) { view, identifier in
            view.accessibilityIdentifier(identifier)
        }
    }

    private var closeAccessibilityIdentifier: String? {
        accessibilityIdentifier.map { "\($0)CloseButton" }
    }

    private var tip: some View {
        let horizontalSign: CGFloat = layoutDirection == .rightToLeft ? -1 : 1

        return TipShape()
            .fill(variant.palette.background)
            .frame(width: tipSize, height: tipSize)
            .scaleEffect(x: horizontalSign, y: 1)
            .offset(x: tipLeadingInset * horizontalSign, y: -tipSize)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

// MARK: - Setupable

public extension TangemMessageBubble {
    func variant(_ variant: Variant) -> Self {
        map { $0.variant = variant }
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

// MARK: - Public Type

public extension TangemMessageBubble {
    enum Variant: Hashable, Sendable, CaseIterable {
        case neutral
        case success
        case info
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
        static let textLineLimit: Int = 2
        static let itemSpacing: CGFloat = 4
        static let paddingTop: CGFloat = 4
        static let paddingBottom: CGFloat = 4
        static let paddingLeading: CGFloat = 8
        static let paddingTrailing: CGFloat = 4
        static let closeWrapperLeadingPadding: CGFloat = 4
        static let tipSize: CGFloat = 8
        static let tipLeadingInset: CGFloat = 16
    }
}
