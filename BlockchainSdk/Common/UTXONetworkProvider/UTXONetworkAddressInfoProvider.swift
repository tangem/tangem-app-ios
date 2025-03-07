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
