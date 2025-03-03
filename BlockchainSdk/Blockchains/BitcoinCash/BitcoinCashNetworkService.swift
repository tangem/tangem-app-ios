//
//  BitcoinCashNetworkService.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine

class BitcoinCashNetworkService: MultiUTXONetworkProvider {
    override func getUnspentOutputs(address: String) -> AnyPublisher<[UnspentOutput], any Error> {
        super.getUnspentOutputs(address: address.removeBchPrefix())
    }

    override func getTransactionInfo(hash: String, address: String) -> AnyPublisher<TransactionRecord, any Error> {
        super.getTransactionInfo(hash: hash, address: address.removeBchPrefix())
    }
}
