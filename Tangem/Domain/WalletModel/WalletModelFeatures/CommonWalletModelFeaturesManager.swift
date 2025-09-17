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
import BlockchainSdk

final class CommonWalletModelFeaturesManager {
    @Injected(\.nftAvailabilityProvider) private var nftAvailabilityProvider: NFTAvailabilityProvider

    private let userWalletId: UserWalletId
    private let userWalletConfig: UserWalletConfig
    private let tokenItem: TokenItem
    private let blockchainDataProvider: BlockchainDataProvider

    private let featuresValueSubject: CurrentValueSubject<[WalletModelFeature], Never> = .init([])
    private var cancellables = Set<AnyCancellable>()

    // MARK: - NFT

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

    // MARK: - Init

    init(
        userWalletId: UserWalletId,
        userWalletConfig: UserWalletConfig,
        tokenItem: TokenItem,
        blockchainDataProvider: BlockchainDataProvider
    ) {
        self.userWalletId = userWalletId
        self.userWalletConfig = userWalletConfig
        self.tokenItem = tokenItem
        self.blockchainDataProvider = blockchainDataProvider

        setupFeatureSubscriptions()
        updateFeatures()
    }

    // MARK: - Private Methods

    private func updateFeatures() {
        var allFeatures: [WalletModelFeature] = []

        // MARK: - NFT

        if let nftNetworkService, isNFTAvailable, isNFTEnabledForWallet {
            allFeatures.append(contentsOf: [.nft(networkService: nftNetworkService)])
        }

        // MARK: - Staking

        // [REDACTED_TODO_COMMENT]

        // MARK: - Transaction history

        // [REDACTED_TODO_COMMENT]

        // MARK: - Send

        allFeatures.append(contentsOf: [
            .send(logger: CommonNetworkProviderAnalyticsLogger(dataProvider: blockchainDataProvider)),
        ])

        featuresValueSubject.send(allFeatures.compactMap { $0 })
    }

    private func setupFeatureSubscriptions() {
        // NFT
        nftAvailabilityProvider
            .didChangeNFTAvailabilityPublisher
            .receiveOnMain()
            .sink { [weak self] _ in
                self?.updateFeatures()
            }
            .store(in: &cancellables)

        // Any Service Subscriptions
    }
}

// MARK: - WalletModelFeaturesManager protocol conformance

extension CommonWalletModelFeaturesManager: WalletModelFeaturesManager {
    var featuresPublisher: AnyPublisher<[WalletModelFeature], Never> {
        featuresValueSubject
            .dropFirst()
            .eraseToAnyPublisher()
    }

    var features: [WalletModelFeature] {
        featuresValueSubject.value
    }
}
