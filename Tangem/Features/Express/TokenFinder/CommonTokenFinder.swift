//
//  CommonTokenFinder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdk
import TangemExpress

class CommonTokenFinder: TokenFinder {
    @Injected(\.tangemApiService) var tangemApiService: TangemApiService

    private let supportedBlockchains: Set<Blockchain>

    init(supportedBlockchains: Set<Blockchain>) {
        self.supportedBlockchains = supportedBlockchains
    }

    func findToken(blockchainNetwork: BlockchainNetwork, contractAddress: String) async throws -> TokenItem {
        let blockchain = blockchainNetwork.blockchain

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

        guard let tokenItem = coinItem?.tokenItem else {
            throw Error.notFound
        }

        return tokenItem
    }
}

extension CommonTokenFinder {
    enum Error: LocalizedError {
        case unsupportedBlockchain
        case unknownNetworkId
        case notFound
    }
}
