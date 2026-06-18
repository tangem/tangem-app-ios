//
//  PushNotificationsAllowanceBootstrapPolicy.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

enum PushNotificationsAllowanceBootstrapPolicy {
    static func hasNotCompletedOnboarding(userWalletId: UserWalletId) -> Bool {
        !AppSettings.shared.allowanceUserWalletIdTransactionsPush.contains(userWalletId.stringValue)
    }

    static func isEligibleForBootstrap(userWalletId: UserWalletId, isSystemPushAuthorized: Bool) -> Bool {
        isSystemPushAuthorized && hasNotCompletedOnboarding(userWalletId: userWalletId)
    }

    static func hasNotCompletedOnboardingPublisher(userWalletId: UserWalletId) -> AnyPublisher<Bool, Never> {
        AppSettings.shared
            .$allowanceUserWalletIdTransactionsPush
            .map { allowanceWalletIds in
                !allowanceWalletIds.contains(userWalletId.stringValue)
            }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    @MainActor
    static func markOnboardingCompleted(userWalletId: UserWalletId) {
        guard hasNotCompletedOnboarding(userWalletId: userWalletId) else {
            return
        }

        AppSettings.shared.allowanceUserWalletIdTransactionsPush.append(userWalletId.stringValue)
    }

    @MainActor
    static func markOnboardingCompleted(userWalletIds: [UserWalletId]) {
        userWalletIds.forEach(markOnboardingCompleted(userWalletId:))
    }
}
