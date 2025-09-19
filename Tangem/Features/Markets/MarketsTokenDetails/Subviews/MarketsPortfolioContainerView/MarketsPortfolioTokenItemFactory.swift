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
        entries: [StoredUserTokenList.Entry],
        userWalletInfo: UserWalletInfo,
        userWalletConfig: UserWalletConfig,
        totalBalanceProvider: TotalBalanceProviding
    ) -> [MarketsPortfolioTokenItemViewModel] {
        let walletModelsKeyedByIds = walletModels.keyedFirst(by: \.id)
        let blockchainNetworksFromWalletModels = walletModels
            .map(\.tokenItem.blockchainNetwork)
            .toSet()

        let l2BlockchainsIds = SupportedBlockchains.l2Blockchains.map { $0.coinId }

        let tokenItemTypes: [TokenItemType] = entries
            .filter { entry in
                if entry.coinId == coinId {
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
                    return walletModelsKeyedByIds[userToken.walletModelId].map { .default($0) }
                } else {
                    // Section item for entry without derivation (yet)
                    return .withoutDerivation(userToken)
                }
            }

        let viewModels = tokenItemTypes.map {
            makeTokenItemViewModel(
                tokenItemType: $0,
                userWalletInfo: userWalletInfo,
                userWalletConfig: userWalletConfig,
                totalBalanceProvider: totalBalanceProvider
            )
        }

        return viewModels
    }

    private func makeTokenItemViewModel(
        tokenItemType: TokenItemType,
        userWalletInfo: UserWalletInfo,
        userWalletConfig: UserWalletConfig,
        totalBalanceProvider: TotalBalanceProviding
    ) -> MarketsPortfolioTokenItemViewModel {
        let (id, provider, tokenItem, tokenIcon) = tokenItemInfoProviderItemBuilder
            .mapTokenItemViewModel(from: tokenItemType)

        let balanceRestrictionFeatureAvailabilityProvider = BalanceRestrictionFeatureAvailabilityProvider(
            userWalletConfig: userWalletConfig,
            totalBalanceProvider: totalBalanceProvider
        )

        return MarketsPortfolioTokenItemViewModel(
            walletModelId: id,
            userWalletId: userWalletInfo.userWalletId,
            walletName: userWalletInfo.userWalletName,
            tokenIcon: tokenIcon,
            tokenItem: tokenItem,
            tokenItemInfoProvider: provider,
            balanceRestrictionFeatureAvailabilityProvider: balanceRestrictionFeatureAvailabilityProvider,
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
}
