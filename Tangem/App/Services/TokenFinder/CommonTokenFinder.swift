//
//  CommonTokenFinder.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import BlockchainSdkLocal
import TangemExpress

class CommonTokenFinder: TokenFinder {
    @Injected(\.tangemApiService) var tangemApiService: TangemApiService

    private let supportedBlockchains: Set<Blockchain>

    init(supportedBlockchains: Set<Blockchain>) {
        self.supportedBlockchains = supportedBlockchains
    }

    func findToken(contractAddress: String, networkId: String) async throws -> TokenItem {
        guard let blockchain = supportedBlockchains.first(where: { $0.networkId == networkId }) else {
            throw Error.unknownNetworkId
        }

        if contractAddress == ExpressConstants.coinContractAddress {
            return .blockchain(.init(blockchain, derivationPath: nil))
        }

        let requestModel = CoinsList.Request(
            supportedBlockchains: Set([blockchain]),
            contractAddress: contractAddress
        )

        let response = try await tangemApiService
            .loadCoins(requestModel: requestModel)
            .async()

        guard let tokenItem = response.first?.items.first(where: { $0.blockchain.networkId == blockchain.networkId })?.tokenItem else {
            throw Error.notFound
        }

        return tokenItem
    }
}

extension CommonTokenFinder {
    enum Error: Swift.Error {
        case unknownNetworkId
        case notFound
    }
}
