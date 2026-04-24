//
//  CommonWalletModelNFTFeatureManager.swift
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

final class CommonWalletModelNFTFeatureManager {
    @Injected(\.nftAvailabilityProvider) private var nftAvailabilityProvider: NFTAvailabilityProvider

    private let userWalletId: UserWalletId
    private let userWalletConfig: UserWalletConfig
    private let tokenItem: TokenItem

    private lazy var _nftFeaturePublisher: some Publisher<WalletModelFeature?, Never> = nftAvailabilityProvider
        .didChangeNFTAvailabilityPublisher
        .receiveOnMain()
        .withWeakCaptureOf(self)
        .map { featuresManager, _ in
            guard
                featuresManager.isNFTAvailable,
                let networkService = featuresManager.nftNetworkService
            else {
                return nil
            }

            return .nft(networkService: networkService)
        }

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

// MARK: - WalletModelNFTFeatureManager protocol conformance

extension CommonWalletModelNFTFeatureManager: WalletModelNFTFeatureManager {
    var nftFeature: WalletModelFeature? {
        guard isNFTAvailable, let networkService = nftNetworkService else {
            return nil
        }
        return .nft(networkService: networkService)
    }

    var nftFeaturePublisher: AnyPublisher<WalletModelFeature?, Never> {
        _nftFeaturePublisher.eraseToAnyPublisher()
    }
}
