//
//  CommonExpressTokensListAdapter.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import TangemFoundation

/// Will be delete after accounts
/// [REDACTED_INFO]
struct CommonExpressTokensListAdapter {
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository

    private let userWalletId: UserWalletId

    init(userWalletId: UserWalletId) {
        self.userWalletId = userWalletId
    }
}

// MARK: - ExpressTokensListAdapter

extension CommonExpressTokensListAdapter: ExpressTokensListAdapter {
    func walletModels() -> AnyPublisher<[any WalletModel], Never> {
        guard let userWalletModel = userWalletRepository.models.first(where: { $0.userWalletId == userWalletId }) else {
            return .empty
        }

        // accounts_fixes_needed_none
        let tokenSectionsSourcePublisher = userWalletModel.walletModelsManager.walletModelsPublisher
        // accounts_fixes_needed_none
        let tokenSectionsAdapter = TokenSectionsAdapter(
            userTokensManager: userWalletModel.userTokensManager,
            optionsProviding: OrganizeTokensOptionsManager(
                userTokensReorderer: userWalletModel.userTokensManager
            ),
            preservesLastSortedOrderOnSwitchToDragAndDrop: false
        )

        return tokenSectionsAdapter
            .organizedSections(from: tokenSectionsSourcePublisher, on: .main)
            .map { section -> [any WalletModel] in
                withExtendedLifetime(tokenSectionsAdapter) {}

                return section.flatMap { $0.items.compactMap { $0.walletModel } }
            }
            .eraseToAnyPublisher()
    }
}
