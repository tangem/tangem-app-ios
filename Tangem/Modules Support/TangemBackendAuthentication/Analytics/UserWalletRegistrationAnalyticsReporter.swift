//
//  UserWalletRegistrationAnalyticsReporter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemFoundation
import TangemBackendAuthentication

struct UserWalletRegistrationAnalyticsReporter {
    func reportResult(_ result: UserWalletRegistrationResult, id: UserWalletId) {
        guard result == .registered else {
            return
        }

        Analytics.log(.backendAuthWalletLinked, contextParams: .userWallet(id))
    }

    func reportFailure(walletType: Analytics.ParameterValue, stage: Analytics.ParameterValue, reason: String, id: UserWalletId) {
        Analytics.log(
            event: .backendAuthWalletRegistrationFailed,
            params: [
                .walletType: walletType.rawValue,
                .stage: stage.rawValue,
                .reason: reason,
            ],
            contextParams: .userWallet(id)
        )
    }
}
