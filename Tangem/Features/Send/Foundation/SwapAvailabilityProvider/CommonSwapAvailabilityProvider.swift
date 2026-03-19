//
//  CommonSwapAvailabilityProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

struct CommonSwapAvailabilityProvider: SwapAvailabilityProvider {
    @Injected(\.expressAvailabilityProvider)
    private var expressAvailabilityProvider: ExpressAvailabilityProvider

    let tokenItem: TokenItem
    let userWalletConfig: UserWalletConfig

    var isSwapAvailable: Bool {
        let canSwap = expressAvailabilityProvider.canSwap(tokenItem: tokenItem)
        let isMultiCurrency = userWalletConfig.hasFeature(.multiCurrency)

        return canSwap && isMultiCurrency
    }
}
