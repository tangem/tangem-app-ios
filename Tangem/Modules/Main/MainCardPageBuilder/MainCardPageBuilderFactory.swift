//
//  MainCardPageBuilderFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol MainPageContentFactory {
    func createPages(from models: [UserWalletModel]) -> [CardMainPageBuilder]
    func createPage(for model: UserWalletModel) -> CardMainPageBuilder
}

struct CommonMainPageContentFactory: MainPageContentFactory {
    func createPages(from models: [UserWalletModel]) -> [CardMainPageBuilder] {
        return models.map(createPage(for:))
    }

    func createPage(for model: UserWalletModel) -> CardMainPageBuilder {
        let id = model.userWalletId.stringValue
        let subtitleProvider = CardHeaderSubtitleProviderFactory().provider(for: model)

        if model.isMultiWallet {
            let coordinator = MultiWalletContentCoordinator()
            coordinator.start(with: .init())
            let header = CardHeaderViewModel(
                cardInfoProvider: model,
                cardSubtitleProvider: subtitleProvider,
                balanceProvider: model
            )

            return .multiWallet(
                id: id,
                headerModel: header,
                bodyModel: coordinator
            )
        }

        let coordinator = SingleWalletContentCoordinator()
        coordinator.start(with: .init())
        let header = CardHeaderViewModel(
            cardInfoProvider: model,
            cardSubtitleProvider: subtitleProvider,
            balanceProvider: model
        )
        return .singleWallet(
            id: id,
            headerModel: header,
            bodyModel: coordinator
        )
    }
}
