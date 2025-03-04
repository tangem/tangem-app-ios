//
//  MultiUTXONetworkProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

// Wrapper to support a switch between providers
class MultiUTXONetworkProvider: MultiNetworkProvider, UTXONetworkProvider {
    var providers: [AnyUTXONetworkProvider]
    var currentProviderIndex: Int = 0

    init(providers: [Provider]) {
        self.providers = providers
    }

    init(providers: [UTXONetworkProvider]) {
        self.providers = providers.map { AnyUTXONetworkProvider(provider: $0) }
    }

    func getUnspentOutputs(address: String) -> AnyPublisher<[UnspentOutput], any Error> {
        providerPublisher { $0.getUnspentOutputs(address: address) }
    }

    func getTransactionInfo(hash: String, address: String) -> AnyPublisher<TransactionRecord, any Error> {
        providerPublisher { $0.getTransactionInfo(hash: hash, address: address) }
    }

    func getFee() -> AnyPublisher<UTXOFee, any Error> {
        providerPublisher { $0.getFee() }
    }

    func send(transaction: String) -> AnyPublisher<TransactionSendResult, any Error> {
        providerPublisher { $0.send(transaction: transaction) }
    }
}

// MARK: - AnyUTXONetworkProvider

extension MultiUTXONetworkProvider {
    // Wrapper to conform `MultiNetworkProvider.Provider`
    class AnyUTXONetworkProvider: UTXONetworkProvider {
        private let provider: UTXONetworkProvider

        init(provider: UTXONetworkProvider) {
            self.provider = provider
        }

        var host: String { provider.host }

        func getUnspentOutputs(address: String) -> AnyPublisher<[UnspentOutput], any Error> {
            provider.getUnspentOutputs(address: address)
        }

        func getTransactionInfo(hash: String, address: String) -> AnyPublisher<TransactionRecord, any Error> {
            provider.getTransactionInfo(hash: hash, address: address)
        }

        func getFee() -> AnyPublisher<UTXOFee, any Error> {
            provider.getFee()
        }

        func send(transaction: String) -> AnyPublisher<TransactionSendResult, any Error> {
            provider.send(transaction: transaction)
        }
    }
}
