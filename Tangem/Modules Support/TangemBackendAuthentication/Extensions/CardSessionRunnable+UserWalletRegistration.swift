//
//  CardSessionRunnable+UserWalletRegistration.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemSdk

extension CardSessionRunnable {
    func withUserWalletRegistration() -> UserWalletRegistrationTask<Self> {
        UserWalletRegistrationTask(wrapped: self)
    }
}
