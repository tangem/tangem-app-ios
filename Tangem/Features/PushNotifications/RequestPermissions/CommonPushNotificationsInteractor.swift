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
    @Injected(\.pushNotificationsPermission) private var pushNotificationsPermissionsService: PushNotificationsPermissionService

    @AppStorageCompat(StorageKeys.canRequestAuthorization)
    private var canRequestAuthorization = Constants.canRequestAuthorizationDefaultValue

    /// Optional bool because this property is updated only once,
    /// on the very first launch of the app version with push notifications support.
    @AppStorageCompat(StorageKeys.didRequestAuthorizationOnAfterLogin)
    private var canRequestAuthorizationOnAfterLogin: Bool? = nil

    /// Property type is selected because in the future it may be necessary to count down the date when permissions are displayed
    @AppStorageCompat(StorageKeys.didPostponeOnboardingCompletionDate)
    private var requestAuthorizationOnAfterLoginBannerCompletionDate: Date? = nil

    @AppStorageCompat(StorageKeys.didPostponeAuthorizationRequestOnWalletOnboarding)
    private var didPostponeAuthorizationRequestOnWalletOnboarding = false

    @AppStorageCompat(StorageKeys.didPostponeAuthorizationRequestOnWelcomeOnboarding)
    private var didPostponeAuthorizationRequestOnWelcomeOnboarding = false

    @AppStorageCompat(StorageKeys.resetPushNotificationsAuthorizationRequestCounter)
    private var resetPushNotificationsAuthorizationRequestCounter: Int = ResetVersion.default.rawValue

    private var didPostponeAuthorizationRequestOnWelcomeOnboardingInCurrentSession = false
    private var didPostponeAuthorizationRequestOnWalletOnboardingInCurrentSession = false

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

        switch flow {
        // This workflow is required for mandatory display of the updated content to users from previous versions.
        case .afterLoginBanner where
            canRequestAuthorization == false &&
            requestAuthorizationOnAfterLoginBannerCompletionDate == nil:
            return true
        default:
            return canRequestAuthorization
        }
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
            return !didPostponeAuthorizationRequestOnWelcomeOnboarding
        case .walletOnboarding:
            return !didPostponeAuthorizationRequestOnWelcomeOnboardingInCurrentSession
                && !didPostponeAuthorizationRequestOnWalletOnboarding
        case .afterLogin:
            let currentRequestState = canRequestAuthorizationOnAfterLogin ?? true
            canRequestAuthorizationOnAfterLogin = true

            return currentRequestState
                && !didPostponeAuthorizationRequestOnWelcomeOnboardingInCurrentSession
                && !didPostponeAuthorizationRequestOnWalletOnboardingInCurrentSession
        case .afterLoginBanner:
            // Need to exclude if display is required bottom sheet permission request or current session
            guard
                !isAvailable(in: .afterLogin),
                !didPostponeAuthorizationRequestOnWelcomeOnboardingInCurrentSession,
                !didPostponeAuthorizationRequestOnWalletOnboardingInCurrentSession
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
            stopAllFeatureAuthorizationRequests()
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
            didPostponeAuthorizationRequestOnWalletOnboardingInCurrentSession = true
        case .afterLogin, .afterLoginBanner:
            // Stop all future authorization requests
            stopAllFeatureAuthorizationRequests()
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

    // MARK: - Private Implementation

    private func stopAllFeatureAuthorizationRequests() {
        requestAuthorizationOnAfterLoginBannerCompletionDate = Date()
        canRequestAuthorization = false
    }
}

// MARK: - Initializable protocol conformance

extension CommonPushNotificationsInteractor: Initializable {
    func initialize() {
        resetPushNotificationsAuthorizationRequestCounterIfNeeded()
        registerIfPossible()
    }

    private func resetPushNotificationsAuthorizationRequestCounterIfNeeded() {
        let currentVersion = ResetVersion.current.rawValue

        if resetPushNotificationsAuthorizationRequestCounter < currentVersion {
            canRequestAuthorizationOnAfterLogin = nil
            canRequestAuthorization = Constants.canRequestAuthorizationDefaultValue
            resetPushNotificationsAuthorizationRequestCounter = currentVersion
        }
    }
}

// MARK: - Constants

private extension CommonPushNotificationsInteractor {
    enum StorageKeys: String, RawRepresentable {
        case canRequestAuthorization = "can_request_authorization"
        case didPostponeAuthorizationRequestOnWelcomeOnboarding = "did_postpone_authorization_request_on_welcome_onboarding"
        case didPostponeAuthorizationRequestOnWalletOnboarding = "did_postpone_authorization_request_on_wallet_onboarding"
        case didRequestAuthorizationOnAfterLogin = "did_request_authorization_on_after_login"
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
    }
}
