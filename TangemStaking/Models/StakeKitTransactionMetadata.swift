//
//  StakeKitTransactionMetadata.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

public struct StakeKitTransactionMetadata: StakingTransactionMetadata {
    public let id: String
    public let actionId: String
    public let type: String
    public let status: String
    public let stepIndex: Int
}
