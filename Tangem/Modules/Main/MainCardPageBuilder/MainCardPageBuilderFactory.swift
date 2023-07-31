//
//  MainCardPageBuilderFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol MainCardPageBuilderFactory {
    func createPages(from models: [UserWalletModel]) -> [MainCardPageBuilder]
}

struct CommonMainCardPageBuilderFactory: MainCardPageBuilderFactory {
    func createPages(from models: [UserWalletModel]) -> [MainCardPageBuilder] {
        return models.map {
            let id = $0.userWalletId.stringValue
            let subtitleProvider = CardHeaderSubtitleProviderFactory().provider(for: $0)

            if $0.isMultiWallet {
                let coordinator = MultiWalletContentCoordinator()
                coordinator.start(with: .init())
                let header = CardHeaderViewModel(
                    cardInfoProvider: $0,
                    cardSubtitleProvider: subtitleProvider,
                    balanceProvider: $0
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
                cardInfoProvider: $0,
                cardSubtitleProvider: subtitleProvider,
                balanceProvider: $0
            )
            return .singleWallet(
                id: id,
                headerModel: header,
                bodyModel: coordinator
            )
        }
    }
}
