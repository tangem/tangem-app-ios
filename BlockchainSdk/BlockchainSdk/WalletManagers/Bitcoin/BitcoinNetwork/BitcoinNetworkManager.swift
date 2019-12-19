//
//  BitcoinNetwork.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2019 Tangem AG. All rights reserved.
//

import Foundation
import Moya
import Combine

struct BtcFee {
    let minimalKb: Decimal
    let normalKb: Decimal
    let priorityKb: Decimal
}

struct BitcoinResponse {
    let balance: Decimal
    let unconfirmed_balance: Int
    let txrefs: [BtcTx]
}

struct BtcTx {
    let tx_hash: String
    let tx_output_n: Int
    let value: UInt64
}

enum BitcoinNetworkApi {
    case main
    case blockcypher
}

//class BitcoinNetworkManager {
//    var networkApi: BitcoinNetworkApi = .main
//    let blockchainInfoProvider = MoyaProvider<BlockchainInfoTarget>()
//    let estimateFeeProvider = MoyaProvider<EstimateFeeTarget>()
//    let blockcypherProvider = MoyaProvider<BlockcypherTarget>()
//
//    func getInfo() -> AnyPublisher<BitcoinResponse, Error> {
//
//    }
//}
