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
        static let contentSpacing: CGFloat = 4
        static let horizontalPadding: CGFloat = 10
        static let verticalPadding: CGFloat = 4
        static let cornerRadius: CGFloat = 16
        static let iconSize: CGSize = .init(bothDimensions: 16)
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
            with: Colors.Control.unchecked,
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
        let layout = (width > 0 && hasMeasuredAllChips) ? layoutResult(for: width) : (visible: chips, hiddenCount: 0)

        HStack(spacing: Layout.defaultSpacing) {
            ForEach(layout.visible) { chip in
                InfoChipView(item: chip)
            }

            if layout.hiddenCount > 0 {
                OverflowChip(hiddenCount: layout.hiddenCount)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .background(measurementView)
        .infinityFrame(axis: .horizontal, alignment: alignment.swiftUIAlignment)
        .readGeometry(\.size.width) { availableWidth = $0 }
        .clipped()
    }

    private var hasMeasuredAllChips: Bool {
        chips.allSatisfy { chipSizes[$0.id] != nil }
    }

    private var measurementView: some View {
        Group {
            if chips.isEmpty {
                EmptyView()
            } else {
                HStack(spacing: Layout.defaultSpacing) {
                    ForEach(chips) { chip in
                        InfoChipView(item: chip)
                            .readGeometry(\.size) { size in
                                chipSizes[chip.id] = size
                            }
                    }

                    // Measure a "worst case" overflow width (max number of digits = chips.count).
                    OverflowChip(hiddenCount: chips.count)
                        .readGeometry(\.size) { size in
                            overflowSize = size
                        }
                }
                .fixedSize(horizontal: true, vertical: true)
                .opacity(0)
                .allowsHitTesting(false)
            }
        }
    }

    private func layoutResult(for availableWidth: CGFloat) -> (visible: [InfoChipItem], hiddenCount: Int) {
        guard availableWidth > 0, hasMeasuredAllChips else {
            return (chips, 0)
        }

        var bestVisibleCount = 0
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
        let btcIcon = Image(systemName: "bitcoinsign.circle.fill")
        let ethIcon = Image(systemName: "e.circle.fill")
        let regulationIcon = Image(systemName: "building.columns.fill")
        let hackIcon = Image(systemName: "exclamationmark.shield.fill")

        let cryptoNewsTitles = [
            "BTC breaks $50K",
            "ETH network upgrade",
            "SEC: new rules",
            "ETF inflows",
            "Exchange: token delisting",
            "Network: fees spike",
            "DeFi: TVL up",
            "Airdrop: snapshot",
            "Mining: difficulty up",
            "Hack: protocol exploited",
            "Stablecoins: risk premium",
        ]

        let cryptoNewsChips = cryptoNewsTitles.map { title in
            let leadingIcon: InfoChipIcon? = switch title {
            case let title where title.hasPrefix("BTC"):
                .image(btcIcon)
            case let title where title.hasPrefix("ETH"):
                .image(ethIcon)
            case let title where title.hasPrefix("SEC"), let title where title.hasPrefix("ETF"), let title where title.hasPrefix("Stablecoins"):
                .image(regulationIcon)
            case let title where title.hasPrefix("Hack"):
                .image(hackIcon)
            default:
                nil
            }

            return InfoChipItem(title: title, leadingIcon: leadingIcon)
        }

        InfoChipsView(
            chips: cryptoNewsChips,
            alignment: .leading
        )

        InfoChipsView(
            chips: [
                InfoChipItem(title: "Regulation"),
                InfoChipItem(title: "ETF inflows", leadingIcon: .image(regulationIcon), trailingIcon: .image(regulationIcon)),
                InfoChipItem(title: "BTC ATH?", leadingIcon: .image(btcIcon)),
            ],
            alignment: .center
        )

        Spacer(minLength: .zero)
    }
    .padding()
    .background(Colors.Background.action)
}
#endif
