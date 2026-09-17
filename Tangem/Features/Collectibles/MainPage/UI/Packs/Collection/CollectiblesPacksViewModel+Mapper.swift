//
//  CollectiblesPacksViewModel+Mapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

extension CollectiblesPacksViewModel {
    enum Mapper {
        private static let balanceFormatter = BalanceFormatter()
        private static let percentFormatter = PercentFormatter()

        static func map(_ packs: [CollectiblesPack]) -> [CollectiblesPackCard.Model] {
            packs.map(makeCardModel)
        }
    }
}

private extension CollectiblesPacksViewModel.Mapper {
    static func makeCardModel(_ pack: CollectiblesPack) -> CollectiblesPackCard.Model {
        CollectiblesPackCard.Model(
            id: pack.id,
            title: pack.name,
            priceText: balanceFormatter.formatFiatBalance(
                pack.price,
                currencyCode: pack.currencyCode,
                formattingOptions: .collectiblesDollars
            ),
            buybackText: pack.buybackRate.map(makeBuybackText),
            artworkURL: pack.artworkURL
        )
    }

    static func makeBuybackText(rate: Decimal) -> String {
        Localization.collectiblesMainPackBuybackBadge(percentFormatter.format(rate, option: .collectibles))
    }
}
