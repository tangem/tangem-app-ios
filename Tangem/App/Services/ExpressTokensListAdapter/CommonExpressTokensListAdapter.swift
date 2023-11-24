//
//  CommonExpressTokensListAdapter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation
import Combine

struct CommonExpressTokensListAdapter {
    let userWallet: UserWalletModel
    let adapter: TokenSectionsAdapter

    init(userWallet: UserWalletModel) {
        self.userWallet = userWallet
        adapter = TokenSectionsAdapter(
            userTokenListManager: userWallet.userTokenListManager,
            optionsProviding: OrganizeTokensOptionsManager(userTokensReorderer: userWallet.userTokensManager),
            preservesLastSortedOrderOnSwitchToDragAndDrop: false
        )
    }
}

extension CommonExpressTokensListAdapter: ExpressTokensListAdapter {
    func walletModels() -> AnyPublisher<[WalletModel], Never> {
        let just = Just(userWallet.walletModelsManager.walletModels)
        return adapter
            .organizedSections(from: just, on: .global())
            .map { section -> [WalletModel] in
                section.flatMap { $0.items.compactMap { $0.walletModel } }
            }
            .eraseToAnyPublisher()
    }
}

private extension TokenSectionsAdapter.SectionItem {
    var walletModel: WalletModel? {
        switch self {
        case .default(let walletModel):
            return walletModel
        case .withoutDerivation:
            return nil
        }
    }
}
