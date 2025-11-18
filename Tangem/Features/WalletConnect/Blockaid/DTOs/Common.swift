//
//  Common.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

extension BlockaidDTO {
    enum ResultType: String, Decodable {
        case malicious = "Malicious"
        case warning = "Warning"
        case benign = "Benign"
        case info = "Info"
        case error = "Error"
    }

    enum Status: String, Decodable {
        case success = "Success"
        case error = "Error"
    }

    enum Option: String, Encodable {
        case simulation
        case validation
        case gasEstimation = "gas_estimation"
    }

    struct Validation: Decodable {
        let status: Status?
        let resultType: ResultType
        let description: String?
        let reason: String?
        let error: String?
    }

    struct TransactionDetail: Decodable {
        let summary: String?
        @FlexibleDecimal var value: Decimal?
        @FlexibleDecimal var rawValue: Decimal?

        private enum CodingKeys: String, CodingKey {
            case summary
            case value
            case rawValue = "raw_value"
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            summary = try c.decodeIfPresent(String.self, forKey: .summary)
            _value = try c.decodeIfPresent(FlexibleDecimal.self, forKey: .value)
                ?? FlexibleDecimal(wrappedValue: nil)
            _rawValue = try c.decodeIfPresent(FlexibleDecimal.self, forKey: .rawValue)
                ?? FlexibleDecimal(wrappedValue: nil)
        }
    }

    struct Asset: Decodable {
        let type: String
        let address: String?
        let logoUrl: String?
        let name: String?
        let symbol: String?

        // ERC20-specific
        let chainName: String?
        let decimals: Int?
        let chainID: Int?
    }

    struct ExposureDetail: Decodable {
        @FlexibleDecimal var value: Decimal?
        let rawValue: String?

        private enum CodingKeys: String, CodingKey {
            case value
            case rawValue = "raw_value"
        }

        public init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            _value = try c.decodeIfPresent(FlexibleDecimal.self, forKey: .value)
                ?? FlexibleDecimal(wrappedValue: nil)
            rawValue = try c.decodeIfPresent(String.self, forKey: .rawValue)
        }
    }

    struct SpenderDetail: Decodable {
        let summary: String
        let exposure: [ExposureDetail]?
        let approval: String?
        let expiration: Date?
        let isApprovedForAll: Bool?
    }

    struct Exposure: Decodable {
        let assetType: String
        let asset: Asset
        let spenders: [String: SpenderDetail]?
    }

    struct Trace: Decodable {
        let type: String
        let traceType: String
        let owner: String?
        let spender: String?
        let asset: Asset
        let exposed: ExposureDetail?
        let fromAddress: String?
        let toAddress: String?
        let diff: TransactionDetail?
    }

    struct AddressDetail: Decodable {
        let nameTag: String?
        let contractName: String?
    }

    struct TransactionParams: Codable {
        let from: String
        let to: String
        let data: String
        let value: String
    }
}
