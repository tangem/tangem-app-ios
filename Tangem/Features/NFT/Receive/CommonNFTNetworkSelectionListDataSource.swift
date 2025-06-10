//
//  CommonNFTNetworkSelectionListDataSource.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemNFT
import BlockchainSdk
import TangemSdk
import TangemFoundation

final class CommonNFTNetworkSelectionListDataSource {
    private let walletModelsManager: WalletModelsManager
    private let userWalletConfig: UserWalletConfig

    private var isTestnet: Bool { AppEnvironment.current.isTestnet }

    /// - Note: Cached for performance reasons.
    private lazy var availableNFTChainItems: [NFTChainItem] = {
        let nftAvailabilityUtil = NFTAvailabilityUtil(userWalletConfig: userWalletConfig)

        return walletModelsManager
            .walletModels
            .filter { nftAvailabilityUtil.isNFTAvailable(for: $0.tokenItem) }
            .compactMap { walletModel -> NFTChainItem? in
                let tokenItem = walletModel.tokenItem

                guard let nftChain = NFTChainConverter.convert(tokenItem.blockchain) else {
                    return nil
                }

                return NFTChainItem(
                    nftChain: nftChain,
                    isCustom: walletModel.isCustom,
                    displayName: walletModel.tokenItem.networkName,
                    underlyingIdentifier: walletModel.id.id
                )
            }
    }()

    init(
        walletModelsManager: WalletModelsManager,
        userWalletConfig: UserWalletConfig
    ) {
        self.walletModelsManager = walletModelsManager
        self.userWalletConfig = userWalletConfig
    }

    /// - Note: This method creates dummy token items that are only used for validation in `NFTAvailabilityUtil` and as the source
    /// of the `displayName` property for `NFTChainItem`. Such token items should never be used in the actual domain layer of the app.
    private func makeTokenItem(for nftChain: NFTChain) -> TokenItem {
        // [REDACTED_TODO_COMMENT]
        // The dummy hardcoded `version` is used here since it has no effect on the availability checks in `NFTAvailabilityUtil`
        let blockchain = NFTChainConverter.convert(nftChain, version: .v2)
        // We don't care about derivation path here since there are no wallet models for all these token items in the `walletModelsManager`
        // All token items, created in this method, are essentially virtual and don't exist in the model layer
        let blockchainNetwork = BlockchainNetwork(blockchain, derivationPath: nil)

        return .blockchain(blockchainNetwork)
    }
}

// MARK: - NFTNetworkSelectionListDataSource protocol conformance

extension CommonNFTNetworkSelectionListDataSource: NFTNetworkSelectionListDataSource {
    func allSupportedChains() -> [NFTChainItem] {
        let nftAvailabilityUtil = NFTAvailabilityUtil(userWalletConfig: userWalletConfig)

        // This set acts as a filter to prevent duplicate entries (from both `walletModelsManager.walletModels` and `NFTChain.allCases`)
        let availableNFTChains = availableNFTChainItems
            .map(\.nftChain)
            .toSet()

        let unavailableNFTChainItems = NFTChain
            .allCases(isTestnet: isTestnet)
            .filter { !availableNFTChains.contains($0) }
            .map { ($0, makeTokenItem(for: $0)) }
            .filter { nftAvailabilityUtil.isNFTAvailable(for: $0.1) }
            .map { NFTChainItem(nftChain: $0.0, isCustom: false, displayName: $0.1.networkName, underlyingIdentifier: nil) }

        return availableNFTChainItems + unavailableNFTChainItems
    }

    func isSupportedChainAvailable(_ nftChainItem: NFTChainItem) -> Bool {
        return availableNFTChainItems.contains(nftChainItem)
    }
}
