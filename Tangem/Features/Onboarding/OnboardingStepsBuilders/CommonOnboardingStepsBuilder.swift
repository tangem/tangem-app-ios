//
//  CommonOnboardingStepsBuilder.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import TangemSdk

struct CommonOnboardingStepsBuilder {
    @Injected(\.pushNotificationsInteractor) private var pushNotificationsInteractor: PushNotificationsInteractor

    var shouldAddSaveWalletsStep: Bool {
        BiometricsUtil.isAvailable
            && !AppSettings.shared.useBiometricAuthentication
            && !AppSettings.shared.askedToSaveUserWallets
    }

    var shouldAddPushNotificationsStep: Bool {
        let factory = PushNotificationsHelpersFactory()
        let availabilityProvider = factory.makeAvailabilityProviderForWalletOnboarding(using: pushNotificationsInteractor)
        return availabilityProvider.isAvailable
    }
}
