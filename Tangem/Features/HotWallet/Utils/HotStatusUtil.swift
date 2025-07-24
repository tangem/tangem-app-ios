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
        // userWalletModel.config.getFeatureAvailability(.accessCode) == .available
        false
    }

    var isBackupFeatureAvailable: Bool {
        // [REDACTED_TODO_COMMENT]
        // userWalletModel.config.getFeatureAvailability(.backup) == .available
        false
    }

    var isSeedPhraseBackupNeeded: Bool {
        // [REDACTED_TODO_COMMENT]
        true
    }

    var isAccessCodeBackupNeeded: Bool {
        !isAccessCodeSet
    }

    var isAccessCodeSet: Bool {
        // [REDACTED_TODO_COMMENT]
        false
    }

    // [REDACTED_TODO_COMMENT]
    var isUserWalletHot: Bool {
        false
    }

    private let userWalletModel: UserWalletModel

    init(userWalletModel: UserWalletModel) {
        self.userWalletModel = userWalletModel
    }
}
