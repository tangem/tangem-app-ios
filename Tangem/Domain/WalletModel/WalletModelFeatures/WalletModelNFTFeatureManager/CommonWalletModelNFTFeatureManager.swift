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

    private lazy var _nftNetworkServicePublisher: some Publisher<NFTNetworkService?, Never> = nftAvailabilityProvider
        .didChangeNFTAvailabilityPublisher
        .receiveOnMain()
        .withWeakCaptureOf(self)
        .map { featuresManager, _ in
            featuresManager.nftNetworkService
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

    init(
        userWalletId: UserWalletId,
        userWalletConfig: UserWalletConfig,
        tokenItem: TokenItem
    ) {
        self.userWalletId = userWalletId
        self.userWalletConfig = userWalletConfig
        self.tokenItem = tokenItem
    }

    // MARK: - Feature

    var nftNetworkService: NFTNetworkService? {
        guard isNFTAvailable else {
            return nil
        }

        if isNFTEnabledForWallet {
            let service = _nftNetworkService ?? NFTNetworkServiceFactory().makeNetworkService(for: tokenItem)
            _nftNetworkService = service
        } else {
            _nftNetworkService = nil
        }

        return _nftNetworkService
    }

    var nftNetworkServicePublisher: AnyPublisher<NFTNetworkService?, Never> {
        _nftNetworkServicePublisher.eraseToAnyPublisher()
    }
}
