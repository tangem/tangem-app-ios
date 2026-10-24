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
            title: pack.machine.name,
            priceText: CollectiblesPriceFormatter.format(pack.machine.price, currencyCode: pack.currencyCode),
            buybackText: makeBuybackText(rate: pack.machine.buybackRate),
            artworkURL: pack.machine.artworkURL
        )
    }

    static func makeBuybackText(rate: Decimal) -> String {
        Localization.collectiblesMainPackBuybackBadge(percentFormatter.format(rate, option: .collectibles))
    }
}
