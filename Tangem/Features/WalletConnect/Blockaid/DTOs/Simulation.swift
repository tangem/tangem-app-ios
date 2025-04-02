//
//  Simulation.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

extension BlockaidDTO {
    struct Simulation: Decodable {
        let status: Status
        let assetsDiffs: [String: [AssetDiff]]
        let exposures: [String: [Exposure]]
        let addressDetails: [String: AddressDetail]
        let accountSummary: AccountSummary
        let error: String?
        let errorDetails: String?
    }
    
    struct AssetDiff: Decodable {
        struct BalanceChange: Decodable {
            let usdPrice: Decimal
            let value: Decimal
            let rawValue: String
        }

        struct TransactionDetail: Decodable {
            let usdPrice: Decimal
            let summary: String
            let value: Decimal
            let rawValue: String
        }

        let assetType: String
        let asset: Asset
        let `in`: [TransactionDetail]
        let out: [TransactionDetail]
        let balanceChanges: [String: BalanceChange]?
    }
    
    struct Asset: Decodable {
        let type: String
        let chainName: String?
        let decimals: Int
        let chainID: Int?
        let logoURL: String
        let name: String
        let symbol: String
    }
    
    struct ExposureDetail: Decodable {
        let value: Decimal
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

    struct AccountSummary: Decodable {
        let assetsDiffs: [AssetDiff]
        let traces: [Trace]
        let exposures: [Exposure]
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
