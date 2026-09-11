//
//  CollectiblesFormatting.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

extension BalanceFormattingOptions {
    static let collectiblesDollars = BalanceFormattingOptions(
        minFractionDigits: 0,
        maxFractionDigits: 2,
        formatEpsilonAsLowestRepresentableValue: true,
        roundingType: .default(roundingMode: .plain, scale: 2)
    )
}

extension PercentFormatter.Option {
    static let collectibles = PercentFormatter.Option(fractionDigits: .init(min: 0, max: 0), prefix: .empty, suffix: .yield)
}
