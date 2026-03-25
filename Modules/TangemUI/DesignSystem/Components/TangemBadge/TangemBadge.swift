//
//  TangemBadge.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

public struct TangemBadge: View, Setupable {
    private let text: String

    private var icon: Image?
    private var size: Size = .x9
    private var shape: Shape = .rectangular
    private var color: BadgeColor = .gray
    private var type: BadgeType = .solid
    private var iconPosition: IconPosition = .leading

    @ScaledMetric private var height: CGFloat
    @ScaledMetric private var iconSize: CGFloat
    @ScaledMetric private var horizontalPadding: CGFloat
    @ScaledMetric private var contentSpacing: CGFloat

    public init(text: String, size: Size = .x9) {
        self.text = text
        self.size = size

        _height = ScaledMetric(wrappedValue: size.baseHeight)
        _iconSize = ScaledMetric(wrappedValue: size.baseIconSize)
        _horizontalPadding = ScaledMetric(wrappedValue: size.baseHorizontalPadding)
        _contentSpacing = ScaledMetric(wrappedValue: size.baseContentSpacing)
    }

    public var body: some View {
        contentView
            .background(backgroundColor) { badgeShape }
            .overlay { borderView }
            .clipShape { badgeShape }
    }

    private var contentView: some View {
        HStack(spacing: contentSpacing) {
            if iconPosition == .leading, let icon {
                iconView(icon)
            }

            textView

            if iconPosition == .trailing, let icon {
                iconView(icon)
            }
        }
        .padding(.horizontal, horizontalPadding)
        .frame(minHeight: height)
    }

    private var textView: some View {
        Text(text)
            .style(size.font, color: Self.textColor(type: type, color: color))
            .lineLimit(1)
            .truncationMode(.tail)
    }

    private func iconView(_ icon: Image) -> some View {
        icon
            .resizable()
            .renderingMode(.template)
            .aspectRatio(contentMode: .fit)
            .frame(width: iconSize, height: iconSize)
            .foregroundStyle(Self.iconColor(type: type, color: color))
    }

    @ShapeBuilder
    private var badgeShape: AnyInsettableShape {
        switch shape {
        case .rectangular:
            RoundedRectangle(cornerRadius: shape.cornerRadius(for: size))
        case .rounded:
            Capsule()
        }
    }

    private var backgroundColor: Color? {
        Self.backgroundColor(type: type, color: color)
    }

    @ViewBuilder
    private var borderView: some View {
        if let borderColor = Self.borderColor(type: type, color: color) {
            badgeShape.stroke(borderColor, lineWidth: 1)
        }
    }
}

// MARK: - Setupable

public extension TangemBadge {
    func icon(_ icon: Image?) -> Self {
        map { $0.icon = icon }
    }

    func shape(_ shape: Shape) -> Self {
        map { $0.shape = shape }
    }

    func color(_ color: BadgeColor) -> Self {
        map { $0.color = color }
    }

    func type(_ type: BadgeType) -> Self {
        map { $0.type = type }
    }

    func iconPosition(_ position: IconPosition) -> Self {
        map { $0.iconPosition = position }
    }
}
