//
//  HotAccessCodeSkipHelper.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemFoundation

enum HotAccessCodeSkipHelper {
    static func has(userWalletId: UserWalletId) -> Bool {
        let id = userWalletId.stringValue
        return AppSettings.shared.userWalletIdsWithSkippedAccessCode.contains(id)
    }

    static func append(userWalletId: UserWalletId) {
        let id = userWalletId.stringValue
        AppSettings.shared.userWalletIdsWithSkippedAccessCode.appendIfNotContains(id)
    }

    static func remove(userWalletId: UserWalletId) {
        let id = userWalletId.stringValue
        AppSettings.shared.userWalletIdsWithSkippedAccessCode.removeAll { $0 == id }
    }
}
