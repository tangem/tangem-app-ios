//
//  MobileAccessCodeStatusUtil.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum MobileAccessCodeStatusUtil {
    static func isAccessCodeNeeded(config: UserWalletConfig) -> Bool {
        guard config.hasFeature(.userWalletAccessCode) else {
            return false
        }

        switch config.userWalletAccessCodeStatus {
        case .none:
            return true
        case .set:
            return false
        case .skipped:
            return false
        }
    }
}
