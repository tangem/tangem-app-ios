//
//  SendSummarySectionViewModelFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct SendSummarySectionViewModelFactory {
    private let tokenItem: TokenItem

    private var feeFormatter: SwappingFeeFormatter {
        CommonSwappingFeeFormatter(
            balanceFormatter: BalanceFormatter(),
            balanceConverter: BalanceConverter(),
            fiatRatesProvider: SwappingRatesProvider()
        )
    }

    init(tokenItem: TokenItem) {
        self.tokenItem = tokenItem
    }

    func makeFeeViewModel(from value: Fee?) -> DefaultTextWithTitleRowViewData? {
        guard let value else { return nil }

        let formattedValue = feeFormatter.format(
            fee: value.amount.value,
            tokenItem: tokenItem
        )

        return DefaultTextWithTitleRowViewData(title: Localization.sendNetworkFeeTitle, text: formattedValue)
    }
}
