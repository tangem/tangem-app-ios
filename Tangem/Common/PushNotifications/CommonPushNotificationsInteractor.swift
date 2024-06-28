//
//  CommonPushNotificationsInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class CommonPushNotificationsInteractor {
    @AppStorageCompat(StorageKeys.didRequestAuthorization)
    private var didRequestAuthorization = false

    @AppStorageCompat(StorageKeys.numberOfRequestsPostponedByExistingUser)
    private var numberOfRequestsPostponedByExistingUser = 0

    @AppStorageCompat(StorageKeys.didPostponeAuthorizationRequestOnWalletOnboarding)
    private var didPostponeAuthorizationRequestOnWalletOnboarding = false

    @AppStorageCompat(StorageKeys.didPostponeAuthorizationRequestOnWelcomeOnboarding)
    private var didPostponeAuthorizationRequestOnWelcomeOnboarding = false

    private var didPostponeAuthorizationRequestOnWelcomeOnboardingInCurrentSession = false

    private var isFeatureFlagEnabled: Bool { FeatureProvider.isAvailable(.pushNotifications) }

    private let pushNotificationsService: PushNotificationsService

    init(pushNotificationsService: PushNotificationsService) {
        self.pushNotificationsService = pushNotificationsService
    }

    func isAvailable(in flow: PermissionRequestFlow) -> Bool {
        guard isFeatureFlagEnabled, !didRequestAuthorization else {
            return false
        }

        switch flow {
        case .newUser(state: .welcomeOnboarding):
            return !didPostponeAuthorizationRequestOnWelcomeOnboarding
        case .newUser(state: .walletOnboarding):
            return !didPostponeAuthorizationRequestOnWelcomeOnboardingInCurrentSession && !didPostponeAuthorizationRequestOnWalletOnboarding
        case .newUser(state: .afterLogin),
             .existingUser:
            // [REDACTED_TODO_COMMENT]
            return true
        }
    }

    func allowRequest(in flow: PermissionRequestFlow) async {
        await pushNotificationsService.requestAuthorizationAndRegister()
        runOnMain {
            didRequestAuthorization = true
        }
    }

    func canPostponeRequest(in flow: PermissionRequestFlow) -> Bool {
        switch flow {
        case .newUser(state: .welcomeOnboarding),
             .newUser(state: .walletOnboarding):
            return true
        case .newUser(state: .afterLogin):
            return false
        case .existingUser:
            // Only the first permissions authorization request can be postponed
            return numberOfRequestsPostponedByExistingUser == 0
        }
    }

    func postponeRequest(in flow: PermissionRequestFlow) {
        switch flow {
        case .newUser(state: .welcomeOnboarding):
            didPostponeAuthorizationRequestOnWelcomeOnboarding = true
            didPostponeAuthorizationRequestOnWelcomeOnboardingInCurrentSession = true
        case .newUser(state: .walletOnboarding):
            didPostponeAuthorizationRequestOnWalletOnboarding = true
        case .newUser(state: .afterLogin):
            break
        case .existingUser:
            numberOfRequestsPostponedByExistingUser += 1
        }
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
            case afterLogin
        }

        case newUser(state: NewUserState)
        case existingUser
    }

    private enum StorageKeys: String, RawRepresentable {
        case didRequestAuthorization = "did_request_push_notifications_authorization"
        case didPostponeAuthorizationRequestOnWelcomeOnboarding = "did_postpone_authorization_request_on_welcome_onboarding"
        case didPostponeAuthorizationRequestOnWalletOnboarding = "did_postpone_authorization_request_on_wallet_onboarding"
        case numberOfRequestsPostponedByExistingUser = "number_of_requests_postponed_by_existing_user"
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
