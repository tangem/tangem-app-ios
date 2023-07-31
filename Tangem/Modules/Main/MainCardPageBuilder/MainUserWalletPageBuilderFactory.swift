//
//  MainUserWalletPageBuilderFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol MainUserWalletPageBuilderFactory {
    func createPage(for model: UserWalletModel) -> MainUserWalletPageBuilder
    func createPages(from models: [UserWalletModel]) -> [MainUserWalletPageBuilder]
}

struct CommonMainUserWalletPageBuilderFactory: MainUserWalletPageBuilderFactory {
    func createPage(for model: UserWalletModel) -> MainUserWalletPageBuilder {
        let id = model.userWalletId
        let subtitleProvider = MainHeaderSubtitleProviderFactory().provider(for: model)
        let headerModel = MainHeaderViewModel(
            infoProvider: model,
            subtitleProvider: subtitleProvider,
            balanceProvider: model
        )

        if model.isMultiWallet {
            let coordinator = MultiWalletMainContentCoordinator()
            coordinator.start(with: .init())

            return .multiWallet(
                id: id,
                headerModel: headerModel,
                bodyModel: coordinator
            )
        }

        let coordinator = SingleWalletMainContentCoordinator()
        coordinator.start(with: .init())
        return .singleWallet(
            id: id,
            headerModel: headerModel,
            bodyModel: coordinator
        )
    }

    func createPages(from models: [UserWalletModel]) -> [MainUserWalletPageBuilder] {
        return models.map(createPage(for:))
    }
}
