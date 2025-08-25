//
//  WCFeeRowViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import BlockchainSdk

struct WCFeeRowViewModel {
    let components: LoadingValue<FormattedFeeComponents>
    let onTap: () -> Void

    init(
        selectedFee: WCFee,
        blockchain: Blockchain,
        feeTokenItem: TokenItem,
        onTap: @escaping () -> Void
    ) {
        self.onTap = onTap
        components = Self.mapToFormattedFeeComponents(
            selectedFee: selectedFee,
            blockchain: blockchain,
            feeTokenItem: feeTokenItem
        )
    }

    private static func mapToFormattedFeeComponents(
        selectedFee: WCFee,
        blockchain: Blockchain,
        feeTokenItem: TokenItem
    ) -> LoadingValue<FormattedFeeComponents> {
        switch selectedFee.value {
        case .loading:
            return .loading
        case .loaded(let fee):
            let feeFormatter = CommonFeeFormatter(
                balanceFormatter: BalanceFormatter(),
                balanceConverter: BalanceConverter()
            )

            let components = feeFormatter.formattedFeeComponents(
                fee: fee.amount.value,
                currencySymbol: blockchain.currencySymbol,
                currencyId: feeTokenItem.currencyId,
                isFeeApproximate: false,
                formattingOptions: .defaultCryptoFeeFormattingOptions
            )
            return .loaded(components)
        case .failedToLoad(let error):
            return .failedToLoad(error: error)
        }
    }
}
