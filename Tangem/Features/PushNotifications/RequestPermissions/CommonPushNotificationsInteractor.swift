//
//  CommonPushNotificationsInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import Combine

final class CommonPushNotificationsInteractor {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.pushNotificationsPermission) private var pushNotificationsPermissionsService: PushNotificationsPermissionService

    /// Optional bool because this property is updated only once,
    /// on the very first launch of the app version with push notifications support.
    @AppStorageCompat(StorageKeys.hasSavedWalletsFromPreviousVersion)
    private var hasSavedWalletsFromPreviousVersion: Bool? = nil

    @AppStorageCompat(StorageKeys.canRequestAuthorization)
    private var canRequestAuthorization = Constants.canRequestAuthorizationDefaultValue

    @AppStorageCompat(StorageKeys.didPostponeAuthorizationRequestOnWalletOnboarding)
    private var didPostponeAuthorizationRequestOnWalletOnboarding = false

    @AppStorageCompat(StorageKeys.didPostponeAuthorizationRequestOnWelcomeOnboarding)
    private var didPostponeAuthorizationRequestOnWelcomeOnboarding = false

    @AppStorageCompat(StorageKeys.resetPushNotificationsAuthorizationRequestCounter)
    private var resetPushNotificationsAuthorizationRequestCounter: Int = ResetVersion.default.rawValue

    @AppStorageCompat(StorageKeys.didPostponeOnboardingCompletionDate)
    private var didPostponeOnboardingCompletionDate: Date? = nil

    private var didPostponeAuthorizationRequestOnWelcomeOnboardingInCurrentSession = false

    private func updateSavedWalletsStatusIfNeeded() {
        // Runs only once per installation
        guard hasSavedWalletsFromPreviousVersion == nil else {
            return
        }

        hasSavedWalletsFromPreviousVersion = userWalletRepository.models.isNotEmpty
    }

    private func registerIfPossible() {
        runTask(in: self) { interactor in
            await interactor.pushNotificationsPermissionsService.registerIfPossible()
        }
    }

    private func logAllowRequest(in flow: PushNotificationsPermissionRequestFlow) {
        let source = analyticsSourceValue(for: flow)
        Analytics.log(.pushButtonAllow, params: [.source: source])
    }

    private func logPostponedRequest(in flow: PushNotificationsPermissionRequestFlow) {
        let source = analyticsSourceValue(for: flow)
        Analytics.log(.pushButtonPostpone, params: [.source: source])
    }

    private func logAuthorizationStatus() async {
        let state: Analytics.ParameterValue = await pushNotificationsPermissionsService.isAuthorized ? .allow : .cancel
        Analytics.log(.pushPermissionStatus, params: [.state: state])
    }

    private func analyticsSourceValue(for flow: PushNotificationsPermissionRequestFlow) -> Analytics.ParameterValue {
        switch flow {
        case .welcomeOnboarding:
            return .stories
        case .walletOnboarding:
            return .onboarding
        case .afterLogin, .afterLoginBanner:
            return .main
        }
    }

    private let _permissionRequestEventSubject: PassthroughSubject<PushNotificationsPermissionRequest, Never> = .init()

    private func preconditionAvailable(in flow: PushNotificationsPermissionRequestFlow) -> Bool {
        guard !AppEnvironment.current.isUITest else {
            return false
        }

        return canRequestAuthorization
    }
}

// MARK: - PushNotificationsInteractor protocol conformance

