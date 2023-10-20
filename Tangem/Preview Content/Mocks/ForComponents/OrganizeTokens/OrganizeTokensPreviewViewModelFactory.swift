//
//  OrganizeTokensPreviewViewModelFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct OrganizeTokensPreviewViewModelFactory {
    func makeViewModel() -> OrganizeTokensViewModel {
        let coordinator = OrganizeTokensRoutableStub()
        let userWalletModel = UserWalletModelMock()
        let optionsManager = OrganizeTokensOptionsManagerStub(
            initialGroupingOption: .none,
            initialSortingOption: .dragAndDrop
        )
        let tokenSectionsAdapter = TokenSectionsAdapter(
            userTokenListManager: userWalletModel.userTokenListManager,
            optionsProviding: optionsManager,
            preservesLastSortedOrderOnSwitchToDragAndDrop: false
        )

        return OrganizeTokensViewModel(
            coordinator: coordinator,
            walletModelsManager: userWalletModel.walletModelsManager,
            tokenSectionsAdapter: tokenSectionsAdapter,
            optionsProviding: optionsManager,
            optionsEditing: optionsManager
        )
    }
}
