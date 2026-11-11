//
//  UITestExperimentService.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation
import Experiment

final class UITestExperimentService {
    private let wrapped: ExperimentService
    private let variantOverrides: [ExperimentFeatureFlagKey: ExperimentFeatureVariantKey]

    init(
        wrapped: ExperimentService,
        variantOverrides: [ExperimentFeatureFlagKey: ExperimentFeatureVariantKey]
    ) {
        self.wrapped = wrapped
        self.variantOverrides = variantOverrides
    }
}

// MARK: - ExperimentService

extension UITestExperimentService: ExperimentService {
    var variantsPublisher: AnyPublisher<Void, Never> {
        wrapped.variantsPublisher
    }

    var hasFreshVariants: Bool {
        variantOverrides.isNotEmpty || wrapped.hasFreshVariants
    }

    func configure() {
        wrapped.configure()
    }

    func variant(_ key: ExperimentFeatureFlagKey) -> Variant? {
        wrapped.variant(key)
    }

    func isOn(_ key: ExperimentFeatureFlagKey, variant: ExperimentFeatureVariantKey) -> Bool {
        if let override = variantOverrides[key] {
            return override == variant
        }

        return wrapped.isOn(key, variant: variant)
    }

    func isOnWithoutExposure(_ key: ExperimentFeatureFlagKey, variant: ExperimentFeatureVariantKey) -> Bool {
        if let override = variantOverrides[key] {
            return override == variant
        }

        return wrapped.isOnWithoutExposure(key, variant: variant)
    }

    func waitForVariants(ofWalletMatching isMatching: @escaping (UserWalletId) -> Bool) async -> Bool {
        await wrapped.waitForVariants(ofWalletMatching: isMatching)
    }

    @MainActor
    func hasFetchedVariants(for userWalletId: UserWalletId) -> Bool {
        wrapped.hasFetchedVariants(for: userWalletId)
    }
}
