//
//  MainUserWalletPageBuilderFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

protocol MainUserWalletPageBuilderFactory {
    func createPages(from models: [UserWalletModel]) -> [MainUserWalletPageBuilder]
}

struct CommonMainUserWalletPageBuilderFactory: MainUserWalletPageBuilderFactory {
    func createPages(from models: [UserWalletModel]) -> [MainUserWalletPageBuilder] {
        return models.map {
            let id = $0.userWalletId.stringValue
            let subtitleProvider = MainHeaderSubtitleProviderFactory().provider(for: $0)
            let headerModel = MainHeaderViewModel(
                infoProvider: $0,
                subtitleProvider: subtitleProvider,
                balanceProvider: $0
            )

            if $0.isMultiWallet {
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
    }
}
