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
    private let walletModelsManager: WalletModelsManager
    private let adapter: TokenSectionsAdapter

    init(
        walletModelsManager: WalletModelsManager,
        userTokenListManager: UserTokenListManager,
        userTokensManager: UserTokensManager
    ) {
        self.walletModelsManager = walletModelsManager
        adapter = TokenSectionsAdapter(
            userTokenListManager: userTokenListManager,
            optionsProviding: OrganizeTokensOptionsManager(userTokensReorderer: userTokensManager),
            preservesLastSortedOrderOnSwitchToDragAndDrop: false
        )
    }
}

extension CommonExpressTokensListAdapter: ExpressTokensListAdapter {
    func walletModels() -> AnyPublisher<[WalletModel], Never> {
        let just = Just(walletModelsManager.walletModels)
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
