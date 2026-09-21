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
    case notEnoughReceivedAmount(minAmount: ReceivedAmountThreshold, reason: NotEnoughReceivedAmountReason)
    case tooMuchReceivedAmount(maxAmount: ReceivedAmountThreshold)
    case incompleteBackup(UserWalletInfo)
    case requiresTrustline
}

/// A threshold states the currency it is set in: a chain's own reserve is a token amount, while a partner's
/// limit is a dollar figure that any token can be swapped into.
enum ReceivedAmountThreshold: Hashable {
    case token(Decimal)
    case fiatUSD(Decimal)
}

enum NotEnoughReceivedAmountReason {
    /// The blockchain account does not exist yet and is created only by a large enough transfer.
    case accountReserve
    /// The receiving side credits nothing below a threshold of its own, e.g. a funded account.
    case receivingMinimum
}
