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
        let optionsManager = OrganizeTokensOptionsManagerStub()
        let organizeTokensSectionsAdapter = OrganizeTokensSectionsAdapter(
            userTokenListManager: userWalletModel.userTokenListManager,
            organizeTokensOptionsProviding: optionsManager,
            preservesLastSortedOrderOnSwitchToDragAndDrop: false
        )

        return OrganizeTokensViewModel(
            coordinator: coordinator,
            walletModelsManager: userWalletModel.walletModelsManager,
            organizeTokensSectionsAdapter: organizeTokensSectionsAdapter,
            organizeTokensOptionsProviding: optionsManager,
            organizeTokensOptionsEditing: optionsManager
        )
    }
}
