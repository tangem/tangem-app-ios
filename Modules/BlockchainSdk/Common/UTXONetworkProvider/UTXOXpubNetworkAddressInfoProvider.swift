//
//  UTXOXpubNetworkAddressInfoProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt

protocol UTXOXpubNetworkAddressInfoProvider: UTXONetworkAddressInfoProvider {
    func getInfo(xpub: String) -> AnyPublisher<UTXOXpubAddressesInfo, Error>
    func getUnspentOutputs(xpub: String) -> AnyPublisher<[UTXOUsedAddress: [UnspentOutput]], Error>
}

// MARK: - Convenience

extension UTXOXpubNetworkAddressInfoProvider {
    func getInfo(xpub: String) -> AnyPublisher<UTXOXpubNetworkProviderUpdatingResponse, Error> {
        Publishers
            .CombineLatest(getInfo(xpub: xpub), getUnspentOutputs(xpub: xpub))
            .withWeakCaptureOf(self)
            .flatMap { provider, combined in
                let (info, unspentOutputs) = combined

                let pendingPublishers = unspentOutputs.flatMap { address, outputs in
                    outputs.filter { !$0.isConfirmed }.map {
                        provider.getTransactionInfo(hash: $0.txId, address: address.address)
                    }
                }

                return Publishers.MergeMany(pendingPublishers).collect().map { pending in
                    UTXOXpubNetworkProviderUpdatingResponse(
                        info: info,
                        outputs: unspentOutputs,
                        pending: pending
                    )
                }
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - UTXOXpubNetworkAddressInfoProviderError

enum UTXOXpubNetworkAddressInfoProviderError: LocalizedError {
    case xpubNotSupported

    var errorDescription: String? {
        switch self {
        case .xpubNotSupported: "XPUB is not supported"
        }
    }
}

// MARK: - UTXOXpubNetworkProviderUpdatingResponse

struct UTXOXpubNetworkProviderUpdatingResponse {
    let info: UTXOXpubAddressesInfo
    let outputs: [UTXOUsedAddress: [UnspentOutput]]
    let pending: [TransactionRecord]
}
