//
//  PushNotificationsHelperFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct PushNotificationsHelperFactory {
    // [REDACTED_TODO_COMMENT]
    private var pushNotificationsInteractor: CommonPushNotificationsInteractor { CommonPushNotificationsInteractor.shared }

    func makeAvailabilityProviderForWelcomeOnboarding() -> PushNotificationsAvailabilityProvider {
        return makeTrampolineForFlow(.welcomeOnboarding)
    }

    func makeAvailabilityProviderForWalletOnboarding() -> PushNotificationsAvailabilityProvider {
        return makeTrampolineForFlow(.walletOnboarding)
    }

    func makeAvailabilityProviderForAfterLogin() -> PushNotificationsAvailabilityProvider {
        return makeTrampolineForFlow(.afterLogin)
    }

    func makePermissionManagerForWelcomeOnboarding() -> PushNotificationsPermissionManager {
        return makeTrampolineForFlow(.welcomeOnboarding)
    }

    func makePermissionManagerForWalletOnboarding() -> PushNotificationsPermissionManager {
        return makeTrampolineForFlow(.walletOnboarding)
    }

    func makePermissionManagerForAfterLogin() -> PushNotificationsPermissionManager {
        return makeTrampolineForFlow(.afterLogin)
    }

    private func makeTrampolineForFlow(
        _ flow: CommonPushNotificationsInteractor.PermissionRequestFlow
    ) -> PushNotificationsInteractorTrampoline {
        return PushNotificationsInteractorTrampoline(
            isAvailable: { pushNotificationsInteractor.isAvailable(in: flow) },
            canPostponePermissionRequest: { pushNotificationsInteractor.canPostponeRequest(in: flow) },
            allowRequest: { await pushNotificationsInteractor.allowRequest(in: flow) },
            postponeRequest: { pushNotificationsInteractor.postponeRequest(in: flow) }
        )
    }
}
