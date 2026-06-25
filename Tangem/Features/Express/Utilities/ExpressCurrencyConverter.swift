//
//  ExpressCurrencyConverter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemExpress
import TangemFoundation

struct ExpressCurrencyConverter {
    @Injected(\.tangemApiService) var tangemApiService: TangemApiService

    private let supportedBlockchains: Set<Blockchain>
    private let shouldPerformLocalLookup: Bool

    init(
        supportedBlockchains: Set<Blockchain>,
        shouldPerformLocalLookup: Bool
    ) {
        self.supportedBlockchains = supportedBlockchains
        self.shouldPerformLocalLookup = shouldPerformLocalLookup
    }

    func convert(
        expressCurrency: ExpressCurrency,
        in blockchainNetwork: BlockchainNetwork
    ) async throws -> TokenItem {
        let blockchain = blockchainNetwork.blockchain
        let contractAddress = expressCurrency.contractAddress

        guard supportedBlockchains.contains(blockchain) else {
            throw Error.unsupportedBlockchain
        }

        if contractAddress == ExpressConstants.coinContractAddress {
            return .blockchain(blockchainNetwork)
        }

        let requestModel = CoinsList.Request(
            supportedBlockchains: Set([blockchain]),
            contractAddress: contractAddress
        )

        let response = try await tangemApiService
            .loadCoins(requestModel: requestModel)
            .async()

        let items = response.flatMap { $0.items }
        let coinItem = items.first(where: { $0.blockchain.networkId == blockchain.networkId })

        guard let token = coinItem?.token else {
            throw Error.notFound
        }

        return .token(token, blockchainNetwork)
    }
}

// MARK: - Auxiliary types

extension ExpressCurrencyConverter {
    enum Error: LocalizedError {
        case unsupportedBlockchain
        case notFound
    }
}
