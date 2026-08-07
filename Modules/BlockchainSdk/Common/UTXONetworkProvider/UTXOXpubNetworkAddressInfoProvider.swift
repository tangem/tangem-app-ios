//
//  UTXOXpubNetworkAddressInfoProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt

protocol UTXOXpubNetworkAddressInfoProvider: UTXONetworkAddressInfoProvider {
    func getInfo(xpub: UTXOXpubScriptType) -> AnyPublisher<UTXOXpubAddressesInfo, Error>
    func getUnspentOutputs(xpub: UTXOXpubScriptType) -> AnyPublisher<[UTXOUsedAddress: [UnspentOutput]], Error>
}

// MARK: - Convenience

extension UTXOXpubNetworkAddressInfoProvider {
    /// Convenient method for multi-xpub wallet
    func getInfo(xpubs: [UTXOXpubScriptType]) -> AnyPublisher<[UTXOXpubNetworkProviderUpdatingResponse], Error> {
        if xpubs.isEmpty {
            return .anyFail(error: BlockchainSdkError.addressesIsEmpty)
        }

        let publishers: [AnyPublisher<UTXOXpubNetworkProviderUpdatingResponse, Error>] = xpubs.map { xpub in
            getInfo(xpub: xpub)
        }

        return Publishers.MergeMany(publishers).collect().eraseToAnyPublisher()
    }

    func getInfo(xpub: UTXOXpubScriptType) -> AnyPublisher<UTXOXpubNetworkProviderUpdatingResponse, Error> {
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
