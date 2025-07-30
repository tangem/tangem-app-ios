//
//  HotStatusUtil.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

struct HotStatusUtil {
    var isAccessCodeFeatureAvailable: Bool {
        // [REDACTED_TODO_COMMENT]
        false
    }

    var isBackupFeatureAvailable: Bool {
        // [REDACTED_TODO_COMMENT]
        false
    }

    var isBackupNeeded: Bool {
        // [REDACTED_TODO_COMMENT]
        true
    }

    var isAccessCodeNeeded: Bool {
        // [REDACTED_TODO_COMMENT]
        true
    }

    // [REDACTED_TODO_COMMENT]
    var isAccessCodeCreated: Bool {
        // [REDACTED_TODO_COMMENT]
        false
    }

    var isAccessCodeRequired: Bool {
        // [REDACTED_TODO_COMMENT]
        false
    }

    private let userWalletModel: UserWalletModel

    init(userWalletModel: UserWalletModel) {
        self.userWalletModel = userWalletModel
    }
}
