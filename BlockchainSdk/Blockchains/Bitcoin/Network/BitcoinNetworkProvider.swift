//
//  BitcoinNetworkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol BitcoinNetworkProvider: AnyObject, HostProvider {
    func getInfo(addresses: [String]) -> AnyPublisher<[BitcoinResponse], Error>
    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error>
    func getFee() -> AnyPublisher<BitcoinFee, Error>
    func send(transaction: String) -> AnyPublisher<String, Error>
}

extension BitcoinNetworkProvider {
    func getInfo(addresses: [String]) -> AnyPublisher<[BitcoinResponse], Error> {
        .multiAddressPublisher(addresses: addresses, requestFactory: { [weak self] in
            self?.getInfo(address: $0) ?? .emptyFail
        })
    }

    func eraseToAnyBitcoinNetworkProvider() -> AnyBitcoinNetworkProvider {
        AnyBitcoinNetworkProvider(self)
    }
}

class AnyBitcoinNetworkProvider: BitcoinNetworkProvider {
    var host: String { provider.host }

    private let provider: BitcoinNetworkProvider

    init<P: BitcoinNetworkProvider>(_ provider: P) {
        self.provider = provider
    }

    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error> {
        provider.getInfo(address: address)
    }

    func getFee() -> AnyPublisher<BitcoinFee, Error> {
        provider.getFee()
    }

    func send(transaction: String) -> AnyPublisher<String, Error> {
        provider.send(transaction: transaction)
    }
}
