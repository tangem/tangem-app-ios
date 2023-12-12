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
    @Injected(\.swapAvailabilityProvider) private var swapAvailabilityProvider: SwapAvailabilityProvider

    let walletModel: WalletModel
    let walletModelsManager: WalletModelsManager
    let userWalletId: String

    func canSwap() -> AnyPublisher<Bool, Never> {
        return walletModelsManager.walletModelsPublisher
            .removeDuplicates()
            .flatMap { walletModels in
                return Publishers.MergeMany(walletModels.map { $0.walletDidChangePublisher })
                    .map { _ in walletModels }
                    .filter { walletModels in
                        walletModels.allConforms { !$0.state.isLoading }
                    }
            }
            .flatMap { walletModels -> AnyPublisher<Bool, Never> in
                let expressCurrencies = walletModels.map { $0.expressCurrency }

                if !walletModel.isZeroAmount, swapAvailabilityProvider.canSwap(tokenItem: walletModel.tokenItem) {
                    return .just(output: true)
                }

                return Deferred {
                    Future<Bool, Never> { promise in
                        Task {
                            let factory = ExpressAPIProviderFactory()
                            let provider = factory.makeExpressAPIProvider(userId: userWalletId, logger: AppLog.shared)

                            do {
                                let swapPairs = try await provider.pairs(from: expressCurrencies, to: expressCurrencies)

                                let currenciesWithBalance: Set<ExpressCurrency> = Set(walletModels
                                    .filter {
                                        !$0.isZeroAmount
                                    }
                                    .map {
                                        $0.expressCurrency
                                    }
                                )

                                var canSwap = false
                                for swapPair in swapPairs {
                                    if swapPair.destination != swapPair.source, currenciesWithBalance.contains(swapPair.source) || currenciesWithBalance.contains(swapPair.destination) {
                                        canSwap = true
                                        break
                                    }
                                }

                                print("ZZZ", currenciesWithBalance, canSwap)

                                promise(.success(canSwap))
                            } catch {
                                promise(.success(false))
                            }
                        }
                    }
                }
                .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }
}
