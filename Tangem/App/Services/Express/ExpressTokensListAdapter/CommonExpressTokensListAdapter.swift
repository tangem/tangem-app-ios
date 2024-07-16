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
    private let userWalletModel: UserWalletModel
    private let adapter: TokenSectionsAdapter

    init(userWalletModel: UserWalletModel) {
        self.userWalletModel = userWalletModel
        adapter = TokenSectionsAdapter(
            userTokenListManager: userWalletModel.userTokenListManager,
            optionsProviding: OrganizeTokensOptionsManager(userTokensReorderer: userWalletModel.userTokensManager),
            preservesLastSortedOrderOnSwitchToDragAndDrop: false
        )
    }
}

extension CommonExpressTokensListAdapter: ExpressTokensListAdapter {
    func walletModels() -> AnyPublisher<[WalletModel], Never> {
        let sourcePublisherFactory = TokenSectionsSourcePublisherFactory()
        let tokenSectionsSourcePublisher = sourcePublisherFactory.makeSourcePublisher(for: userWalletModel)

        return adapter
            .organizedSections(from: tokenSectionsSourcePublisher, on: .global())
            .map { section -> [WalletModel] in
                section.flatMap { $0.items.compactMap { $0.walletModel } }
            }
            .eraseToAnyPublisher()
    }
}
