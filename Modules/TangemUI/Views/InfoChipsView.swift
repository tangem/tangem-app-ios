//
//  InfoChipsView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

/// Data model for a single chip.
public struct InfoChipItem: Identifiable, Hashable {
    public let id: String
    public let title: String
    public let leadingIcon: InfoChipIcon?
    public let trailingIcon: InfoChipIcon?

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

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(title)
    }

    public static func == (lhs: InfoChipItem, rhs: InfoChipItem) -> Bool {
        lhs.id == rhs.id && lhs.title == rhs.title
    }
}

/// Defines how an icon should be rendered inside a chip.
public enum InfoChipIcon {
    case system(String)
    case asset(String)

    public var view: Image {
        switch self {
        case .system(let name):
            Image(systemName: name)
        case .asset(let name):
            Image(name)
        }
    }
}

/// Alignment options for chips container.
public enum InfoChipsAlignment {
    case center
    case leading
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
                icon.view
                    .resizable()
                    .renderingMode(.template)
                    .frame(size: .init(bothDimensions: 16))
                    .fixedSize(horizontal: true, vertical: true)
            }

            Text(item.title)
                .style(Fonts.Bold.caption1, color: Colors.Text.secondary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: true)

            if let icon = item.trailingIcon {
                icon.view
                    .resizable()
                    .renderingMode(.template)
                    .frame(size: .init(bothDimensions: 16))
                    .fixedSize(horizontal: true, vertical: true)
            }
        }
        .defaultRoundedBackground(
            with: Colors.Control.unchecked,
            verticalPadding: Layout.verticalPadding,
            horizontalPadding: Layout.horizontalPadding,
            cornerRadius: Layout.cornerRadius
        )
    }

    private enum Layout {
        static let contentSpacing: CGFloat = 4
        static let horizontalPadding: CGFloat = 10
        static let verticalPadding: CGFloat = 4
        static let cornerRadius: CGFloat = 16
    }
}

/// Chip representing overflow count.
private struct OverflowChip: View {
    let hiddenCount: Int

    var body: some View {
        HStack(spacing: Layout.contentSpacing) {
            Text("+\(hiddenCount)")
                .style(Fonts.Bold.caption1, color: Colors.Text.secondary)
                .fixedSize(horizontal: true, vertical: true)
        }
        .defaultRoundedBackground(
            with: Colors.Control.checked,
            verticalPadding: Layout.verticalPadding,
            horizontalPadding: Layout.horizontalPadding
        )
    }

    private enum Layout {
        static let contentSpacing: CGFloat = .zero
        static let horizontalPadding: CGFloat = 10
        static let verticalPadding: CGFloat = 4
    }
}

/// A horizontally flowing chips container that collapses overflowing chips into a "+N" indicator.
public struct InfoChipsView: View {
    public let chips: [InfoChipItem]
    public var alignment: InfoChipsAlignment = .center

    @State private var chipSizes: [InfoChipItem.ID: CGSize] = [:]
    @State private var overflowSize: CGSize = .zero
    @State private var availableWidth: CGFloat = 0

    public init(
        chips: [InfoChipItem],
        alignment: InfoChipsAlignment = .center
    ) {
        self.chips = chips
        self.alignment = alignment
    }

    public var body: some View {
        let width = availableWidth
        let layout = width > 0 ? layoutResult(for: width) : (visible: chips, hiddenCount: 0)

        HStack(spacing: Layout.defaultSpacing) {
            ForEach(layout.visible) { chip in
                InfoChipView(item: chip)
                    .readGeometry(\.size) { size in
                        chipSizes[chip.id] = size
                    }
            }

            if layout.hiddenCount > 0 {
                OverflowChip(hiddenCount: layout.hiddenCount)
                    .readGeometry(\.size) { size in
                        overflowSize = size
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: alignment.swiftUIAlignment)
        .fixedSize(horizontal: false, vertical: true)
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear { availableWidth = proxy.size.width }
                    .onChange(of: proxy.size.width) { availableWidth = $0 }
            }
        )
        .infinityFrame(axis: .horizontal, alignment: alignment.swiftUIAlignment)
    }

    private func layoutResult(for availableWidth: CGFloat) -> (visible: [InfoChipItem], hiddenCount: Int) {
        guard availableWidth > 0, !chipSizes.isEmpty else {
            return (chips, 0)
        }

        var bestVisibleCount = chips.count
        var usedWidth: CGFloat = 0
        let overflowWidth = overflowSize.width > 0 ? overflowSize.width : Layout.overflowDefaultWidth

        for visibleCount in 0 ... chips.count {
            usedWidth = 0

            // Width of the chips that would be visible.
            for index in 0 ..< visibleCount {
                if index > 0 {
                    usedWidth += Layout.defaultSpacing
                }
                let chip = chips[index]
                let chipWidth = chipSizes[chip.id]?.width ?? 0
                usedWidth += chipWidth
            }

            // If there will be hidden chips, include overflow chip width.
            let hidden = chips.count - visibleCount
            if hidden > 0 {
                if visibleCount > 0 {
                    usedWidth += Layout.defaultSpacing
                }
                usedWidth += overflowWidth
            }

            if usedWidth <= availableWidth {
                bestVisibleCount = visibleCount
            } else {
                break
            }
        }

        bestVisibleCount = min(bestVisibleCount, chips.count)
        let hiddenCount = max(chips.count - bestVisibleCount, 0)
        let visible = Array(chips.prefix(bestVisibleCount))
        return (visible, hiddenCount)
    }

    private enum Layout {
        static let defaultSpacing: CGFloat = 4
        static let overflowDefaultWidth: CGFloat = 36
    }
}

private extension InfoChipsAlignment {
    var swiftUIAlignment: Alignment {
        switch self {
        case .center:
            return .center
        case .leading:
            return .leading
        }
    }
}

#if DEBUG
#Preview {
    VStack(spacing: 12) {
        InfoChipsView(
            chips: [
                InfoChipItem(title: "Tag"),
                InfoChipItem(title: "Tag", leadingIcon: .system("bitcoinsign.circle.fill")),
                InfoChipItem(title: "Tag"),
                InfoChipItem(title: "Tag", leadingIcon: .system("bitcoinsign.circle.fill")),
                InfoChipItem(title: "Tag"),
                InfoChipItem(title: "+3"),
            ],
            alignment: .leading
        )

        InfoChipsView(
            chips: [
                InfoChipItem(title: "Regulation"),
                InfoChipItem(title: "Tag", leadingIcon: .system("bitcoinsign.circle.fill"), trailingIcon: .system("bitcoinsign.circle.fill")),
                InfoChipItem(title: "Tag"),
            ],
            alignment: .center
        )

        Spacer(minLength: .zero)
    }
    .padding()
    .background(Colors.Background.action)
}
#endif
