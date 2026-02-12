//
//  AuthWalletView+EnvironmentValues.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import SwiftUI
import TangemFoundation

private struct UnlockingUserWalletIdKey: EnvironmentKey {
    static var defaultValue: UserWalletId?
}

extension EnvironmentValues {
    var unlockingUserWalletId: UserWalletId? {
        get { self[UnlockingUserWalletIdKey.self] }
        set { self[UnlockingUserWalletIdKey.self] = newValue }
    }
}
