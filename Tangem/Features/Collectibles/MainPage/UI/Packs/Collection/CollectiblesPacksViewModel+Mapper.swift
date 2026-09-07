//
//  CollectiblesPacksViewModel+Mapper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

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
    static let priceFormattingOptions = BalanceFormattingOptions(
        minFractionDigits: 0,
        maxFractionDigits: 2,
        formatEpsilonAsLowestRepresentableValue: true,
        roundingType: .default(roundingMode: .plain, scale: 2)
    )

    static let buybackRateFormattingOption = PercentFormatter.Option(
        fractionDigits: .init(min: 0, max: 0),
        prefix: .empty,
        suffix: .yield
    )

    static func makeCardModel(_ pack: CollectiblesPack) -> CollectiblesPackCard.Model {
        CollectiblesPackCard.Model(
            id: pack.id,
            title: pack.name,
            priceText: balanceFormatter.formatFiatBalance(
                pack.price,
                currencyCode: pack.currencyCode,
                formattingOptions: priceFormattingOptions
            ),
            buybackText: pack.buybackRate.map(makeBuybackText),
            artworkURL: pack.artworkURL
        )
    }

    static func makeBuybackText(rate: Decimal) -> String {
        // [REDACTED_TODO_COMMENT]
        "Buyback \(percentFormatter.format(rate, option: buybackRateFormattingOption))"
    }
}
