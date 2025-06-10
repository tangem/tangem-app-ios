//
//  BlockchainScanResult.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk

struct BlockaidChainScanResult {
    let validationStatus: ValidationStatus?
    let assetsDiff: AssetDiff?
    let approvals: [Asset]?

    enum ValidationStatus: String {
        case malicious = "Malicious"
        case warning = "Warning"
        case benign = "Benign"
    }

    struct AssetDiff {
        let `in`: [Asset]
        let out: [Asset]
    }

    struct Asset {
        let assetType: String
        let amount: Decimal
        let symbol: String?
        let logoURL: URL?
    }
}
