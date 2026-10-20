//
//  ExperimentServiceStub.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Experiment
import TangemFoundation
@testable import Tangem

final class ExperimentServiceStub: ExperimentService {
    enum Method: Equatable {
        case variant
        case isOn
        case isOnWithoutExposure
    }

    private let storedVariant: String?
    private let isFetched: Bool
    private let recordedMethods = OSAllocatedUnfairLock<[Method]>(initialState: [])

    init(storedVariant: String?, isFetched: Bool) {
        self.storedVariant = storedVariant
        self.isFetched = isFetched
    }

    convenience init(storedVariant: ExperimentFeatureVariantKey?) {
        self.init(storedVariant: storedVariant?.rawValue, isFetched: storedVariant != nil)
    }

    var invokedMethods: [Method] { recordedMethods.withLock { $0 } }

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

    func hasFetchedVariants(for userWalletId: UserWalletId) -> Bool {
        isFetched
    }
}
