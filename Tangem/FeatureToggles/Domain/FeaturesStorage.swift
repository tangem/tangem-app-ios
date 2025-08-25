//
//  FeatureStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemVisa

// MARK: - Provider

class FeatureStorage {
    static let instance: FeatureStorage = .init()

    @AppStorageCompat(FeatureStorageKeys.testnet)
    var isTestnet: Bool = false

    @AppStorageCompat(FeatureStorageKeys.availableFeatures)
    var availableFeatures: [Feature: FeatureState] = [:]

    @AppStorageCompat(FeatureStorageKeys.apiExpress)
    var apiExpress: String = "production"

    @AppStorageCompat(FeatureStorageKeys.supportedBlockchainsIds)
    var supportedBlockchainsIds: [String] = []

    @AppStorageCompat(FeatureStorageKeys.stakingBlockchainsIds)
    var stakingBlockchainsIds: [String] = []

    @AppStorageCompat(FeatureStorageKeys.testableNFTChainsIds)
    var testableNFTChainsIds: [String] = []

    @AppStorageCompat(FeatureStorageKeys.performanceMonitorEnabled)
    var isPerformanceMonitorEnabled = false

    @AppStorageCompat(FeatureStorageKeys.mockedCardScannerEnabled)
    var isMockedCardScannerEnabled = true

    @AppStorageCompat(FeatureStorageKeys.useVisaAPIMocks)
    var isVisaAPIMocksEnabled = false

    @AppStorageCompat(FeatureStorageKeys.visaAPIType)
    var visaAPIType = VisaAPIType.prod

    @AppStorageCompat(FeatureStorageKeys.tangemAPIType)
    var tangemAPIType = TangemAPIType.prod

    private init() {}
}

// MARK: - Keys

private enum FeatureStorageKeys: String {
    case testnet
    case availableFeatures = "integrated_features"
    case apiExpress = "api_express"
    case supportedBlockchainsIds
    case stakingBlockchainsIds
    case testableNFTChainsIds = "testable_nft_chains_ids"
    case performanceMonitorEnabled = "performance_monitor_enabled"
    case mockedCardScannerEnabled = "mocked_card_scanner_enabled"
    case useVisaTestnet = "use_visa_testnet"
    case useVisaAPIMocks = "use_visa_api_mocks"
    case visaAPIType = "visa_api_type"
    case tangemAPIType = "tangem_api_type"
}
