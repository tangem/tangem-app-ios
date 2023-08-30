//
//  MainUserWalletPageBuilderFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol MainUserWalletPageBuilderFactory {
    func createPage(for model: UserWalletModel, lockedUserWalletDelegate: MainLockedUserWalletDelegate) -> MainUserWalletPageBuilder?
    func createPages(from models: [UserWalletModel], lockedUserWalletDelegate: MainLockedUserWalletDelegate) -> [MainUserWalletPageBuilder]
}

struct CommonMainUserWalletPageBuilderFactory: MainUserWalletPageBuilderFactory {
    let coordinator: MultiWalletMainContentRoutable & SingleWalletMainContentRoutable

    func createPage(for model: UserWalletModel, lockedUserWalletDelegate: MainLockedUserWalletDelegate) -> MainUserWalletPageBuilder? {
        let id = model.userWalletId
        let containsDefaultToken = (model.config.defaultBlockchains.first?.tokens.count ?? 0) > 0
        let isMultiWalletPage = model.isMultiWallet || containsDefaultToken
        let subtitleProvider = MainHeaderSubtitleProviderFactory().provider(for: model, isMultiWallet: isMultiWalletPage)
        let headerModel = MainHeaderViewModel(
            infoProvider: model,
            subtitleProvider: subtitleProvider,
            balanceProvider: model
        )

        if model.isUserWalletLocked {
            return .lockedWallet(
                id: id,
                headerModel: headerModel,
                bodyModel: .init(
                    userWalletModel: model,
                    isMultiWallet: isMultiWalletPage,
                    lockedUserWalletDelegate: lockedUserWalletDelegate
                )
            )
        }

        if isMultiWalletPage {
            let sectionsAdapter = makeSectionsAdapter(for: model)
            let viewModel = MultiWalletMainContentViewModel(
                userWalletModel: model,
                coordinator: coordinator,
                tokenSectionsAdapter: sectionsAdapter,
                canManageTokens: model.isMultiWallet // [REDACTED_TODO_COMMENT]
            )

            return .multiWallet(
                id: id,
                headerModel: headerModel,
                bodyModel: viewModel
            )
        }

        guard let walletModel = model.walletModelsManager.walletModels.first else {
            return nil
        }

        let exchangeUtility = ExchangeCryptoUtility(
            blockchain: walletModel.blockchainNetwork.blockchain,
            address: walletModel.wallet.address,
            amountType: walletModel.amountType
        )

        let viewModel = SingleWalletMainContentViewModel(
            userWalletModel: model,
            walletModel: walletModel,
            userTokensManager: model.userTokensManager,
            exchangeUtility: exchangeUtility,
            coordinator: coordinator
        )

        return .singleWallet(
            id: id,
            headerModel: headerModel,
            bodyModel: viewModel
        )
    }

    func createPages(from models: [UserWalletModel], lockedUserWalletDelegate: MainLockedUserWalletDelegate) -> [MainUserWalletPageBuilder] {
        return models.compactMap { createPage(for: $0, lockedUserWalletDelegate: lockedUserWalletDelegate) }
    }

    private func makeSectionsAdapter(for model: UserWalletModel) -> TokenSectionsAdapter {
        let optionsManager = OrganizeTokensOptionsManager(userTokensReorderer: model.userTokensManager)

        return TokenSectionsAdapter(
            userTokenListManager: model.userTokenListManager,
            optionsProviding: optionsManager,
            preservesLastSortedOrderOnSwitchToDragAndDrop: false
        )
    }
}
