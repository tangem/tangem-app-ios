//
//  InfoChipView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils
import TangemFoundation

/// Data model for a single chip.
public struct InfoChipItem: Identifiable, Equatable {
    public let id: String
    public let title: String
    public var leadingIcon: InfoChipIcon?
    public var trailingIcon: InfoChipIcon?

    public init(
        id: String = UUID().uuidString,
        title: String,
        leadingIcon: InfoChipIcon? = nil,
        trailingIcon: InfoChipIcon? = nil
    ) {
        self.id = id
        self.title = title
        self.leadingIcon = leadingIcon
        self.trailingIcon = trailingIcon
    }
}

/// Defines how an icon should be rendered inside a chip.
public enum InfoChipIcon: Equatable {
    case image(Image)
    case url(URL)
}

/// A row of chips with optional overflow indicator.
public struct InfoChipsRowView: View {
    private let chips: [InfoChipItem]
    private let spacing: CGFloat
    private let alignment: HorizontalAlignment
    private let lineLimit: Int?
    private let style: InfoChipView.Style

    /// Creates a chips row view.
    /// - Parameters:
    ///   - chips: The chips to display.
    ///   - spacing: Spacing between chips (default: 4).
    ///   - alignment: Horizontal alignment (default: .leading).
    ///   - lineLimit: Maximum number of lines. Use `1` for single line with "+N", `nil` for unlimited (default: 1).
    public init(
        chips: [InfoChipItem],
        spacing: CGFloat = 4,
        alignment: HorizontalAlignment = .leading,
        lineLimit: Int? = 1,
        style: InfoChipView.Style = .legacy
    ) {
        self.chips = chips
        self.spacing = spacing
        self.alignment = alignment
        self.lineLimit = lineLimit
        self.style = style
    }

    public var body: some View {
        OverflowHStack(
            chips,
            horizontalSpacing: spacing,
            verticalSpacing: spacing,
            horizontalAlignment: alignment,
            lineLimit: lineLimit
        ) { chip in
            InfoChipView(item: chip, style: style)
        } limitViewGenerator: { count in
            if style == .redesign {
                InfoChipsOverflowView(style: style)
            } else {
                Text("+\(count)")
                    .style(style.titleFont, color: style.titleColor)
                    .padding(.horizontal, style.horizontalPadding)
                    .padding(.vertical, style.verticalPadding)
                    .background(style.backgroundColor)
                    .cornerRadiusContinuous(style.cornerRadius)
            }
        }
    }
}

/// Overflow indicator for a redesign-style chips row — the "…" pill shown when
/// not all chips fit on a single line. Matches the pill geometry of a regular
/// `InfoChipView`: icon sits inside a contentHeight-tall slot, wrapped with the
/// same rounded background / padding used by text chips.
private struct InfoChipsOverflowView: View {
    let style: InfoChipView.Style

    @ScaledMetric(relativeTo: .caption) private var iconWidth: CGFloat = .unit(.x5)
    @ScaledMetric(relativeTo: .caption) private var iconHeight: CGFloat = .unit(.x4)

    var body: some View {
        Assets.horizontalDots.image
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundStyle(Color.Tangem.Markers.iconGray)
            .frame(width: iconWidth, height: iconHeight)
            .frame(height: style.contentHeight)
            .defaultRoundedBackground(
                with: style.backgroundColor,
                verticalPadding: style.verticalPadding,
                horizontalPadding: style.horizontalPadding,
                cornerRadius: style.cornerRadius
            )
    }
}

/// Single chip appearance.
public struct InfoChipView: View {
    public let item: InfoChipItem
    private let style: Style

    public init(item: InfoChipItem, style: Style = .legacy) {
        self.item = item
        self.style = style
    }

    public var body: some View {
        HStack(spacing: .unit(.x1)) {
            if let icon = item.leadingIcon {
                makeIconImage(with: icon)
                    .frame(size: style.iconSize)
                    .fixedSize(horizontal: true, vertical: true)
            }

            Text(item.title)
                .style(style.titleFont, color: style.titleColor)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: true)

            if let icon = item.trailingIcon {
                makeIconImage(with: icon)
                    .frame(size: style.iconSize)
                    .fixedSize(horizontal: true, vertical: true)
            }
        }
        .frame(height: style.contentHeight)
        .defaultRoundedBackground(
            with: style.backgroundColor,
            verticalPadding: style.verticalPadding,
            horizontalPadding: style.horizontalPadding,
            cornerRadius: style.cornerRadius
        )
    }

    @ViewBuilder
    private func makeIconImage(with iconType: InfoChipIcon) -> some View {
        switch iconType {
        case .image(let image):
            image
                .resizable()
                .renderingMode(.template)
        case .url(let url):
            IconView(url: url, size: style.iconSize, forceKingfisher: true)
        }
    }
}

// MARK: - InfoChipView.Style

public extension InfoChipView {
    enum Style {
        case legacy
        case redesign

        var verticalPadding: CGFloat { .unit(.x1) }
        var cornerRadius: CGFloat { .unit(.x4) }
        var iconSize: CGSize { .init(bothDimensions: .unit(.x4)) }

        var contentHeight: CGFloat {
            switch self {
            case .legacy: return .unit(.x4)
            case .redesign: return .unit(.x6)
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .legacy: return 10
            case .redesign: return .unit(.x2)
            }
        }

        var titleFont: TangemFontStyle {
            switch self {
            case .legacy: return TangemFontStyle(font: Fonts.Bold.caption1)
            case .redesign: return Font.Tangem.Caption12.semibold
            }
        }

        var titleColor: Color {
            switch self {
            case .legacy: return Colors.Text.secondary
            case .redesign: return Color.Tangem.Markers.textGray
            }
        }

        var backgroundColor: Color {
            switch self {
            case .legacy: return Colors.Control.unchecked
            case .redesign: return Color.Tangem.Markers.backgroundTintedGray
            }
        }
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 12) {
        InfoChipView(item: InfoChipItem(title: "BTC"))
        InfoChipView(item: InfoChipItem(title: "With icon", leadingIcon: .image(Image(systemName: "star.fill"))))
    }
    .padding()
}
#endif
