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
        userTokensManager: UserTokensManager,
        walletModelsManager: WalletModelsManager
    ) {
        self.walletModelsManager = walletModelsManager

        adapter = TokenSectionsAdapter(
            userTokensManager: userTokensManager,
            optionsProviding: OrganizeTokensOptionsManager(userTokensReorderer: userTokensManager),
            preservesLastSortedOrderOnSwitchToDragAndDrop: false
        )
    }
}

// MARK: - ExpressTokensListAdapter

extension CommonExpressTokensListAdapter: ExpressTokensListAdapter {
    func walletModels() -> AnyPublisher<[any WalletModel], Never> {
        let tokenSectionsSourcePublisher = walletModelsManager.walletModelsPublisher

        return adapter
            .organizedSections(from: tokenSectionsSourcePublisher, on: .global())
            .map { section -> [any WalletModel] in
                section.flatMap { $0.items.compactMap { $0.walletModel } }
            }
            .eraseToAnyPublisher()
    }
}