extension CommonPushNotificationsInteractor: PushNotificationsInteractor {
    func isAvailable(in flow: PushNotificationsPermissionRequestFlow) -> Bool {
        guard preconditionAvailable(in: flow) else {
            return false
        }

        switch flow {
        case .welcomeOnboarding:
            didPostponeOnboardingCompletionDate = Date()
            return !didPostponeAuthorizationRequestOnWelcomeOnboarding
        case .walletOnboarding:
            return !didPostponeAuthorizationRequestOnWelcomeOnboardingInCurrentSession
                && !didPostponeAuthorizationRequestOnWalletOnboarding
        case .afterLogin:
            return hasSavedWalletsFromPreviousVersion ?? false
        case .afterLoginBanner:
            guard
                !isAvailable(in: .afterLogin), // Need exclude if display is required bottom sheet permission request
                let didPostponeOnboardingCompletionDate,
                Date().timeIntervalSince(didPostponeOnboardingCompletionDate) > Constants.showDurationAfterLoginBanner
            else {
                return false
            }

            return true
        }
    }

    func allowRequest(in flow: PushNotificationsPermissionRequestFlow) async {
        logAllowRequest(in: flow)
        await pushNotificationsPermissionsService.requestAuthorizationAndRegister()
        await logAuthorizationStatus()
        runOnMain {
            canRequestAuthorization = false
            _permissionRequestEventSubject.send(.allow(flow))
        }
    }

    func postponeRequest(in flow: PushNotificationsPermissionRequestFlow) {
        switch flow {
        case .welcomeOnboarding:
            didPostponeAuthorizationRequestOnWelcomeOnboarding = true
            didPostponeAuthorizationRequestOnWelcomeOnboardingInCurrentSession = true
        case .walletOnboarding:
            didPostponeAuthorizationRequestOnWalletOnboarding = true
        case .afterLogin, .afterLoginBanner:
            // Stop all future authorization requests
            canRequestAuthorization = false
            _permissionRequestEventSubject.send(.postpone(flow))
        }

        logPostponedRequest(in: flow)
    }

    func logRequest(in flow: PushNotificationsPermissionRequestFlow) {
        let source = analyticsSourceValue(for: flow)
        Analytics.log(.pushNotificationScreenOpened, params: [.source: source])
    }

    var permissionRequestPublisher: AnyPublisher<PushNotificationsPermissionRequest, Never> {
        _permissionRequestEventSubject.eraseToAnyPublisher()
    }
}

// MARK: - Initializable protocol conformance

extension CommonPushNotificationsInteractor: Initializable {
    func initialize() {
        resetPushNotificationsAuthorizationRequestCounterIfNeeded()
        updateSavedWalletsStatusIfNeeded()
        registerIfPossible()
    }

    private func resetPushNotificationsAuthorizationRequestCounterIfNeeded() {
        let currentVersion = ResetVersion.current.rawValue

        if resetPushNotificationsAuthorizationRequestCounter < currentVersion {
            hasSavedWalletsFromPreviousVersion = AppSettings.shared.saveUserWallets
            canRequestAuthorization = Constants.canRequestAuthorizationDefaultValue
            resetPushNotificationsAuthorizationRequestCounter = currentVersion
        }
    }
}

// MARK: - Constants

private extension CommonPushNotificationsInteractor {
    enum StorageKeys: String, RawRepresentable {
        case hasSavedWalletsFromPreviousVersion = "has_saved_wallets_from_previous_version"
        case canRequestAuthorization = "can_request_authorization"
        case didPostponeAuthorizationRequestOnWelcomeOnboarding = "did_postpone_authorization_request_on_welcome_onboarding"
        case didPostponeAuthorizationRequestOnWalletOnboarding = "did_postpone_authorization_request_on_wallet_onboarding"
        case resetPushNotificationsAuthorizationRequestCounter = "reset_push_notifications_authorization_request_counter"
        case didPostponeOnboardingCompletionDate = "did_postpone_onboarding_completion_date"
    }

    enum ResetVersion: Int {
        case `default` = 0

        /// We've blocked transactional push notifications, so we need to reset allow notifications.
        case transactionPushNotifications = 1

        static var current: ResetVersion {
            .transactionPushNotifications
        }
    }

    enum Constants {
        static let canRequestAuthorizationDefaultValue = true

        /// One week
        static let showDurationAfterLoginBanner: TimeInterval = 7 * 24 * 60 * 60
    }
}
