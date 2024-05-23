//
//  FeatureStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation

// MARK: - Provider

class FeatureStorage {
    @AppStorageCompat(FeatureStorageKeys.testnet)
    var isTestnet: Bool = false

    @AppStorageCompat(FeatureStorageKeys.availableFeatures)
    var availableFeatures: [Feature: FeatureState] = [:]

    @AppStorageCompat(FeatureStorageKeys.useDevApi)
    var useDevApi = false

    @AppStorageCompat(FeatureStorageKeys.useDevApiExpress)
    var useDevApiExpress = false

    // [REDACTED_TODO_COMMENT]
    @AppStorageCompat(FeatureStorageKeys.fakeTxHistory)
    var useFakeTxHistory = false

    @AppStorageCompat(FeatureStorageKeys.supportedBlockchainsIds)
    var supportedBlockchainsIds: [String] = []

    @AppStorageCompat(FeatureStorageKeys.performanceMonitorEnabled)
    var isPerformanceMonitorEnabled = false

    @AppStorageCompat(FeatureStorageKeys.mockedCardScannerEnabled)
    var isMockedCardScannerEnabled = true
}

// MARK: - Keys

private enum FeatureStorageKeys: String {
    case testnet
    case availableFeatures = "integrated_features"
    case useDevApi = "use_dev_api"
    case useDevApiExpress = "use_dev_api_express"
    case fakeTxHistory = "fake_transaction_history"
    case supportedBlockchainsIds
    case performanceMonitorEnabled = "performance_monitor_enabled"
    case mockedCardScannerEnabled = "mocked_card_scanner_enabled"
}
