//
//  ExperimentServiceStub.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Experiment
import TangemFoundation
@testable import Tangem

final class ExperimentServiceStub: ExperimentService {
    enum Method: Equatable {
        case variant
        case isOn
        case isOnWithoutExposure
    }

    private let storedVariantState: OSAllocatedUnfairLock<String?>
    private let isFetched: Bool
    private let recordedMethods = OSAllocatedUnfairLock<[Method]>(initialState: [])
    private let variantsSubject = PassthroughSubject<Void, Never>()
    private let freshVariants: OSAllocatedUnfairLock<Bool>

    init(storedVariant: String?, isFetched: Bool) {
        storedVariantState = OSAllocatedUnfairLock(initialState: storedVariant)
        self.isFetched = isFetched
        freshVariants = OSAllocatedUnfairLock(initialState: isFetched)
    }

    convenience init(storedVariant: ExperimentFeatureVariantKey?) {
        self.init(storedVariant: storedVariant?.rawValue, isFetched: storedVariant != nil)
    }

    var invokedMethods: [Method] { recordedMethods.withLock { $0 } }

    var variantsPublisher: AnyPublisher<Void, Never> {
        variantsSubject.eraseToAnyPublisher()
    }

    var hasFreshVariants: Bool {
        freshVariants.withLock { $0 }
    }

    func fetch(variant: ExperimentFeatureVariantKey?) {
        storedVariantState.withLock { $0 = variant?.rawValue }
        freshVariants.withLock { $0 = true }
        variantsSubject.send()
    }

    func startFetching() {
        freshVariants.withLock { $0 = false }
        variantsSubject.send()
    }

    private var storedVariant: String? {
        storedVariantState.withLock { $0 }
    }

    func configure() {}

    func variant(_ key: ExperimentFeatureFlagKey) -> Variant? {
        recordedMethods.withLock { $0.append(.variant) }
        return storedVariant.map { Variant($0) }
    }

    func isOn(_ key: ExperimentFeatureFlagKey, variant: ExperimentFeatureVariantKey) -> Bool {
        recordedMethods.withLock { $0.append(.isOn) }
        return storedVariant == variant.rawValue
    }

    func isOnWithoutExposure(_ key: ExperimentFeatureFlagKey, variant: ExperimentFeatureVariantKey) -> Bool {
        recordedMethods.withLock { $0.append(.isOnWithoutExposure) }
        return storedVariant == variant.rawValue
    }

    func waitForVariants(ofWalletMatching _: @escaping (UserWalletId) -> Bool) async -> Bool {
        isFetched
    }

    func hasFetchedVariants(for userWalletId: UserWalletId) -> Bool {
        isFetched
    }
}
