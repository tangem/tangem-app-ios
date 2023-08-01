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
    let coordinator: MultiWalletMainContentRoutable & SingleWalletMainContentRoutable

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
                let viewModel = MultiWalletMainContentViewModel(coordinator: coordinator)

                return .multiWallet(
                    id: id,
                    headerModel: headerModel,
                    bodyModel: viewModel
                )
            }

            let viewModel = SingleWalletMainContentViewModel(coordinator: coordinator)
            return .singleWallet(
                id: id,
                headerModel: headerModel,
                bodyModel: viewModel
            )
        }
    }
}
