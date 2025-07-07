//
//  CommonHotAccessCodeValidator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

final class CommonHotAccessCodeValidator {
    // [REDACTED_TODO_COMMENT]
    typealias UserWalletId = String

    private let userWalletId: UserWalletId

    init(userWalletId: UserWalletId) {
        self.userWalletId = userWalletId
    }
}

// MARK: - CommonHotAccessCodeValidator

extension CommonHotAccessCodeValidator: HotAccessCodeValidator {
    func isValid(accessCode: String) -> Bool {
        // [REDACTED_TODO_COMMENT]
        accessCode == "111111"
    }
}
