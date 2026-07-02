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
import TangemNFT

final class CommonWalletModelFeaturesManager<
    NFT: WalletModelFeatureManager<NFTNetworkService>,
    DynamicAddresses: WalletModelFeatureManager<DynamicAddressesManager>,
    TransactionHistory: WalletModelFeatureManager<TransactionHistoryProviding>
> {
    private let nftFeatureManager: NFT
    private let dynamicAddressesFeatureManager: DynamicAddresses
    private let transactionHistoryFeatureManager: TransactionHistory

    // MARK: - Staking

    // [REDACTED_TODO_COMMENT]
    private lazy var stakingFeaturePublisher: AnyPublisher<WalletModelFeature?, Never> = .just(output: nil)

    init(
        nftFeatureManager: NFT,
        dynamicAddressesFeatureManager: DynamicAddresses,
        transactionHistoryFeatureManager: TransactionHistory
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
            nftFeatureManager.featurePayload.map(WalletModelFeature.nft(networkService:)),
            dynamicAddressesFeatureManager.featurePayload.map(WalletModelFeature.dynamicAddresses(manager:)),
            transactionHistoryFeatureManager.featurePayload.map(WalletModelFeature.transactionHistory(provider:)),
        ].compactMap { $0 }
    }

    var featuresPublisher: AnyPublisher<[WalletModelFeature], Never> {
        [
            nftFeatureManager.featurePayloadPublisher
                .map { $0.map(WalletModelFeature.nft(networkService:)) }
                .eraseToAnyPublisher(),
            dynamicAddressesFeatureManager.featurePayloadPublisher
                .map { $0.map(WalletModelFeature.dynamicAddresses(manager:)) }
                .eraseToAnyPublisher(),
            transactionHistoryFeatureManager.featurePayloadPublisher
                .map { $0.map(WalletModelFeature.transactionHistory(provider:)) }
                .eraseToAnyPublisher(),
            stakingFeaturePublisher,
        ]
        .combineLatest()
        .map { $0.compactMap(\.self) }
        .eraseToAnyPublisher()
    }
}
