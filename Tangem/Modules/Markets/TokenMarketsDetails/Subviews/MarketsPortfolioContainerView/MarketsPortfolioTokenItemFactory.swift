//
//  MarketsPortfolioTokenItemFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation

struct MarketsPortfolioTokenItemFactory {
    private let contextActionsProvider: MarketsPortfolioContextActionsProvider
    private let contextActionsDelegate: MarketsPortfolioContextActionsDelegate
    private var quickActionDisclosureTap: ((Int) -> Void)?

    private let tokenItemInfoProviderMapper = TokenItemInfoProviderMapper()

    // MARK: - Init

    init(
        contextActionsProvider: MarketsPortfolioContextActionsProvider,
        contextActionsDelegate: MarketsPortfolioContextActionsDelegate,
        quickActionDisclosureTap: ((Int) -> Void)? = nil
    ) {
        self.contextActionsProvider = contextActionsProvider
        self.contextActionsDelegate = contextActionsDelegate
        self.quickActionDisclosureTap = quickActionDisclosureTap
    }

    // MARK: - Implementation

    func makeViewModels(
        coinId: String,
        networks: [NetworkModel],
        walletModels: [WalletModel],
        entries: [StoredUserTokenList.Entry],
        userWalletInfo: UserWalletInfo
    ) -> [MarketsPortfolioTokenItemViewModel] {
        let walletModelsKeyedByIds = walletModels.keyedFirst(by: \.id)
        let blockchainNetworksFromWalletModels = walletModels
            .map(\.blockchainNetwork)
            .toSet()

        let networkIds = Set(networks.map { $0.networkId })

        let tokenItemTypes: [TokenItemType] = entries
            .filter { entry in
                entry.id == coinId && networkIds.contains(entry.blockchainNetwork.blockchain.networkId)
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
            makeTokenItemViewModel(from: $0, with: userWalletInfo)
        }

        return viewModels
    }

    private func makeTokenItemViewModel(
        from tokenItemType: TokenItemType,
        with userWalletInfo: UserWalletInfo
    ) -> MarketsPortfolioTokenItemViewModel {
        let infoProviderItem = tokenItemInfoProviderMapper.mapTokenItemViewModel(from: tokenItemType)
        let tokenIcon = TokenIconInfoBuilder().build(from: infoProviderItem.provider.tokenItem, isCustom: infoProviderItem.isCustom)

        return MarketsPortfolioTokenItemViewModel(
            userWalletId: userWalletInfo.userWalletId,
            walletName: userWalletInfo.userWalletName,
            tokenIcon: tokenIcon,
            tokenItemInfoProvider: infoProviderItem.provider,
            contextActionsProvider: contextActionsProvider,
            contextActionsDelegate: contextActionsDelegate
        ) { viewModelId in
            quickActionDisclosureTap?(viewModelId)
        }
    }
}

extension MarketsPortfolioTokenItemFactory {
    struct UserWalletInfo {
        let userWalletName: String
        let userWalletId: UserWalletId
    }
}
