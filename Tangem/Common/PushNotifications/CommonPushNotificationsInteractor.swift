//
//  CommonPushNotificationsInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class CommonPushNotificationsInteractor {
    private var isFeatureFlagEnabled: Bool { FeatureProvider.isAvailable(.pushNotifications) }

    private var didPostponeRequest = false

    private let pushNotificationsService: PushNotificationsService

    init(pushNotificationsService: any PushNotificationsService) {
        self.pushNotificationsService = pushNotificationsService
    }

    func isAvailable(in flow: PermissionRequestFlow) async -> Bool {
        // Apparently, short-circuit operators like `&&` don't work with async-await, and since we want to preserve
        // short-circuit semantics here - the first condition is checked using plain guard
        guard isFeatureFlagEnabled else {
            return false
        }

        return await pushNotificationsService.isAvailable
    }

    func allowRequest(in flow: PermissionRequestFlow) async {
        await pushNotificationsService.requestAuthorizationAndRegister()
    }

    func canPostponeRequest(in flow: PermissionRequestFlow) -> Bool {
        // [REDACTED_TODO_COMMENT]
        return true
    }

    func postponeRequest(in flow: PermissionRequestFlow) {
        // [REDACTED_TODO_COMMENT]
    }
}

// MARK: - Auxiliary types

extension CommonPushNotificationsInteractor {
    enum PermissionRequestFlow {
        enum NewUserState {
            /// User starts the app for the first time, accept TOS, etc.
            case welcomeOnboarding
            /// User adds first wallet to the app, performs backup, etc.
            case walletOnboarding
            /// User completed all onboarding procedures and using app normally.
            case normalUsage
        }

        case newUser(state: NewUserState)
        case existingUser
    }
}

// MARK: - Test extensions

extension CommonPushNotificationsInteractor {
    // [REDACTED_TODO_COMMENT]
    @available(*, deprecated, message: "Inject as a dependency instead")
    static let shared = CommonPushNotificationsInteractor(
        pushNotificationsService: CommonPushNotificationsService(application: .shared)
    )
}
