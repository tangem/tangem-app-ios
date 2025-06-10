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
    }

    struct Metadata: Encodable {
        let domain: String
    }

    struct Validation: Decodable {
        let status: Status?
        let resultType: ResultType
        let description: String?
        let reason: String?
        let error: String?
    }

    struct TransactionDetail: Decodable {
        let summary: String
        @FlexibleDecimal var value: Decimal
        @FlexibleDecimal var rawValue: Decimal
    }

    struct Asset: Decodable {
        let type: String
        let chainName: String?
        let decimals: Int
        let chainID: Int?
        let logoURL: String?
        let name: String?
        let symbol: String?
    }

    struct ExposureDetail: Decodable {
        @FlexibleDecimal var value: Decimal
        let rawValue: String
    }

    struct SpenderDetail: Decodable {
        let summary: String
        let exposure: [ExposureDetail]
        let approval: String
        let expiration: Date
    }

    struct Exposure: Decodable {
        let assetType: String
        let asset: Asset
        let spenders: [String: SpenderDetail]
    }

    struct Trace: Decodable {
        let type: String
        let exposed: ExposureDetail
        let traceType: String
        let owner: String
        let spender: String
        let asset: Asset
    }

    struct AddressDetail: Decodable {
        let nameTag: String
        let contractName: String?
    }
}
