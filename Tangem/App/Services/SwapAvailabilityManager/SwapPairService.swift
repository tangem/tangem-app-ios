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
import TangemSwapping

struct SwapPairService {
    let walletModelsManager: WalletModelsManager
    let userWalletId: String

    func canSwap() async -> Bool {
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

        print(walletModels)

        let expressCurrencies = walletModels.map { $0.expressCurrency }

        let factory = ExpressAPIProviderFactory()
        let provider = factory.makeExpressAPIProvider(userId: userWalletId, logger: AppLog.shared)

        let swapPairs: [ExpressPair]
        do {
            swapPairs = try await provider.pairs(from: expressCurrencies, to: expressCurrencies)
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
            if swapPair.destination != swapPair.source, currenciesWithBalance.contains(swapPair.source) || currenciesWithBalance.contains(swapPair.destination) {
                return true
            }
        }
        return false
    }
}
