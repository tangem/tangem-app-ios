//
//  FeaturesStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - Provider

class FeaturesStorage {
    @AppStorageCompat(FeaturesStorageKeys.testnet)
    var isTestnet: Bool = false

    @AppStorageCompat(FeaturesStorageKeys.availableFeatures)
    var availableFeatures: [FeatureToggle: FeatureState] = [:]

    @AppStorageCompat(FeaturesStorageKeys.useDevApi)
    var useDevApi = false
}

// MARK: - Keys

private enum FeaturesStorageKeys: String {
    case testnet
    case availableFeatures = "integrated_features"
    case useDevApi = "use_dev_api"
}
