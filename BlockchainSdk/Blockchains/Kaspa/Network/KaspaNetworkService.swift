//
//  KaspaNetworkService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class KaspaNetworkService: MultiNetworkProvider {
    let providers: [KaspaNetworkProvider]
    var currentProviderIndex: Int = 0
    let blockchainName: String = Blockchain.kaspa(testnet: false).displayName

    init(providers: [KaspaNetworkProvider]) {
        self.providers = providers
    }

    func send(transaction: KaspaDTO.Send.Request) -> AnyPublisher<KaspaDTO.Send.Response, Error> {
        providerPublisher { $0.send(transaction: transaction) }
    }

    func mass(data: KaspaDTO.Send.Request.Transaction) -> AnyPublisher<KaspaDTO.Mass.Response, Error> {
        providerPublisher { $0.mass(data: data) }
    }

    func feeEstimate() -> AnyPublisher<KaspaDTO.EstimateFee.Response, Error> {
        providerPublisher { $0.feeEstimate() }
    }
}

// MARK: - UTXONetworkAddressInfoProvider

extension KaspaNetworkService: UTXONetworkAddressInfoProvider {
    func getInfo(xpub: String) -> AnyPublisher<UTXOXpubInfo, any Error> {
        .anyFail(error: UTXONetworkAddressInfoProviderError.xpubNotSupported)
    }

    func getUnspentOutputs(address: String) -> AnyPublisher<[UnspentOutput], any Error> {
        providerPublisher { $0.getUnspentOutputs(address: address) }
    }

    func getTransactionInfo(hash: String, address: String) -> AnyPublisher<TransactionRecord, any Error> {
        providerPublisher { $0.getTransactionInfo(hash: hash, address: address) }
    }
}
