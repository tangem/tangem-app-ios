//
//  PolymarketAvailabilityProvider.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation

protocol PolymarketAvailabilityProvider {
    var isAvailable: Bool { get }

    var isAvailablePublisher: AnyPublisher<Bool, Never> { get }
}

/// The experiment is evaluated for the selected wallet, so one enrolled wallet opens the feature for the session.
struct CommonPolymarketAvailabilityProvider: PolymarketAvailabilityProvider {
    @Injected(\.experimentService) private var experimentService: ExperimentService

    private let enrollment = OSAllocatedUnfairLock(initialState: false)

    var isAvailable: Bool {
        FeatureProvider.isAvailable(.polymarket) || isEnrolled
    }

    private var isEnrolled: Bool {
        if enrollment.withLock({ $0 }) {
            return true
        }

        guard experimentService.isOn(.polymarket, variant: .on) else {
            return false
        }

        enrollment.withLock { $0 = true }

        return true
    }

    var isAvailablePublisher: AnyPublisher<Bool, Never> {
        let isAvailable = { self.isAvailable }

        return experimentService
            .variantsPublisher
            .map { _ in isAvailable() }
            .prepend(isAvailable())
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}

// MARK: - Injection

private struct PolymarketAvailabilityProviderKey: InjectionKey {
    static var currentValue: PolymarketAvailabilityProvider = CommonPolymarketAvailabilityProvider()
}

extension InjectedValues {
    var polymarketAvailabilityProvider: PolymarketAvailabilityProvider {
        get { Self[PolymarketAvailabilityProviderKey.self] }
        set { Self[PolymarketAvailabilityProviderKey.self] = newValue }
    }
}
