//
//  PolkadotResponse.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import ScaleCodec

struct PolkadotHeader: Codable {
    let number: String
}

struct PolkadotRuntimeVersion: Codable {
    let specName: String
    let specVersion: UInt32
    let transactionVersion: UInt32
}

struct PolkadotQueriedInfo: ScaleDecodable {
    let refTime: UInt64
    let proofSize: UInt64
    let classType: UInt8
    let partialFee: BigUInt

    init(from decoder: any ScaleCodec.ScaleDecoder) throws {
        refTime = try decoder.decode(.compact)
        proofSize = try decoder.decode(.compact)
        classType = try decoder.decode()

        // RPC APIs for Bittensor are returning shortened response to `TransactionPaymentApi_query_info`
        // And result for `partialFee` will UInt64 instead of UInt128 for rest APIs
        switch decoder.length {
        case 8:
            let fee: UInt64 = try decoder.decode()
            partialFee = .init(fee)
        case 16:
            partialFee = try decoder.decode(.b128)
        default:
            throw WalletError.failedToGetFee
        }
    }
}

struct PolkadotAccountInfo: ScaleDecodable {
    let nonce: UInt32
    let consumers: UInt32
    let providers: UInt32
    let sufficients: UInt32
    let data: PolkadotAccountData

    init(from decoder: ScaleDecoder) throws {
        nonce = try decoder.decode()
        consumers = try decoder.decode()
        providers = try decoder.decode()
        sufficients = try decoder.decode()
        data = try decoder.decode()
    }
}

struct PolkadotAccountData: ScaleDecodable {
    init(from decoder: ScaleDecoder) throws {
        free = try decoder.decode(BigUInt.self, .b256)
    }

    var free: BigUInt
}
