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
    @Injected(\.transactionHistoryAuxDataRepository) private var auxDataRepository: TransactionHistoryAuxDataRepository

    // [REDACTED_TODO_COMMENT]
    @available(iOS, deprecated: 100000.0, message: "To be removed, do not use")
    @Injected(\.tangemApiService) private var tangemApiService: TangemApiService

    // [REDACTED_TODO_COMMENT]
    @available(iOS, deprecated: 100000.0, message: "To be removed, do not use")
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private let supportedBlockchains: Set<Blockchain>

    init(supportedBlockchains: Set<Blockchain>) {
        self.supportedBlockchains = supportedBlockchains
    }

    func convert(
        expressCurrency: ExpressCurrency,
        in blockchainNetwork: BlockchainNetwork
    ) async throws -> TokenItem {
        guard supportedBlockchains.contains(blockchainNetwork.blockchain) else {
            throw Error.unsupportedBlockchain
        }

        guard FeatureProvider.isAvailable(.transactionHistoryV2) else {
            // Converting w/o database access/lookup
            return try await convertWithoutAuxData(expressCurrency: expressCurrency, in: blockchainNetwork)
        }

        guard let tokenItem = await auxDataRepository.cryptoCurrency(
            for: expressCurrency,
            supportedBlockchains: supportedBlockchains
        ) else {
            throw Error.notFound
        }

        // `TransactionHistoryAuxDataRepository` always returns a `TokenItem` with no derivation path,
        // so we have to enrich it with the caller's network
        return tokenItem.with(blockchainNetwork: blockchainNetwork)
    }
}

// MARK: - Legacy implementation

// [REDACTED_TODO_COMMENT]
@available(iOS, deprecated: 100000.0, message: "To be removed, do not use")
private extension ExpressCurrencyConverter {
    func convertWithoutAuxData(
        expressCurrency: ExpressCurrency,
        in blockchainNetwork: BlockchainNetwork
    ) async throws -> TokenItem {
        let blockchain = blockchainNetwork.blockchain
        let contractAddress = expressCurrency.contractAddress

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

    func fetchLocalToken(
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

    func fetchRemoteToken(
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
