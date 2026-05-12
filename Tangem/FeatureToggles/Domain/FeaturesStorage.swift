//
//  FeatureStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemVisa
import TangemStaking
import TangemPay

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

    @AppStorageCompat(FeatureStorageKeys.visaAPIType)
    var visaAPIType = VisaAPIType.prod

    @AppStorageCompat(FeatureStorageKeys.tangemAPIType)
    var tangemAPIType = TangemAPIType.prod

    @AppStorageCompat(FeatureStorageKeys.stakeKitAPIType)
    var stakeKitAPIType = StakeKitAPIType.prod

    @AppStorageCompat(FeatureStorageKeys.yieldModuleAPIType)
    var yieldModuleAPIType = YieldModuleAPIType.prod

    @AppStorageCompat(FeatureStorageKeys.gaslessTransactionsAPIType)
    var gaslessTransactionsAPIType = GaslessTransactionsAPIType.prod

    @AppStorageCompat(UserWalletIdSpoofMapStorageKey(rawValue: UserWalletIdSpoofer.shared.storageKey), store: UserWalletIdSpoofer.shared.userDefaults)
    var userWalletIdSpoofMap: [String: Data] = [:]

    private init() {}
}

// MARK: - Storage keys

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
    case stakeKitAPIType = "stake_kit_api_type"
    case yieldModuleAPIType = "yield_module_api_type"
    case gaslessTransactionsAPIType = "gasless_transactions_api_type"
}

/// Wraps `UserWalletIdSpoofer.shared.storageKey` so it can be consumed by `@AppStorageCompat`,
/// which requires its key to conform to `RawRepresentable<String>`. The corresponding
/// `FeatureStorageKeys` enum can't reference the spoofer's storage key directly because Swift
/// enum raw values must be literals.
private struct UserWalletIdSpoofMapStorageKey: RawRepresentable {
    let rawValue: String
}
