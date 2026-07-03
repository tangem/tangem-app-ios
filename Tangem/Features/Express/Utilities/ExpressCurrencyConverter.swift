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

struct ExpressCurrencyConverter {
    @Injected(\.transactionHistoryAuxDataRepository) private var auxDataRepository: TransactionHistoryAuxDataRepository

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

// MARK: - Auxiliary types

extension ExpressCurrencyConverter {
    enum Error: LocalizedError {
        case unsupportedBlockchain
        case notFound
    }
}
