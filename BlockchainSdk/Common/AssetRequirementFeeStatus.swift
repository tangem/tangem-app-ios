//
//  AssetRequirementFeeStatus.swift
//  BlockchainSdk
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

public enum AssetRequirementFeeStatus {
    case sufficient
    case insufficient(missingAmount: String)
}
