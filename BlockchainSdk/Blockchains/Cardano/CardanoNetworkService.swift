//
//  CardanoNetworkService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol CardanoNetworkProvider: HostProvider {
    func getInfo(addresses: [String], tokens: [Token]) -> AnyPublisher<CardanoAddressResponse, Error>
    func send(transaction: Data) -> AnyPublisher<String, Error>
}

extension CardanoNetworkProvider {
    func eraseToAnyCardanoNetworkProvider() -> AnyCardanoNetworkProvider {
        AnyCardanoNetworkProvider(self)
    }
}

class AnyCardanoNetworkProvider: CardanoNetworkProvider {
    var host: String { provider.host }

    private let provider: CardanoNetworkProvider

    init<P: CardanoNetworkProvider>(_ provider: P) {
        self.provider = provider
    }

    func getInfo(addresses: [String], tokens: [Token]) -> AnyPublisher<CardanoAddressResponse, Error> {
        provider.getInfo(addresses: addresses, tokens: tokens)
    }

    func send(transaction: Data) -> AnyPublisher<String, Error> {
        provider.send(transaction: transaction)
    }
}

class CardanoNetworkService: MultiNetworkProvider, CardanoNetworkProvider {
    let providers: [AnyCardanoNetworkProvider]
    var currentProviderIndex: Int = 0
    let blockchainName: String = Blockchain.cardano(extended: false).displayName

    init(providers: [AnyCardanoNetworkProvider]) {
        self.providers = providers
    }

    func getInfo(addresses: [String], tokens: [Token]) -> AnyPublisher<CardanoAddressResponse, Error> {
        providerPublisher { $0.getInfo(addresses: addresses, tokens: tokens) }
    }

    func send(transaction: Data) -> AnyPublisher<String, Error> {
        providerPublisher { $0.send(transaction: transaction) }
    }
}
