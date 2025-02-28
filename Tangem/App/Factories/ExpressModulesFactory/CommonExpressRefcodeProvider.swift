//
//  CommonExpressRefcodeProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct CommonExpressRefcodeProvider: RefcodeProvider {
    private let userId: String
    private let batchId: String

    // MARK: - Init

    init(userId: String, batchId: String) {
        self.userId = userId
        self.batchId = batchId
    }

    // MARK: - ExpressRefcodeProvider

    func getRefcode() -> Refcode? {
        if isRingUserWallet(by: userId) {
            return .ring
        } else if let refcode = defineBatchRefcode() {
            return refcode
        }

        return nil
    }

    // MARK: - Private Implementation

    private func isRingUserWallet(by userId: String) -> Bool {
        AppSettings.shared.userWalletIdsWithRing.contains(userId)
    }

    private func defineBatchRefcode() -> Refcode? {
        Refcode.allCases.first(where: { $0.batchId == batchId })
    }
}
