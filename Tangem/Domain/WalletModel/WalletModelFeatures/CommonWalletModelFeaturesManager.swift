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
    @Injected(\.yieldModuleAvailabilityProvider) private var yieldModuleAvailabilityProvider: YieldModuleAvailabilityProvider

    private let userWalletId: UserWalletId
    private let userWalletConfig: UserWalletConfig
    private let tokenItem: TokenItem
    private let walletManager: WalletManager

    // MARK: - NFT

    private lazy var nftFeaturePublisher: some Publisher<[WalletModelFeature], Never> = nftAvailabilityProvider
        .didChangeNFTAvailabilityPublisher
        .receiveOnMain()
        .withWeakCaptureOf(self)
        .map { featuresManager, _ in
            guard
                featuresManager.isNFTAvailable,
                let networkService = featuresManager.nftNetworkService
            else {
                return []
            }

            return [.nft(networkService: networkService)]
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

    // MARK: - Staking

    // [REDACTED_TODO_COMMENT]
    private lazy var stakingFeaturePublisher: some Publisher<[WalletModelFeature], Never> = Just([])

    // MARK: - Transaction history

    // [REDACTED_TODO_COMMENT]
    private lazy var transactionHistoryFeaturePublisher: some Publisher<[WalletModelFeature], Never> = Just([])
    
    // MARK: - Yield module
    
    private lazy var yieldModuleFeaturePublisher: some Publisher<[WalletModelFeature], Never> = {
        let publisher: Just<[WalletModelFeature]> = if let factory = yieldModuleManagerFactory {
            Just([WalletModelFeature.yieldModule(managerFactory: factory)])
        } else {
            Just([])
        }
        return publisher.eraseToAnyPublisher()
    }()
    
    private var isYieldModuleAvailable: Bool {
        yieldModuleAvailabilityProvider.isYieldModuleAvailable()
    }
    
    private var _yieldModuleManagerFactory: YieldModuleManagerFactory?
    private var yieldModuleManagerFactory: YieldModuleManagerFactory? {
        if isYieldModuleAvailable,
           let token = tokenItem.token,
           let ethereumNetworkProvider = walletManager as? EthereumNetworkProvider,
           let yieldTokenService = walletManager as? YieldTokenService,
           let ethereumTransactionDataBuilder = walletManager as? EthereumTransactionDataBuilder {
            let factory = _yieldModuleManagerFactory ?? CommonYieldModuleManagerFactory(
                token: token,
                blockchain: tokenItem.blockchain,
                signer: userWalletConfig.tangemSigner,
                ethereumNetworkProvider: ethereumNetworkProvider,
                yieldTokenService: yieldTokenService,
                ethereumTransactionDataBuilder: ethereumTransactionDataBuilder
            )
            _yieldModuleManagerFactory = factory
        } else {
            _yieldModuleManagerFactory = nil
        }

        return _yieldModuleManagerFactory
    }

    init(
        userWalletId: UserWalletId,
        userWalletConfig: UserWalletConfig,
        tokenItem: TokenItem,
        walletManager: WalletManager
    ) {
        self.userWalletId = userWalletId
        self.userWalletConfig = userWalletConfig
        self.tokenItem = tokenItem
        self.walletManager = walletManager
    }
}

// MARK: - WalletModelFeaturesManager protocol conformance

extension CommonWalletModelFeaturesManager: WalletModelFeaturesManager {
    var featuresPublisher: AnyPublisher<[WalletModelFeature], Never> {
        return Publishers.CombineLatest4(
            nftFeaturePublisher,
            stakingFeaturePublisher,
            transactionHistoryFeaturePublisher,
            yieldModuleFeaturePublisher,
        )
        .map { $0.0 + $0.1 + $0.2 + $0.3 }
        .eraseToAnyPublisher()
    }
}
