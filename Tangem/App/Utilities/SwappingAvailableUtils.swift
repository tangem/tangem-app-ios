//
//  SupportedSwappingBlockchain.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import TangemSwapping
import BlockchainSdk

struct SwappingAvailableUtils {
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    private let supportedBlockchains: [SwappingBlockchain] = [
        .ethereum,
        .bsc,
        .polygon,
        .optimism,
        .arbitrum,
        .gnosis,
        .avalanche,
        .fantom,
    ]

    func canSwap(amountType: Amount.AmountType, blockchain: Blockchain) -> Bool {
        // Checking that toggle is on
        guard FeatureProvider.isAvailable(.exchange) else {
            return false
        }

        let networkId = blockchain.networkId
        guard let blockchain = SwappingBlockchain(networkId: networkId) else {
            return false
        }

        switch amountType {
        case .coin:
            return supportedBlockchains.contains(blockchain)
        case .token(let token):
            // If exchangeable == nil then swap is available for old users
            return !token.isCustom && (token.exchangeable ?? true)
        default:
            return false
        }
    }

    func isSwapAvailable(for blockchain: Blockchain) -> Bool {
        let networkId = blockchain.networkId
        guard let swapBlockchain = SwappingBlockchain(networkId: networkId) else {
            return false
        }

        return supportedBlockchains.contains(swapBlockchain)
    }

    func canSwap(amount: Amount.AmountType, blockchain: Blockchain) -> AnyPublisher<Bool, Error> {
        // Checking that toggle is on
        guard FeatureProvider.isAvailable(.exchange) else {
            return .justWithError(output: false)
        }

        let networkId = blockchain.networkId
        guard let blockchain = SwappingBlockchain(networkId: networkId) else {
            return .justWithError(output: false)
        }

        switch amount {
        case .coin:
            return .justWithError(output: supportedBlockchains.contains(blockchain))
        case .token(let token):
            let currencyId = token.id ?? blockchain.id

            return tangemApiService
                .loadCoins(requestModel: .init(networkIds: [networkId], ids: [currencyId]))
                .map { models in
                    let coin = models.first(where: { $0.id == currencyId })
                    let tokenItem = coin?.items.first(where: { $0.id == currencyId })

                    if case .token = tokenItem {
                        return !token.isCustom && (token.exchangeable ?? true)
                    }

                    return false
                }
                .eraseToAnyPublisher()
//            // If exchangeable == nil then swap is available for old users
//            return !token.isCustom && (token.exchangeable ?? true)
        default:
            return .justWithError(output: false)
        }
    }
//
//    func canSwapToken(token: Token, in blockchain: Blockchain) -> AnyPublisher<Bool, Error> {
//        let networkId = blockchain.networkId
//        guard isSwapAvailable(forNetworkWith: networkId) else {
//            return .justWithError(output: false)
//        }
//
//
//
//        return tangemApiService
//            .loadCoins(requestModel: .init(networkIds: [networkId], ids: [currencyId]))
//            .map { models in
//                let coin = models.first(where: { $0.id == currencyId })
//                let tokenItem = coin?.items.first(where: { $0.id == currencyId })
//
//                if case .token = tokenItem {
//                    return !token.isCustom && (token.exchangeable ?? true)
//                }
//
//                return false
//            }
//            .eraseToAnyPublisher()
//    }

//    private func isSwapAvailable(forNetworkWith id: String) -> Bool {
//        guard FeatureProvider.isAvailable(.exchange) else {
//            return false
//        }
//
//        return SwappingBlockchain(networkId: id) != nil
//    }
}
