//
//  CommonExpressRefcodeProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import TangemFoundation

struct CommonExpressRefcodeProvider: RefcodeProvider {
    private let userWalletId: UserWalletId
    private let batchId: String?
    private let cardId: String?

    // MARK: - Init

    init(
        userWalletId: UserWalletId,
        cardId: String?,
        batchId: String?
    ) {
        self.userWalletId = userWalletId
        self.cardId = cardId
        self.batchId = batchId
    }

    // MARK: - ExpressRefcodeProvider

    func getRefcode() -> Refcode? {
        if let refcode = tryGetByUserWalletId() {
            return refcode
        }

        if let refcode = tryGetByBatchId() {
            return refcode
        }

        if let refcode = tryGetByCardId() {
            return refcode
        }

        return nil
    }

    // MARK: - Private Implementation

    private func tryGetByUserWalletId() -> Refcode? {
        // User wallet with ring
        if AppSettings.shared.userWalletIdsWithRing.contains(userWalletId.stringValue) {
            return .ring
        }

        return nil
    }

    private func tryGetByBatchId() -> Refcode? {
        switch batchId {
        case "AF990015":
            return .partner
        case "BB000013":
            return .changeNow
        default:
            return nil
        }
    }

    private func tryGetByCardId() -> Refcode? {
        guard let cardId else { return nil }

        // ChangeNow stealth
        if let changeNowStealthRange = CardIdRange(start: "AF99001800554008", end: "AF99001800559994"),
           changeNowStealthRange.contains(cardId) {
            return .changeNow
        }

        return nil
    }
}
