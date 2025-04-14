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
import TangemFoundation

final class CommonWalletModelFeaturesManager {
    @Injected(\.nftAvailabilityProvider) private var nftAvailabilityProvider: NFTAvailabilityProvider

    private let userWalletId: UserWalletId
    private let userWalletConfig: UserWalletConfig
    private let tokenItem: TokenItem

    // MARK: - NFT

    private lazy var nftFeaturePublisher: AnyPublisher<[WalletModelFeature], Never> = {
        guard isNFTAvailable else {
            return .just(output: [])
                .append(Empty(completeImmediately: false)) // Prevents `nftFeaturePublisher` from completion
                .eraseToAnyPublisher()
        }

        return nftAvailabilityProvider
            .didChangeNFTAvailabilityPublisher
            .receive(on: DispatchQueue.main)
            .withWeakCaptureOf(self)
            .map { featuresManager, _ in
                guard let networkService = featuresManager.nftNetworkService else {
                    return []
                }

                return [.nft(networkService: networkService)]
            }
            .eraseToAnyPublisher()
    }()

    /// Can change its value at runtime.
    private var isNFTEnabledForWallet: Bool {
        nftAvailabilityProvider.isNFTEnabled(forUserWalletWithId: userWalletId)
    }

    /// Can't change its value at runtime.
    private var isNFTAvailable: Bool {
        let nftAvailabilityUtil = NFTAvailabilityUtil(userWalletConfig: userWalletConfig)

        return nftAvailabilityProvider.isNFTAvailable(for: userWalletConfig) && nftAvailabilityUtil.isNFTAvailable(for: tokenItem)
    }

    private var _nftNetworkService: NFTNetworkService?

    private var nftNetworkService: NFTNetworkService? {
        if isNFTEnabledForWallet {
            let service = _nftNetworkService ?? NFTNetworkServiceFactory().makeNetworkService(for: tokenItem)
            _nftNetworkService = service
        } else {
            _nftNetworkService = nil
        }

        return _nftNetworkService
    }

    // MARK: - Staking

    // [REDACTED_TODO_COMMENT]
    private lazy var stakingFeaturePublisher: AnyPublisher<[WalletModelFeature], Never> = .just(output: [])

    // MARK: - Transaction history

    // [REDACTED_TODO_COMMENT]
    private lazy var transactionHistoryFeaturePublisher: AnyPublisher<[WalletModelFeature], Never> = .just(output: [])

    init(
        userWalletId: UserWalletId,
        userWalletConfig: UserWalletConfig,
        tokenItem: TokenItem
    ) {
        self.userWalletId = userWalletId
        self.userWalletConfig = userWalletConfig
        self.tokenItem = tokenItem
    }
}

// MARK: - WalletModelFeaturesManager protocol conformance

extension CommonWalletModelFeaturesManager: WalletModelFeaturesManager {
    var featuresPublisher: AnyPublisher<[WalletModelFeature], Never> {
        let featurePublishers = [
            nftFeaturePublisher,
            stakingFeaturePublisher,
            transactionHistoryFeaturePublisher,
        ]

        return featurePublishers
            .combineLatest()
            .map { $0.flattened() }
            .eraseToAnyPublisher()
    }
}
