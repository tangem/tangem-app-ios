//
//  TronNetworkModels.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

struct TronGetChainParametersResponse: Decodable {
    struct TronChainParameter: Decodable {
        let key: String
        let value: Int?
    }

    let chainParameter: [TronChainParameter]
}

struct TronChainParameters {
    let sunPerEnergyUnit: Int
    let dynamicEnergyMaxFactor: Int
    let dynamicEnergyIncreaseFactor: Int
}

struct TronEnergyFeeData {
    let energyFee: Int
    let sunPerEnergyUnit: Int
}

struct TronAccountInfo {
    let balance: Decimal
    let tokenBalances: [Token: Decimal]
    let confirmedTransactionIDs: [String]
}

struct TronGetAccountRequest: Encodable {
    let address: String
    let visible: Bool
}

struct TronGetAccountResponse: Decodable {
    let balance: UInt64?
    /// We don't use this field but we can't have just one optional `balance` field
    /// Otherwise an empty JSON will conform to this structure
    let address: String
}

struct TronGetAccountInfoByAddressResponse: Decodable {
    let data: [Account]

    struct Account: Decodable {
        let address: String?
        let balance: UInt64?
        let trc20: [[String: String]]?
    }
}

struct TronAccountInfoByAddress {
    let balance: Decimal
    let tokenBalances: [String: Decimal]
}

struct TronGetAccountResourceResponse: Decodable {
    let freeNetUsed: Int?
    let freeNetLimit: Int
    let energyLimit: Decimal?
    let energyUsed: Decimal?

    enum CodingKeys: String, CodingKey {
        case freeNetUsed
        case freeNetLimit
        case energyLimit = "EnergyLimit"
        case energyUsed = "EnergyUsed"
    }
}

struct TronTransactionInfoRequest: Encodable {
    let value: String
}

struct TronTransactionInfoResponse: Decodable {
    let id: String
}

struct TronBlock: Decodable {
    struct BlockHeader: Decodable {
        struct RawData: Decodable {
            let number: Int64
            let txTrieRoot: String
            let witness_address: String
            let parentHash: String
            let version: Int32
            let timestamp: Int64
        }

        let raw_data: RawData
    }

    let block_header: BlockHeader
}

struct TronBroadcastRequest: Encodable {
    let transaction: String
}

struct TronBroadcastResponse: Decodable {
    let result: Bool
    let txid: String
}

struct TronTriggerSmartContractRequest: Encodable {
    let owner_address: String
    let contract_address: String
    let function_selector: String
    var fee_limit: UInt64? = nil
    let parameter: String
    let visible: Bool
}

/// Same `triggerconstantcontract` endpoint as `TronTriggerSmartContractRequest`, but for simulating
/// a call from raw calldata (e.g. a DEX swap in EVM tx format) instead of a known function selector.
struct TronTriggerSmartContractCallDataRequest: Encodable {
    let owner_address: String
    let contract_address: String
    let data: String
    let call_value: UInt64
    let visible: Bool
}

struct TronTriggerSmartContractResponse: Decodable {
    let constant_result: [String]
}

struct TronContractEnergyUsageResponse: Decodable {
    let energy_used: Int
}
