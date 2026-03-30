//
//  CommonWalletModelFeaturesManager.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import CombineExt

final class CommonWalletModelFeaturesManager {
    private let nftFeatureManager: WalletModelNFTFeatureManager
    private let dynamicAddressesFeatureManager: WalletModelDynamicAddressesFeatureManager

    // MARK: - Staking

    // [REDACTED_TODO_COMMENT]
    private lazy var stakingFeaturePublisher: some Publisher<[WalletModelFeature], Never> = Just([])

    // MARK: - Transaction history

    // [REDACTED_TODO_COMMENT]
    private lazy var transactionHistoryFeaturePublisher: some Publisher<[WalletModelFeature], Never> = Just([])

    init(
        nftFeatureManager: WalletModelNFTFeatureManager,
        dynamicAddressesFeatureManager: WalletModelDynamicAddressesFeatureManager
    ) {
        self.nftFeatureManager = nftFeatureManager
        self.dynamicAddressesFeatureManager = dynamicAddressesFeatureManager
    }
}

// MARK: - WalletModelFeaturesManager protocol conformance

extension CommonWalletModelFeaturesManager: WalletModelFeaturesManager {
    var featuresPublisher: AnyPublisher<[WalletModelFeature], Never> {
        return Publishers.CombineLatest4(
            nftFeatureManager.nftFeaturePublisher,
            dynamicAddressesFeatureManager.dynamicAddressesFeaturePublisher,
            stakingFeaturePublisher,
            transactionHistoryFeaturePublisher
        )
        .map { $0.0 + $0.1 + $0.2 + $0.3 }
        .eraseToAnyPublisher()
    }
}
