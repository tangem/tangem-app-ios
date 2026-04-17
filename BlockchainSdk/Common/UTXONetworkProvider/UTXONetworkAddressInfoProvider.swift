//
//  UTXONetworkAddressInfoProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine

protocol UTXONetworkAddressInfoProvider: AnyObject, HostProvider {
    func getUnspentOutputs(address: String) -> AnyPublisher<[UnspentOutput], Error>
    func getTransactionInfo(hash: String, address: String) -> AnyPublisher<TransactionRecord, Error>
}

extension UTXONetworkAddressInfoProvider {
    /// Convenient method for multi-addresses wallet
    func getInfo(addresses: [Address]) -> AnyPublisher<[UTXONetworkProviderUpdatingResponse], any Error> {
        if addresses.isEmpty {
            return .anyFail(error: BlockchainSdkError.addressesIsEmpty)
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
