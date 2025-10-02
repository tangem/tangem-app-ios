//
//  PushNotificationsHelpersFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct PushNotificationsHelpersFactory {
    func makeAvailabilityProviderForWelcomeOnboarding(
        using interactor: PushNotificationsInteractor
    ) -> PushNotificationsAvailabilityProvider {
        return makeTrampolineForFlow(.welcomeOnboarding, using: interactor)
    }

    func makeAvailabilityProviderForWalletOnboarding(
        using interactor: PushNotificationsInteractor
    ) -> PushNotificationsAvailabilityProvider {
        return makeTrampolineForFlow(.walletOnboarding, using: interactor)
    }

    func makeAvailabilityProviderForAfterLogin(
        using interactor: PushNotificationsInteractor
    ) -> PushNotificationsAvailabilityProvider {
        return makeTrampolineForFlow(.afterLogin, using: interactor)
    }

    func makeAvailabilityProviderForAfterLoginBanner(
        using interactor: PushNotificationsInteractor
    ) -> PushNotificationsAvailabilityProvider {
        return makeTrampolineForFlow(.afterLoginBanner, using: interactor)
    }

    func makePermissionManagerForWelcomeOnboarding(
        using interactor: PushNotificationsInteractor
    ) -> PushNotificationsPermissionManager {
        return makeTrampolineForFlow(.welcomeOnboarding, using: interactor)
    }

    func makePermissionManagerForWalletOnboarding(
        using interactor: PushNotificationsInteractor
    ) -> PushNotificationsPermissionManager {
        return makeTrampolineForFlow(.walletOnboarding, using: interactor)
    }

    func makePermissionManagerForAfterLogin(
        using interactor: PushNotificationsInteractor) -> PushNotificationsPermissionManager {
        return makeTrampolineForFlow(.afterLogin, using: interactor)
    }

    func makePermissionManagerForAfterLoginBanner(
        using interactor: PushNotificationsInteractor) -> PushNotificationsPermissionManager {
        return makeTrampolineForFlow(.afterLoginBanner, using: interactor)
    }

    private func makeTrampolineForFlow(
        _ flow: PushNotificationsPermissionRequestFlow,
        using interactor: PushNotificationsInteractor
    ) -> InteractorTrampoline {
        return InteractorTrampoline(
            isAvailable: { interactor.isAvailable(in: flow) },
            allowRequest: { await interactor.allowRequest(in: flow) },
            postponeRequest: { interactor.postponeRequest(in: flow) },
            logRequest: { interactor.logRequest(in: flow) }
        )
    }
}

// MARK: - Auxiliary types

private extension PushNotificationsHelpersFactory {
    /// Proxy that forwards all calls from `PushNotificationsAvailabilityProvider` and `PushNotificationsPermissionManager`
    /// interfaces to the opaque wrapped underlying entity using closures.
    final class InteractorTrampoline: PushNotificationsAvailabilityProvider, PushNotificationsPermissionManager {
        typealias IsAvailable = () -> Bool
        typealias AllowRequest = () async -> Void
        typealias PostponeRequest = () -> Void
        typealias LogRequest = () -> Void

        var isAvailable: Bool { _isAvailable() }

        private let _isAvailable: IsAvailable
        private let _allowRequest: AllowRequest
        private let _postponeRequest: PostponeRequest
        private let _logRequest: LogRequest

        init(
            isAvailable: @escaping IsAvailable,
            allowRequest: @escaping AllowRequest,
            postponeRequest: @escaping PostponeRequest,
            logRequest: @escaping LogRequest
        ) {
            _isAvailable = isAvailable
            _allowRequest = allowRequest
            _postponeRequest = postponeRequest
            _logRequest = logRequest
        }

        func allowPermissionRequest() async {
            await _allowRequest()
        }

        func postponePermissionRequest() {
            _postponeRequest()
        }

        func logPushNotificationScreenOpened() {
            _logRequest()
        }
    }
}
