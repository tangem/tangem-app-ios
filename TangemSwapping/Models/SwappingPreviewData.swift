//
//  SwappingPreviewData.swift
//  TangemSwapping
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

public struct SwappingPreviewData {
    public let expectedAmount: Decimal

    public let isPermissionRequired: Bool
    public let hasPendingTransaction: Bool
    public let isEnoughAmountForSwapping: Bool

    public init(
        expectedAmount: Decimal,
        isPermissionRequired: Bool,
        hasPendingTransaction: Bool,
        isEnoughAmountForSwapping: Bool
    ) {
        self.expectedAmount = expectedAmount
        self.isPermissionRequired = isPermissionRequired
        self.hasPendingTransaction = hasPendingTransaction
        self.isEnoughAmountForSwapping = isEnoughAmountForSwapping
    }
}
