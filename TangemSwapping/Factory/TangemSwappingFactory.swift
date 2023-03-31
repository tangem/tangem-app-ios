//
//  TangemSwappingFactory.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

/// Public factory for work with swapping
public struct TangemSwappingFactory {
    public init() {}

    public func makeSwappingManager(
        walletDataProvider: SwappingWalletDataProvider,
        referrer: SwappingReferrerAccount? = nil,
        source: Currency,
        destination: Currency?,
        amount: Decimal? = nil,
        logger: SwappingLogger? = nil
    ) -> SwappingManager {
        let swappingItems = SwappingItems(source: source, destination: destination)
        let swappingService = OneInchAPIService(logger: logger ?? CommonSwappingLogger())
        let provider = OneInchSwappingProvider(swappingService: swappingService)

        return CommonSwappingManager(
            swappingProvider: provider,
            walletDataProvider: walletDataProvider,
            logger: logger ?? CommonSwappingLogger(),
            referrer: referrer,
            swappingItems: swappingItems,
            amount: amount
        )
    }
}
