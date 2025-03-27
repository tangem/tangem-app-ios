//
//  UTXONetworkProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine

protocol UTXONetworkProvider: AnyObject, HostProvider {
    func getInfo(address: String) -> AnyPublisher<UTXOResponse, Error>
    func getUnspentOutputs(address: String) -> AnyPublisher<[UnspentOutput], Error>
    func getTransactionInfo(hash: String, address: String) -> AnyPublisher<TransactionRecord, Error>

    func getFee() -> AnyPublisher<UTXOFee, Error>
    func send(transaction: String) -> AnyPublisher<TransactionSendResult, Error>
}

extension UTXONetworkProvider {
    /// Convenient method for multi-addresses wallet
    func getInfo(addresses: [Address]) -> AnyPublisher<[UTXONetworkProviderUpdatingResponse], any Error> {
        if addresses.isEmpty {
            return .anyFail(error: WalletError.addressesIsEmpty)
        }

        let publishers = addresses.map { address in
            getInfo(address: address.value)
                .map { UTXONetworkProviderUpdatingResponse(address: address, response: $0) }
        }

        return Publishers.MergeMany(publishers).collect().eraseToAnyPublisher()
    }

    /// Default implementation
    func getInfo(address: String) -> AnyPublisher<UTXOResponse, any Error> {
        getUnspentOutputs(address: address)
            .withWeakCaptureOf(self)
            .flatMap { provider, outputs in
                let pending = outputs.filter { !$0.isConfirmed }.map {
                    provider.getTransactionInfo(hash: $0.txId, address: address)
                }

                return Publishers.MergeMany(pending).collect()
                    .map { UTXOResponse(outputs: outputs, pending: $0) }
            }
            .eraseToAnyPublisher()
    }
}

struct UTXONetworkProviderUpdatingResponse {
    let address: Address
    let response: UTXOResponse
}
