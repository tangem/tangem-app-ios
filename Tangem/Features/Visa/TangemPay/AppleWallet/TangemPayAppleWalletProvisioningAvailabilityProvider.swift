//
//  TangemPayAppleWalletProvisioningAvailabilityProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemVisa

protocol TangemPayAppleWalletProvisioningAvailabilityProvider {
    var isAvailable: Bool { get }
}

struct CommonTangemPayAppleWalletProvisioningAvailabilityProvider: TangemPayAppleWalletProvisioningAvailabilityProvider {
    @Injected(\.experimentService) private var experimentService: ExperimentService

    var isAvailable: Bool {
        let isAvailable = FeatureProvider.isAvailable(.tangemPayAppleWalletProvisioning)
            || experimentService.isOn(.tangemPayAppleWalletProvisioning, variant: .pushProvisioningOn)
        logAvailability(isAvailable)
        return isAvailable
    }

    private func logAvailability(_ isAvailable: Bool) {
        let isToggleOn = FeatureProvider.isAvailable(.tangemPayAppleWalletProvisioning)
        let variant = experimentService.variant(.tangemPayAppleWalletProvisioning)?.value ?? "none"
        VisaLogger.info("Apple Wallet provisioning available: \(isAvailable), toggle: \(isToggleOn), experiment variant: \(variant)")
    }
}

// MARK: - Injection

private struct TangemPayAppleWalletProvisioningAvailabilityProviderKey: InjectionKey {
    static var currentValue: TangemPayAppleWalletProvisioningAvailabilityProvider =
        CommonTangemPayAppleWalletProvisioningAvailabilityProvider()
}

extension InjectedValues {
    var tangemPayAppleWalletProvisioningAvailabilityProvider: TangemPayAppleWalletProvisioningAvailabilityProvider {
        get { Self[TangemPayAppleWalletProvisioningAvailabilityProviderKey.self] }
        set { Self[TangemPayAppleWalletProvisioningAvailabilityProviderKey.self] = newValue }
    }
}
