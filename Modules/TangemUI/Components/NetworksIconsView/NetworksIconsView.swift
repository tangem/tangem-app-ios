//
//  NetworksIconsView.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemAssets
import TangemUIUtils

public struct NetworksIconsView: View, Setupable {
    private let icons: [NetworkIconItem]

    private var maxVisible: Int = 3
    private var overlapRatio: CGFloat = 0.25
    private var ringColor: Color = DesignSystem.Color.bgSecondary

    @ScaledMetric private var iconDiameter: CGFloat = 24
    @ScaledMetric private var ringWidth: CGFloat = 2
    @ScaledMetric private var badgeHorizontalPadding: CGFloat = 4

    public init(icons: [NetworkIconItem]) {
        self.icons = icons
    }

    private var visibleIcons: [NetworkIconItem] {
        Array(icons.prefix(maxVisible))
    }

    private var overflow: Int {
        max(0, icons.count - maxVisible)
    }

    private var overlap: CGFloat {
        iconDiameter * overlapRatio
    }

    private var artDiameter: CGFloat {
        iconDiameter - 2 * ringWidth
    }

    public var body: some View {
        HStack(spacing: -overlap) {
            ForEach(visibleIcons.indices, id: \.self) { index in
                iconSlot(for: visibleIcons[index])
            }

            if overflow > 0 {
                overflowBadge
            }
        }
    }

    private func iconSlot(for icon: NetworkIconItem) -> some View {
        let size = CGSize(bothDimensions: artDiameter)

        return iconImage(for: icon, size: size)
            .frame(size: size)
            .clipShape(Circle())
            .padding(ringWidth)
            .background(ringColor, in: Circle())
    }

    @ViewBuilder
    private func iconImage(for icon: NetworkIconItem, size: CGSize) -> some View {
        switch icon {
        case .image(let image):
            image.image
                .resizable()
                .scaledToFit()
        case .remote(let url):
            IconView(url: url, size: size, forceKingfisher: true)
        case .token(let info):
            TokenIcon(tokenIconInfo: info, size: size, isWithOverlays: false)
        }
    }

    private var overflowBadge: some View {
        Text("+\(overflow)")
            .style(DesignSystem.Font.captionMediumToken, color: DesignSystem.Color.textSecondary)
            .lineLimit(1)
            .padding(.horizontal, badgeHorizontalPadding)
            .frame(height: artDiameter)
            .frame(minWidth: artDiameter)
            .background(DesignSystem.Color.bgTertiary, in: Capsule())
            .padding(ringWidth)
            .background(ringColor, in: Capsule())
    }
}

// MARK: - Setupable Modifiers

public extension NetworksIconsView {
    func maxVisible(_ count: Int) -> Self {
        map { $0.maxVisible = max(1, count) }
    }

    func iconSize(_ size: CGFloat) -> Self {
        map { $0._iconDiameter = ScaledMetric(wrappedValue: size) }
    }

    func overlapRatio(_ ratio: CGFloat) -> Self {
        map { $0.overlapRatio = ratio }
    }

    func ringWidth(_ width: CGFloat) -> Self {
        map { $0._ringWidth = ScaledMetric(wrappedValue: width) }
    }

    func ringColor(_ color: Color) -> Self {
        map { $0.ringColor = color }
    }
}

// MARK: - NetworkIconItem

public enum NetworkIconItem: Hashable {
    case image(ImageType)
    case remote(url: URL?)
    case token(TokenIconInfo)
}

// MARK: - Previews

#if DEBUG
private enum NetworksIconsViewPreviewData {
    static let glyphs: [ImageType] = [
        Tokens.bitcoinFill,
        Tokens.ethereumFill,
        Tokens.solanaFill,
        Tokens.polygonFill,
        Tokens.bitcoin,
        Tokens.ethereum,
    ]

    static func imageItems(_ count: Int) -> [NetworkIconItem] {
        (0 ..< count).map { .image(glyphs[$0 % glyphs.count]) }
    }
}

#Preview("Overflow") {
    VStack(alignment: .leading, spacing: 28) {
        NetworksIconsView(icons: NetworksIconsViewPreviewData.imageItems(1))
        NetworksIconsView(icons: NetworksIconsViewPreviewData.imageItems(2))
        NetworksIconsView(icons: NetworksIconsViewPreviewData.imageItems(15))
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(DesignSystem.Color.bgSecondary)
}

#Preview("Sizes") {
    VStack(alignment: .leading, spacing: 28) {
        NetworksIconsView(icons: NetworksIconsViewPreviewData.imageItems(8))
            .maxVisible(5)
            .iconSize(36)

        NetworksIconsView(icons: NetworksIconsViewPreviewData.imageItems(6))
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(DesignSystem.Color.bgSecondary)
}

#Preview("On a card") {
    NetworksIconsView(icons: NetworksIconsViewPreviewData.imageItems(6))
        .padding(12)
        .background(DesignSystem.Color.bgSecondary, in: RoundedRectangle(cornerRadius: 14))
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(DesignSystem.Color.bgPrimary)
}
#endif // DEBUG
