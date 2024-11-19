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
    static let instance: FeatureStorage = .init()

    @AppStorageCompat(FeatureStorageKeys.testnet)
    var isTestnet: Bool = false

    @AppStorageCompat(FeatureStorageKeys.availableFeatures)
    var availableFeatures: [Feature: FeatureState] = [:]

    @AppStorageCompat(FeatureStorageKeys.useDevApi)
    var useDevApi = false

    @AppStorageCompat(FeatureStorageKeys.apiExpress)
    var apiExpress: String = "production"

    @AppStorageCompat(FeatureStorageKeys.supportedBlockchainsIds)
    var supportedBlockchainsIds: [String] = []

    @AppStorageCompat(FeatureStorageKeys.stakingBlockchainsIds)
    var stakingBlockchainsIds: [String] = []

    @AppStorageCompat(FeatureStorageKeys.performanceMonitorEnabled)
    var isPerformanceMonitorEnabled = false

    @AppStorageCompat(FeatureStorageKeys.mockedCardScannerEnabled)
    var isMockedCardScannerEnabled = true

    @AppStorageCompat(FeatureStorageKeys.useVisaTestnet)
    var isVisaTestnet = false

    private init() {}
}

// MARK: - Keys

private enum FeatureStorageKeys: String {
    case testnet
    case availableFeatures = "integrated_features"
    case useDevApi = "use_dev_api"
    case apiExpress = "api_express"
    case supportedBlockchainsIds
    case stakingBlockchainsIds
    case performanceMonitorEnabled = "performance_monitor_enabled"
    case mockedCardScannerEnabled = "mocked_card_scanner_enabled"
    case useVisaTestnet = "use_visa_testnet"
}
