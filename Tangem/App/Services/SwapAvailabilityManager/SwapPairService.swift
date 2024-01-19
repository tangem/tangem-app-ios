//
//  SwapPairService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemExpress

struct SwapPairService {
    @Injected(\.swapAvailabilityProvider) private var swapAvailabilityProvider: SwapAvailabilityProvider

    let tokenItem: TokenItem
    let walletModelsManager: WalletModelsManager
    let userWalletId: String

    func canSwap() async -> Bool {
        guard swapAvailabilityProvider.canSwap(tokenItem: tokenItem) else {
            return false
        }

        let selectedExpressCurrency = tokenItem.expressCurrency

        let walletModels = await walletModelsManager.walletModelsPublisher
            .removeDuplicates()
            .flatMap { walletModels in
                return Publishers.MergeMany(walletModels.map { $0.walletDidChangePublisher })
                    .map { _ in walletModels }
                    .filter { walletModels in
                        walletModels.allConforms { !$0.state.isLoading }
                    }
            }
            .eraseToAnyPublisher()
            .async()

        let expressCurrencies = walletModels.map { $0.expressCurrency }

        let factory = ExpressAPIProviderFactory()
        let provider = factory.makeExpressAPIProvider(userId: userWalletId, logger: AppLog.shared)

        let swapPairs: [ExpressPair]
        do {
            async let swapPairsFromSelected = provider.pairs(from: [selectedExpressCurrency], to: expressCurrencies)
            async let swapPairsToSelected = provider.pairs(from: expressCurrencies, to: [selectedExpressCurrency])
            swapPairs = try await (swapPairsFromSelected + swapPairsToSelected)
        } catch {
            return false
        }

        let currenciesWithBalance: Set<ExpressCurrency> = Set(walletModels
            .filter {
                !$0.isZeroAmount
            }
            .map {
                $0.expressCurrency
            }
        )

        for swapPair in swapPairs {
            guard
                swapPair.destination != swapPair.source,
                currenciesWithBalance.contains(swapPair.source)
            else {
                continue
            }

            if swapPair.source == selectedExpressCurrency || swapPair.destination == selectedExpressCurrency {
                return true
            }
        }
        return false
    }
}
