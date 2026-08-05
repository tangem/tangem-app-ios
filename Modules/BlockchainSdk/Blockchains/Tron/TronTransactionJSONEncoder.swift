//
//  TronTransactionJSONEncoder.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import CryptoSwift

@preconcurrency import SwiftProtobuf // [REDACTED_TODO_COMMENT]

struct TronTransactionJSONEncoder {
    func encode(rawData: Protocol_Transaction.raw, signature: Data) throws -> String {
        let rawDataHex = try rawData.serializedData().hex()
        let transaction = SignedTransaction(
            txID: try rawData.serializedData().sha256().hex(),
            rawData: try makeRawData(from: rawData),
            rawDataHex: rawDataHex,
            signature: [signature.hex()]
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(transaction)

        guard let json = String(data: data, encoding: .utf8) else {
            throw BlockchainSdkError.failedToBuildTx
        }

        return json
    }

    private func makeRawData(from rawData: Protocol_Transaction.raw) throws -> RawData {
        RawData(
            contract: try rawData.contract.map(makeContract),
            expiration: rawData.expiration,
            feeLimit: rawData.feeLimit,
            refBlockBytes: rawData.refBlockBytes.hex(),
            refBlockHash: rawData.refBlockHash.hex(),
            timestamp: rawData.timestamp
        )
    }

    private func makeContract(from contract: Protocol_Transaction.Contract) throws -> Contract {
        switch contract.type {
        case .triggerSmartContract:
            let triggerContract = try Protocol_TriggerSmartContract(serializedBytes: contract.parameter.value)
            let value = Contract.Parameter.Value(
                ownerAddress: triggerContract.ownerAddress.hex(),
                contractAddress: triggerContract.contractAddress.hex(),
                data: triggerContract.data.hex()
            )

            return Contract(
                parameter: .init(
                    typeURL: contract.parameter.typeURL,
                    value: value
                ),
                type: "TriggerSmartContract"
            )
        default:
            throw BlockchainSdkError.failedToBuildTx
        }
    }
}

private extension TronTransactionJSONEncoder {
    struct SignedTransaction: Encodable {
        let txID: String
        let rawData: RawData
        let rawDataHex: String
        let signature: [String]

        enum CodingKeys: String, CodingKey {
            case txID
            case rawData = "raw_data"
            case rawDataHex = "raw_data_hex"
            case signature
        }
    }

    struct RawData: Encodable {
        let contract: [Contract]
        let expiration: Int64
        let feeLimit: Int64
        let refBlockBytes: String
        let refBlockHash: String
        let timestamp: Int64

        enum CodingKeys: String, CodingKey {
            case contract
            case expiration
            case feeLimit = "fee_limit"
            case refBlockBytes = "ref_block_bytes"
            case refBlockHash = "ref_block_hash"
            case timestamp
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(contract, forKey: .contract)
            try container.encode(expiration, forKey: .expiration)
            if feeLimit > 0 {
                try container.encode(feeLimit, forKey: .feeLimit)
            }
            try container.encode(refBlockBytes, forKey: .refBlockBytes)
            try container.encode(refBlockHash, forKey: .refBlockHash)
            try container.encode(timestamp, forKey: .timestamp)
        }
    }

    struct Contract: Encodable {
        let parameter: Parameter
        let type: String

        struct Parameter: Encodable {
            let typeURL: String
            let value: Value

            enum CodingKeys: String, CodingKey {
                case typeURL = "type_url"
                case value
            }

            struct Value: Encodable {
                let ownerAddress: String
                let contractAddress: String
                let data: String

                enum CodingKeys: String, CodingKey {
                    case ownerAddress = "owner_address"
                    case contractAddress = "contract_address"
                    case data
                }
            }
        }
    }
}
