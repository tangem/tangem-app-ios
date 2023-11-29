//
//  TangemSwappingFactory.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public struct TangemSwappingFactory {
    private let oneInchApiKey: String

    public init(oneInchApiKey: String) {
        self.oneInchApiKey = oneInchApiKey
    }

    public func makeSwappingManager(
        walletDataProvider: SwappingWalletDataProvider,
        referrer: SwappingReferrerAccount? = nil,
        source: Currency,
        destination: Currency?,
        amount: Decimal? = nil,
        logger: SwappingLogger? = nil
    ) -> SwappingManager {
        let swappingItems = SwappingItems(source: source, destination: destination)
        let swappingService = OneInchAPIService(logger: logger ?? CommonSwappingLogger(), oneInchApiKey: oneInchApiKey)
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
