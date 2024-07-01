//
//  CommonPushNotificationsInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class CommonPushNotificationsInteractor {
    @AppStorageCompat(StorageKeys.canRequestAuthorization)
    private var canRequestAuthorization = true

    /// Note: - Updated only in `.newUser(state: .walletOnboarding)` and `.existingUser` flows.
    @AppStorageCompat(StorageKeys.postponedAuthorizationRequestLaunchCount)
    private var postponedAuthorizationRequestLaunchCount: Int? = nil

    /// Note: - Updated only in `.newUser(state: .walletOnboarding)` and `.existingUser` flows.
    @AppStorageCompat(StorageKeys.postponedAuthorizationRequestDate)
    private var postponedAuthorizationRequestDate: Date? = nil

    @AppStorageCompat(StorageKeys.numberOfRequestsPostponedByExistingUser)
    private var numberOfRequestsPostponedByExistingUser = 0

    @AppStorageCompat(StorageKeys.didPostponeAuthorizationRequestOnWalletOnboarding)
    private var didPostponeAuthorizationRequestOnWalletOnboarding = false

    @AppStorageCompat(StorageKeys.didPostponeAuthorizationRequestOnWelcomeOnboarding)
    private var didPostponeAuthorizationRequestOnWelcomeOnboarding = false

    private var didPostponeAuthorizationRequestOnWelcomeOnboardingInCurrentSession = false

    private var currentLaunchCount: Int { AppSettings.shared.numberOfLaunches }

    private var isFeatureFlagEnabled: Bool { FeatureProvider.isAvailable(.pushNotifications) }

    private let pushNotificationsService: PushNotificationsService

    init(pushNotificationsService: PushNotificationsService) {
        self.pushNotificationsService = pushNotificationsService
    }

    func isAvailable(in flow: PermissionRequestFlow) -> Bool {
        guard
            isFeatureFlagEnabled,
            canRequestAuthorization
        else {
            return false
        }

        switch flow {
        case .newUser(state: .welcomeOnboarding):
            return !didPostponeAuthorizationRequestOnWelcomeOnboarding
        case .newUser(state: .walletOnboarding):
            return !didPostponeAuthorizationRequestOnWelcomeOnboardingInCurrentSession
                && !didPostponeAuthorizationRequestOnWalletOnboarding
        case .newUser(state: .afterLogin),
             .existingUser:
            guard
                let postponedAuthorizationRequestLaunchCount,
                let postponedAuthorizationRequestDate
            else {
                return true
            }

            let launchCountSinceLastPostponedRequest = postponedAuthorizationRequestLaunchCount
                + Constants.finalAuthorizationRequestNumberOfLaunchesDiff

            let timeIntervalSinceLastPostponedRequest = abs(postponedAuthorizationRequestDate.timeIntervalSinceNow)

            return currentLaunchCount >= launchCountSinceLastPostponedRequest
                && timeIntervalSinceLastPostponedRequest >= Constants.finalAuthorizationRequestTimeIntervalDiff
        }
    }

    func allowRequest(in flow: PermissionRequestFlow) async {
        await pushNotificationsService.requestAuthorizationAndRegister()
        runOnMain {
            canRequestAuthorization = false
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
            saveLaunchCountAndDateOfPostponedRequest()
            didPostponeAuthorizationRequestOnWelcomeOnboarding = true
            didPostponeAuthorizationRequestOnWelcomeOnboardingInCurrentSession = true
        case .newUser(state: .walletOnboarding):
            saveLaunchCountAndDateOfPostponedRequest()
            didPostponeAuthorizationRequestOnWalletOnboarding = true
        case .newUser(state: .afterLogin):
            // Stop all future authorization requests
            canRequestAuthorization = false
        case .existingUser:
            saveLaunchCountAndDateOfPostponedRequest()
            numberOfRequestsPostponedByExistingUser += 1
            // Stop all future authorization requests if the user postpones the request for the 2nd time
            if numberOfRequestsPostponedByExistingUser > 1 {
                canRequestAuthorization = false
            }
        }
    }

    private func saveLaunchCountAndDateOfPostponedRequest() {
        postponedAuthorizationRequestLaunchCount = currentLaunchCount
        postponedAuthorizationRequestDate = .now
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
}

// MARK: - Constants

private extension CommonPushNotificationsInteractor {
    enum StorageKeys: String, RawRepresentable {
        case canRequestAuthorization = "can_request_authorization"
        case didPostponeAuthorizationRequestOnWelcomeOnboarding = "did_postpone_authorization_request_on_welcome_onboarding"
        case didPostponeAuthorizationRequestOnWalletOnboarding = "did_postpone_authorization_request_on_wallet_onboarding"
        case numberOfRequestsPostponedByExistingUser = "number_of_requests_postponed_by_existing_user"
        case postponedAuthorizationRequestLaunchCount = "postponed_authorization_request_launch_count"
        case postponedAuthorizationRequestDate = "postponed_authorization_request_date"
    }

    enum Constants {
        // Five active sessions.
        static let finalAuthorizationRequestNumberOfLaunchesDiff = 5
        /// Three days.
        static let finalAuthorizationRequestTimeIntervalDiff: TimeInterval = 3600 * 24 * 3
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
