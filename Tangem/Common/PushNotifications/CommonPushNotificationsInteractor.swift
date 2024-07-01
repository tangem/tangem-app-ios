//
//  CommonPushNotificationsInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

final class CommonPushNotificationsInteractor {
    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    /// Optional bool because this property is updated only once,
    /// on the very first launch of the app version with push notifications support.
    @AppStorageCompat(StorageKeys.hasSavedWalletsFromPreviousVersion)
    private var hasSavedWalletsFromPreviousVersion: Bool? = nil

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

    init(
        pushNotificationsService: PushNotificationsService
    ) {
        self.pushNotificationsService = pushNotificationsService
        updateSavedWalletsStatusIfNeeded()
    }

    func isAvailable(in flow: PermissionRequestFlow) -> Bool {
        guard
            isFeatureFlagEnabled,
            canRequestAuthorization
        else {
            return false
        }

        switch flow {
        case .welcomeOnboarding:
            return !didPostponeAuthorizationRequestOnWelcomeOnboarding
        case .walletOnboarding:
            return !didPostponeAuthorizationRequestOnWelcomeOnboardingInCurrentSession
                && !didPostponeAuthorizationRequestOnWalletOnboarding
        case .afterLogin:
            guard
                let postponedAuthorizationRequestLaunchCount,
                let postponedAuthorizationRequestDate
            else {
                // `postponedAuthorizationRequestLaunchCount` and `postponedAuthorizationRequestDate` can be nil in some cases,
                // for example on the first call with `PermissionRequestFlow.afterLogin` if user has saved wallets
                return true
            }

            let launchCountSinceLastPostponedRequest = postponedAuthorizationRequestLaunchCount
                + Constants.finalAuthorizationRequestNumberOfLaunchesDiff

            let timeIntervalSinceLastPostponedRequest = abs(postponedAuthorizationRequestDate.timeIntervalSinceNow)

            return currentLaunchCount >= launchCountSinceLastPostponedRequest
                && timeIntervalSinceLastPostponedRequest >= Constants.finalAuthorizationRequestTimeIntervalDiff
        }
    }

    func allowRequest(in _: PermissionRequestFlow) async {
        await pushNotificationsService.requestAuthorizationAndRegister()
        runOnMain {
            canRequestAuthorization = false
        }
    }

    func canPostponeRequest(in flow: PermissionRequestFlow) -> Bool {
        switch flow {
        case .welcomeOnboarding, .walletOnboarding:
            return true
        case .afterLogin where hasSavedWalletsFromPreviousVersion == true:
            // In this case only the first permissions authorization request can be postponed
            return numberOfRequestsPostponedByExistingUser == 0
        case .afterLogin:
            return false
        }
    }

    func postponeRequest(in flow: PermissionRequestFlow) {
        switch flow {
        case .welcomeOnboarding:
            saveLaunchCountAndDateOfPostponedRequest()
            didPostponeAuthorizationRequestOnWelcomeOnboarding = true
            didPostponeAuthorizationRequestOnWelcomeOnboardingInCurrentSession = true
        case .walletOnboarding:
            saveLaunchCountAndDateOfPostponedRequest()
            didPostponeAuthorizationRequestOnWalletOnboarding = true
        case .afterLogin where hasSavedWalletsFromPreviousVersion == true:
            saveLaunchCountAndDateOfPostponedRequest()
            numberOfRequestsPostponedByExistingUser += 1
            // Stop all future authorization requests if the user postpones the request for the 2nd time
            if numberOfRequestsPostponedByExistingUser > 1 {
                canRequestAuthorization = false
            }
        case .afterLogin:
            // Stop all future authorization requests
            canRequestAuthorization = false
        }
    }

    private func saveLaunchCountAndDateOfPostponedRequest() {
        postponedAuthorizationRequestLaunchCount = currentLaunchCount
        postponedAuthorizationRequestDate = .now
    }

    private func updateSavedWalletsStatusIfNeeded() {
        // Runs only once per installation
        guard hasSavedWalletsFromPreviousVersion == nil else {
            return
        }

        hasSavedWalletsFromPreviousVersion = userWalletRepository.hasSavedWallets
    }
}

// MARK: - Auxiliary types

extension CommonPushNotificationsInteractor {
    enum PermissionRequestFlow {
        /// User starts the app for the first time, accept TOS, etc.
        case welcomeOnboarding
        /// User adds first wallet to the app, performs backup, etc.
        case walletOnboarding
        /// User completed all onboarding procedures and using app normally.
        case afterLogin
    }
}

// MARK: - Constants

private extension CommonPushNotificationsInteractor {
    enum StorageKeys: String, RawRepresentable {
        case hasSavedWalletsFromPreviousVersion = "has_saved_wallets_from_previous_version"
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
