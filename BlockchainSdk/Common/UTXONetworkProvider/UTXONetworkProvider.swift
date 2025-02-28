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
    // Default implementation
    func getInfo(address: String) -> AnyPublisher<UTXOResponse, any Error> {
        getUnspentOutputs(address: address)
            .withWeakCaptureOf(self)
            .flatMap { provider, outputs in
                let pending = outputs.filter { !$0.isConfirmed }.map {
                    provider.getTransactionInfo(hash: $0.hash, address: address)
                }

                return Publishers.MergeMany(pending).collect()
                    .withWeakCaptureOf(provider)
                    .tryMap { provider, transactions in
                        UTXOResponse(outputs: outputs, pending: transactions)
                    }
            }
            .eraseToAnyPublisher()
    }
}
