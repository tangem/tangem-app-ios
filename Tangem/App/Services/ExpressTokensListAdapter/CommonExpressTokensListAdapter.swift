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
}

extension CommonExpressTokensListAdapter: ExpressTokensListAdapter {
    func walletModels() async -> AsyncStream<[WalletModel]> {
        let just = Just(userWallet.walletModelsManager.walletModels)
        let organizedTokensSectionsPublisher = makeAdapter()
            .organizedSections(from: just, on: .global())
            .map { section -> [WalletModel] in
                section.flatMap { section in
                    section.items.compactMap { item in
                        guard case .default(let walletModel) = item else {
                            return nil
                        }

                        return walletModel
                    }
                }
            }
            .replaceError(with: [])

        return await organizedTokensSectionsPublisher.values
    }
}

private extension CommonExpressTokensListAdapter {
    func makeAdapter() -> TokenSectionsAdapter {
        TokenSectionsAdapter(
            userTokenListManager: userWallet.userTokenListManager,
            optionsProviding: OrganizeTokensOptionsManager(userTokensReorderer: userWallet.userTokensManager),
            preservesLastSortedOrderOnSwitchToDragAndDrop: false
        )
    }
}
