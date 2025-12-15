//
//  MarketsPortfolioTokenItemFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import BlockchainSdk
import TangemFoundation

struct MarketsPortfolioTokenItemFactory {
    private let contextActionsProvider: MarketsPortfolioContextActionsProvider
    private let contextActionsDelegate: MarketsPortfolioContextActionsDelegate

    private let tokenItemInfoProviderItemBuilder = TokenItemInfoProviderItemBuilder()

    // MARK: - Init

    init(
        contextActionsProvider: MarketsPortfolioContextActionsProvider,
        contextActionsDelegate: MarketsPortfolioContextActionsDelegate
    ) {
        self.contextActionsProvider = contextActionsProvider
        self.contextActionsDelegate = contextActionsDelegate
    }

    // MARK: - Implementation

    func makeViewModels(
        coinId: String,
        walletModels: [any WalletModel],
        entries: [TokenItem],
        userWalletInfo: UserWalletInfo,
        namingStyle: NamingStyle = .userWalletName
    ) -> [MarketsPortfolioTokenItemViewModel] {
        let walletModelsKeyedByIds = walletModels.keyedFirst(by: \.id)
        let blockchainNetworksFromWalletModels = walletModels
            .map(\.tokenItem.blockchainNetwork)
            .toSet()

        let l2BlockchainsIds = SupportedBlockchains.l2Blockchains.map { $0.coinId }

        let tokenItemTypes: [TokenItemType] = entries
            .filter { entry in
                if entry.id == coinId {
                    return true
                }

                // add l2 networks
                if let entryId = entry.id,
                   coinId == Blockchain.ethereum(testnet: false).coinId,
                   l2BlockchainsIds.contains(entryId) {
                    return true
                }

                return false
            }
            .compactMap { userToken in
                if blockchainNetworksFromWalletModels.contains(userToken.blockchainNetwork) {
                    // Most likely we have wallet model (and derivation too) for this entry
                    return walletModelsKeyedByIds[WalletModelId(tokenItem: userToken)].map { .default($0) }
                } else {
                    // Section item for entry without derivation (yet)
                    return .withoutDerivation(userToken)
                }
            }

        let viewModels = tokenItemTypes.map {
            makeTokenItemViewModel(from: $0, with: userWalletInfo, namingStyle: namingStyle)
        }

        return viewModels
    }

    private func makeTokenItemViewModel(
        from tokenItemType: TokenItemType,
        with userWalletInfo: UserWalletInfo,
        namingStyle: NamingStyle
    ) -> MarketsPortfolioTokenItemViewModel {
        let (id, provider, tokenItem, tokenIcon) = tokenItemInfoProviderItemBuilder
            .mapTokenItemViewModel(from: tokenItemType)

        let name, description: String

        switch namingStyle {
        case .tokenItemName:
            name = tokenItem.name
            description = tokenItem.networkName

        case .userWalletName:
            name = userWalletInfo.userWalletName
            description = tokenItem.name
        }

        return MarketsPortfolioTokenItemViewModel(
            walletModelId: id,
            userWalletId: userWalletInfo.userWalletId,
            name: name,
            description: description,
            tokenIcon: tokenIcon,
            tokenItem: tokenItem,
            tokenItemInfoProvider: provider,
            contextActionsProvider: contextActionsProvider,
            contextActionsDelegate: contextActionsDelegate
        )
    }
}

extension MarketsPortfolioTokenItemFactory {
    struct UserWalletInfo {
        let userWalletName: String
        let userWalletId: UserWalletId
    }

    enum NamingStyle {
        case userWalletName
        case tokenItemName

        private var timeToRemove: Bool {
            // Run into compilation error here? This means .accounts toggle is removed
            // NamingStyle enum should be removed in favor of `.tokenItemName` case
            FeatureProvider.isAvailable(.accounts)
        }
    }
}
