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

/// A row of chips with overflow indicator using OverflowHStack.
public struct InfoChipsRowView: View {
    private let chips: [InfoChipItem]
    private let spacing: CGFloat
    private let alignment: HorizontalAlignment

    public init(
        chips: [InfoChipItem],
        spacing: CGFloat = 4,
        alignment: HorizontalAlignment = .leading
    ) {
        self.chips = chips
        self.spacing = spacing
        self.alignment = alignment
    }

    public var body: some View {
        OverflowHStack(
            chips,
            spacing: spacing,
            horizontalAlignment: alignment,
            viewGenerator: { chip in
                InfoChipView(item: chip)
            },
            overflowViewGenerator: { count in
                Text("+\(count)")
                    .style(Fonts.Bold.caption1, color: Colors.Text.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Colors.Control.unchecked)
                    .cornerRadiusContinuous(16)
                    .frame(height: 24)
            }
        )
    }
}

/// Single chip appearance.
public struct InfoChipView: View {
    public let item: InfoChipItem

    public init(item: InfoChipItem) {
        self.item = item
    }

    public var body: some View {
        HStack(spacing: Layout.contentSpacing) {
            if let icon = item.leadingIcon {
                makeIconImage(with: icon)
                    .frame(size: Layout.iconSize)
                    .fixedSize(horizontal: true, vertical: true)
            }

            Text(item.title)
                .style(Fonts.Bold.caption1, color: Colors.Text.secondary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: true)

            if let icon = item.trailingIcon {
                makeIconImage(with: icon)
                    .frame(size: Layout.iconSize)
                    .fixedSize(horizontal: true, vertical: true)
            }
        }
        .frame(height: Layout.contentHeight)
        .defaultRoundedBackground(
            with: Colors.Control.unchecked,
            verticalPadding: Layout.verticalPadding,
            horizontalPadding: Layout.horizontalPadding,
            cornerRadius: Layout.cornerRadius
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
            IconView(url: url, size: Layout.iconSize, forceKingfisher: true)
        }
    }

    private enum Layout {
        static let contentHeight: CGFloat = 16
        static let contentSpacing: CGFloat = 4
        static let horizontalPadding: CGFloat = 10
        static let verticalPadding: CGFloat = 4
        static let cornerRadius: CGFloat = 16
        static let iconSize: CGSize = .init(bothDimensions: 16)
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
