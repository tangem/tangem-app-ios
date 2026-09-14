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
    case notEnoughReceivedAmount(minAmount: Decimal, reason: NotEnoughReceivedAmountReason)
    case incompleteBackup(UserWalletInfo)
    case requiresTrustline
}

enum NotEnoughReceivedAmountReason {
    /// The blockchain account does not exist yet and is created only by a large enough transfer.
    case accountReserve
    /// The receiving side credits nothing below a threshold of its own, e.g. a funded account.
    case receivingMinimum
}
