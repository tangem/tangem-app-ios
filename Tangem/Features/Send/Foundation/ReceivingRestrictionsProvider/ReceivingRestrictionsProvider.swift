//
//  ReceivingRestrictionsProvider.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

protocol ReceivingRestrictionsProvider {
    var isRestrictionKnown: Bool { get }

    func restriction(expectAmount: Decimal) async throws -> ReceivedRestriction?
}

enum ReceivingRestrictionsError: String, LocalizedError {
    case restrictionsDataUnavailable

    var errorDescription: String? { rawValue }
}

enum ReceivedRestriction {
    case notEnoughReceivedAmount(minAmount: Decimal)
    case incompleteBackup(UserWalletInfo)
    case requiresTrustline
}
