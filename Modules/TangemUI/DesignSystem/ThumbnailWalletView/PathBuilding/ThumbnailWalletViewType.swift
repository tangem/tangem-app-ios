//
//  ThumbnailWalletViewType.swift
//  TangemModules
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

public enum ThumbnailWalletViewType: Equatable {
    case card(ThumbnailCardPathBuilder.FillColors)
    case twoCards(ThumbnailTwoCardsPathBuilder.FillColors)
    case threeCards(ThumbnailThreeCardsPathBuilder.FillColors)
    case tLetterCard(ThumbnailLetterCardPathBuilder.FillColors)
    case tLetterTwoCards(ThumbnailLetterTwoCardsPathBuilder.FillColors)
    case tLetterThreeCards(ThumbnailLetterThreeCardsPathBuilder.FillColors)
    case ring(ThumbnailRingPathBuilder.FillColors)
    case ringCard(ThumbnailRingCardPathBuilder.FillColors)
    case ringTwoCards(ThumbnailRingTwoCardsPathBuilder.FillColors)
    case mobileWallet(ThumbnailMobileWalletPathBuilder.FillColors)

    func buildParts(for size: CGSize, colorScheme: ColorScheme) -> [ThumbnailPathFillMode] {
        switch self {
        case .card(let colors):
            ThumbnailCardPathBuilder.build(for: size, with: colors, colorScheme: colorScheme)
        case .twoCards(let colors):
            ThumbnailTwoCardsPathBuilder.build(for: size, with: colors, colorScheme: colorScheme)
        case .threeCards(let colors):
            ThumbnailThreeCardsPathBuilder.build(for: size, with: colors, colorScheme: colorScheme)
        case .tLetterCard(let colors):
            ThumbnailLetterCardPathBuilder.build(for: size, with: colors, colorScheme: colorScheme)
        case .tLetterTwoCards(let colors):
            ThumbnailLetterTwoCardsPathBuilder.build(for: size, with: colors, colorScheme: colorScheme)
        case .tLetterThreeCards(let colors):
            ThumbnailLetterThreeCardsPathBuilder.build(for: size, with: colors, colorScheme: colorScheme)
        case .ring(let colors):
            ThumbnailRingPathBuilder.build(for: size, with: colors, colorScheme: colorScheme)
        case .ringCard(let colors):
            ThumbnailRingCardPathBuilder.build(for: size, with: colors, colorScheme: colorScheme)
        case .ringTwoCards(let colors):
            ThumbnailRingTwoCardsPathBuilder.build(for: size, with: colors, colorScheme: colorScheme)
        case .mobileWallet(let colors):
            ThumbnailMobileWalletPathBuilder.build(for: size, with: colors, colorScheme: colorScheme)
        }
    }
}

public struct MiniatureWalletView: View {
    public let type: ThumbnailWalletViewType

    public init(type: ThumbnailWalletViewType) {
        self.type = type
    }

    @Environment(\.colorScheme) private var colorScheme

    public var body: some View {
        Canvas { context, size in
            let parts = type.buildParts(for: size, colorScheme: colorScheme)
            buildFilledThumbnailShape(context: context, parts: parts)
        }
    }
}

// MARK: - Previews

#if DEBUG
import TangemAssets

@available(iOS 17.0, *)
#Preview("All Thumbnail Types") {
    let types: [(String, ThumbnailWalletViewType)] = {
        typealias CC = Color.Tangem.CardCollection
        return [
            ("card", .card(.init(card: CC.tangem))),
            ("twoCards", .twoCards(.init(card: CC.vivid1, secondCard: CC.vivid2))),
            ("threeCards", .threeCards(.init(card: CC.vivid1, secondCard: CC.vivid2, thirdCard: CC.vivid3))),
            ("tLetterCard", .tLetterCard(.init(card: CC.tangem, tLetter: CC.tLogo))),
            ("tLetterTwoCards", .tLetterTwoCards(.init(card: CC.tangem, secondCard: CC.tangem, tLetter: CC.tLogo))),
            ("tLetterThreeCards", .tLetterThreeCards(.init(card: CC.tangem, secondCard: CC.tangem, thirdCard: CC.tangem, tLetter: CC.tLogo))),
            ("ring", .ring(.init(ring: CC.tangem))),
            ("ringCard", .ringCard(.init(ring: CC.tangem, card: CC.tangem))),
            ("ringTwoCards", .ringTwoCards(.init(ring: CC.tangem, card: CC.tangem, secondCard: CC.tangem))),
            ("mobileWallet", .mobileWallet(.init(icon: .Tangem.Graphic.Status.attention))),
        ]
    }()

    ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 16)], spacing: 16) {
            ForEach(types, id: \.0) { name, type in
                VStack(spacing: 8) {
                    MiniatureWalletView(type: type)
                        .frame(width: 80, height: 80)

                    Text(name)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
    }
}
#endif // DEBUG
