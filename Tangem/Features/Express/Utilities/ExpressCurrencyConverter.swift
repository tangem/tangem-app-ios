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
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private let supportedBlockchains: Set<Blockchain>

    init(supportedBlockchains: Set<Blockchain>) {
        self.supportedBlockchains = supportedBlockchains
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

        if let localToken = fetchLocalToken(blockchain: blockchain, contractAddress: contractAddress) {
            return .token(localToken, blockchainNetwork)
        }

        if let remoteToken = try await fetchRemoteToken(blockchain: blockchain, contractAddress: contractAddress) {
            return .token(remoteToken, blockchainNetwork)
        }

        throw Error.notFound
    }

    private func fetchLocalToken(
        blockchain: Blockchain,
        contractAddress: String
    ) -> Token? {
        return AccountWalletModelsAggregator
            .walletModels(from: userWalletRepository.models)
            .lazy
            .first { $0.tokenItem.blockchain == blockchain && $0.tokenItem.contractAddress == contractAddress }?
            .tokenItem
            .token
    }

    private func fetchRemoteToken(
        blockchain: Blockchain,
        contractAddress: String
    ) async throws -> Token? {
        let requestModel = CoinsList.Request(
            supportedBlockchains: Set([blockchain]),
            contractAddress: contractAddress
        )

        let response = try await tangemApiService
            .loadCoins(requestModel: requestModel)
            .async()

        return response
            .flatMap { $0.items }
            .lazy
            .first(where: { $0.blockchain.networkId == blockchain.networkId })?
            .token
    }
}

// MARK: - Auxiliary types

extension ExpressCurrencyConverter {
    enum Error: LocalizedError {
        case unsupportedBlockchain
        case notFound
    }
}
