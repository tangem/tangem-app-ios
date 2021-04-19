//
//  CardanoNetworkService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol CardanoNetworkProvider {
    func getInfo(addresses: [String]) -> AnyPublisher<CardanoAddressResponse, Error>
    func send(transaction: Data) -> AnyPublisher<String, Error>
}

class CardanoNetworkService: MultiNetworkProvider<CardanoNetworkProvider>, CardanoNetworkProvider {
    func getInfo(addresses: [String]) -> AnyPublisher<CardanoAddressResponse, Error> {
        providerPublisher { provider in
            provider.getInfo(addresses: addresses)
        }
    }
    
    func send(transaction: Data) -> AnyPublisher<String, Error> {
        providerPublisher { provider in
            provider.send(transaction: transaction)
        }
    }
}

public struct CardanoAddressResponse {
    let balance: Decimal
    let recentTransactionsHashes: [String]
    let unspentOutputs: [CardanoUnspentOutput]
}

public struct CardanoUnspentOutput {
    let address: String
    let amount: Decimal
    let outputIndex: Int
    let transactionHash: String
}
