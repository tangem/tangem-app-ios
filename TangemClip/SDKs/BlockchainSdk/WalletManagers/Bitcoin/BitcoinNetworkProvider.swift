//
//  BitcoinNetworkProvider.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import Combine

struct BtcFee {
    let minimalSatoshiPerByte: Decimal
    let normalSatoshiPerByte: Decimal
    let prioritySatoshiPerByte: Decimal
}

struct BitcoinResponse {
    let balance: Decimal
    let hasUnconfirmed: Bool
    let txrefs: [BtcTx]
}

struct BtcTx {
    let tx_hash: String
    let tx_output_n: Int
    let value: UInt64
    let script: String
}

protocol BitcoinNetworkProvider: AnyObject {
    func getInfo(addresses: [String]) -> AnyPublisher<[BitcoinResponse], Error>
    func getInfo(address: String) -> AnyPublisher<BitcoinResponse, Error>
}


extension BitcoinNetworkProvider {
    func getInfo(addresses: [String]) -> AnyPublisher<[BitcoinResponse], Error> {
        .multiAddressPublisher(addresses: addresses, requestFactory: {
            self.getInfo(address: $0)
        })
    }
}
