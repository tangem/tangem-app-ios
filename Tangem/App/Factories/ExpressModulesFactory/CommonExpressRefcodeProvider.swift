//
//  CommonExpressRefcodeProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct CommonExpressRefcodeProvider: RefcodeProvider {
    private let cardInfo: CardInfo

    // MARK: - Init

    init(cardInfo: CardInfo) {
        self.cardInfo = cardInfo
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
        let config = UserWalletConfigFactory(cardInfo).makeConfig()
        guard let seed = config.userWalletIdSeed else {
            return nil
        }

        let userWalletId = UserWalletId(with: seed).stringValue

        // User wallet with ring
        if AppSettings.shared.userWalletIdsWithRing.contains(userWalletId) {
            return .ring
        }

        return nil
    }

    private func tryGetByBatchId() -> Refcode? {
        switch cardInfo.card.batchId {
        case "AF990015":
            return .partner
        case "BB000013":
            return .changeNow
        default:
            return nil
        }
    }

    private func tryGetByCardId() -> Refcode? {
        let cardId = cardInfo.card.cardId

        // ChangeNow stealth
        if let changeNowStealthRange = CardIdRange(start: "AF99001800554008", end: "AF99001800559994"),
           changeNowStealthRange.contains(cardId) {
            return .changeNow
        }

        return nil
    }
}

// [REDACTED_TODO_COMMENT]
private extension CommonExpressRefcodeProvider {
    struct CardIdRange {
        public let start: UInt64
        public let end: UInt64

        init?(start: String, end: String) {
            guard let startCardID = UInt64(start, radix: 16),
                  let endCardID = UInt64(end, radix: 16),
                  endCardID > startCardID else {
                return nil
            }

            self.start = startCardID
            self.end = endCardID
        }

         func contains(_ cardId: String) -> Bool {
            guard let value = UInt64(cardId, radix: 16) else {
                return false
            }

            let range = start...end
            return range.contains(value)
        }
    }
}
