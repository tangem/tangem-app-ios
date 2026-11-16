//
//  FeatureStorage.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import enum TangemExpress.ExpressAPIType
import TangemVisa
import TangemStaking
import TangemPay

final class FeatureStorage {
    static let instance: FeatureStorage = .init()

    @AppStorageCompat(FeatureStorageKeys.testnet)
    var isTestnet: Bool = false

    @AppStorageCompat(FeatureStorageKeys.availableFeatures)
    var availableFeatures: [Feature: FeatureState] = [:]

    @AppStorageCompat(FeatureStorageKeys.backendAuthenticationAPIType)
    var backendAuthenticationAPIType = Defaults.backendAuthenticationAPIType

    @AppStorageCompat(FeatureStorageKeys.apiExpress)
    var apiExpress = Defaults.expressAPIType

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
    var tangemAPIType = Defaults.tangemAPIType

    @AppStorageCompat(FeatureStorageKeys.stakeKitAPIType)
    var stakeKitAPIType = StakeKitAPIType.prod

    @AppStorageCompat(FeatureStorageKeys.yieldModuleAPIType)
    var yieldModuleAPIType = YieldModuleAPIType.prod

    @AppStorageCompat(FeatureStorageKeys.gaslessTransactionsAPIType)
    var gaslessTransactionsAPIType = GaslessTransactionsAPIType.prod

    @AppStorageCompat(FeatureStorageKeys.applePayMerchantType)
    var applePayMerchantType = ApplePayMerchantType.sandbox

    @AppStorageCompat(FeatureStorageKeys.appDatabaseDropScheduled)
    var isAppDatabaseDropScheduled = false

    private init() {}
}

// MARK: - Defaults

extension FeatureStorage {
    enum Defaults {
        static let backendAuthenticationAPIType = BackendAuthenticationAPIType.development
        static let expressAPIType = ExpressAPIType.develop5New

        static var tangemAPIType: TangemAPIType {
            #if DEBUG
            return TangemAPIType.dev
            #else
            return TangemAPIType.prod
            #endif
        }
    }
}

// MARK: - Keys

private enum FeatureStorageKeys: String {
    case testnet
    case availableFeatures = "integrated_features"
    case backendAuthenticationAPIType = "backend_authentication_api_type"
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
    case applePayMerchantType = "apple_pay_merchant_id_env"
    case appDatabaseDropScheduled = "app_database_drop_scheduled"
}
