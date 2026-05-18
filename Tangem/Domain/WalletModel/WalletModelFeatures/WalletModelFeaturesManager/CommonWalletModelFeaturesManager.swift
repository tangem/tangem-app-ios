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
    private let nftFeatureManager: CommonWalletModelNFTFeatureManager
    private let dynamicAddressesFeatureManager: CommonWalletModelDynamicAddressesFeatureManager
    private let transactionHistoryFeatureManager: CommonWalletModelTransactionHistoryFeatureManager

    // MARK: - Staking

    // [REDACTED_TODO_COMMENT]
    private lazy var stakingFeaturePublisher: AnyPublisher<WalletModelFeature?, Never> = .just(output: nil)

    init(
        nftFeatureManager: CommonWalletModelNFTFeatureManager,
        dynamicAddressesFeatureManager: CommonWalletModelDynamicAddressesFeatureManager,
        transactionHistoryFeatureManager: CommonWalletModelTransactionHistoryFeatureManager
    ) {
        self.nftFeatureManager = nftFeatureManager
        self.dynamicAddressesFeatureManager = dynamicAddressesFeatureManager
        self.transactionHistoryFeatureManager = transactionHistoryFeatureManager
    }
}

// MARK: - WalletModelFeaturesManager protocol conformance

extension CommonWalletModelFeaturesManager: WalletModelFeaturesManager {
    var features: [WalletModelFeature] {
        [
            nftFeatureManager.nftNetworkService.map(WalletModelFeature.nft(networkService:)),
            dynamicAddressesFeatureManager.dynamicAddressesManager.map(WalletModelFeature.dynamicAddresses(manager:)),
            transactionHistoryFeatureManager.transactionHistorySync.map(WalletModelFeature.transactionHistory(sync:)),
        ].compactMap { $0 }
    }

    var featuresPublisher: AnyPublisher<[WalletModelFeature], Never> {
        [
            nftFeatureManager.nftNetworkServicePublisher
                .map { $0.map(WalletModelFeature.nft(networkService:)) }
                .eraseToAnyPublisher(),
            dynamicAddressesFeatureManager.dynamicAddressesManagerPublisher
                .map { $0.map(WalletModelFeature.dynamicAddresses(manager:)) }
                .eraseToAnyPublisher(),
            transactionHistoryFeatureManager.transactionHistorySyncPublisher
                .map { $0.map(WalletModelFeature.transactionHistory(sync:)) }
                .eraseToAnyPublisher(),
            stakingFeaturePublisher,
        ]
        .combineLatest()
        .map { $0.compactMap(\.self) }
        .eraseToAnyPublisher()
    }
}
