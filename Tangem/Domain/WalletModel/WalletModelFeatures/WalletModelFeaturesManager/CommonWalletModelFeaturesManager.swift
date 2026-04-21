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

    // MARK: - Staking

    // [REDACTED_TODO_COMMENT]
    private lazy var stakingFeaturePublisher: AnyPublisher<WalletModelFeature?, Never> = .just(output: nil)

    // MARK: - Transaction history

    // [REDACTED_TODO_COMMENT]
    private lazy var transactionHistoryFeaturePublisher: AnyPublisher<WalletModelFeature?, Never> = .just(output: nil)

    init(nftFeatureManager: WalletModelNFTFeatureManager) {
        self.nftFeatureManager = nftFeatureManager
    }
}

// MARK: - WalletModelFeaturesManager protocol conformance

extension CommonWalletModelFeaturesManager: WalletModelFeaturesManager {
    var features: [WalletModelFeature] {
        [
            nftFeatureManager.nftFeature,
        ].compactMap { $0 }
    }

    var featuresPublisher: AnyPublisher<[WalletModelFeature], Never> {
        [
            nftFeatureManager.nftFeaturePublisher,
            stakingFeaturePublisher,
            transactionHistoryFeaturePublisher,
        ]
        .combineLatest()
        .map { $0.compactMap(\.self) }
        .eraseToAnyPublisher()
    }
}
