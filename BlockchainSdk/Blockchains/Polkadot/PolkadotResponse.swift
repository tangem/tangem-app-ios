//
//  PolkadotResponse.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import ScaleCodec
import BigInt

struct PolkadotHeader: Swift.Codable {
    let number: String
}

struct PolkadotRuntimeVersion: Swift.Codable {
    let specName: String
    let specVersion: UInt32
    let transactionVersion: UInt32
}

struct PolkadotQueriedInfo: ScaleCodec.Decodable {
    let refTime: UInt64
    let proofSize: UInt64
    let classType: UInt8
    let partialFee: BigUInt

    init<D: ScaleCodec.Decoder>(from decoder: inout D) throws {
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
            let bytes: Data = try decoder.decode(.fixed(16))
            partialFee = BigUInt(littleEndian: bytes)
        default:
            throw BlockchainSdkError.failedToGetFee
        }
    }
}

struct PolkadotAccountInfo: ScaleCodec.Decodable {
    let nonce: UInt32
    let consumers: UInt32
    let providers: UInt32
    let sufficients: UInt32
    let data: PolkadotAccountData

    init<D: ScaleCodec.Decoder>(from decoder: inout D) throws {
        nonce = try decoder.decode()
        consumers = try decoder.decode()
        providers = try decoder.decode()
        sufficients = try decoder.decode()
        data = try decoder.decode()
    }
}

struct PolkadotAccountData: ScaleCodec.Decodable {
    var free: BigUInt
    // Fields below are yet unused, will be used when we will fix Polkadot
    // mapping completely, taking all those fields int account
    var reserved: BigUInt
    var miscFrozen: BigUInt
    var feeFrozen: BigUInt

    init<D: ScaleCodec.Decoder>(from decoder: inout D) throws {
        free = BigUInt(littleEndian: try decoder.decode(.fixed(16)))
        reserved = BigUInt(littleEndian: try decoder.decode(.fixed(16)))
        miscFrozen = BigUInt(littleEndian: try decoder.decode(.fixed(16)))
        feeFrozen = BigUInt(littleEndian: try decoder.decode(.fixed(16)))
    }
}
