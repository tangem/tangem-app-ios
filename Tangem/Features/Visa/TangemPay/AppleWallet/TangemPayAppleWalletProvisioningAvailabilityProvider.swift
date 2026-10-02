//
//  TangemPayAppleWalletProvisioningAvailabilityProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemVisa

protocol TangemPayAppleWalletProvisioningAvailabilityProvider {
    var isAvailable: Bool { get }

    var isAvailablePublisher: AnyPublisher<Bool, Never> { get }
}

struct CommonTangemPayAppleWalletProvisioningAvailabilityProvider: TangemPayAppleWalletProvisioningAvailabilityProvider {
    @Injected(\.experimentService) private var experimentService: ExperimentService

    var isAvailable: Bool {
        FeatureProvider.isAvailable(.tangemPayAppleWalletProvisioning)
            || experimentService.isOn(.tangemPayAppleWalletProvisioning, variant: .pushProvisioningOn)
    }

    var isAvailablePublisher: AnyPublisher<Bool, Never> {
        experimentService
            .variantsPublisher
            .map { _ in isAvailable }
            .prepend(isAvailable)
            .removeDuplicates()
            .handleEvents(receiveOutput: logAvailability)
            .eraseToAnyPublisher()
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
