//
//  OrganizeTokensPreviewViewModelFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

struct OrganizeTokensPreviewViewModelFactory {
    func makeViewModel(for configuration: OrganizeTokensPreviewConfiguration) -> OrganizeTokensViewModel {
        let coordinator = OrganizeTokensRoutableStub()
        let userWalletModel = FakeUserWalletModel.walletWithoutDelay
        let optionsManager = FakeOrganizeTokensOptionsManager(
            initialGroupingOption: configuration.groupingOption,
            initialSortingOption: configuration.sortingOption
        )
        let tokenSectionsAdapter = TokenSectionsAdapter(
            userTokensManager: userWalletModel.userTokensManager,
            optionsProviding: optionsManager,
            preservesLastSortedOrderOnSwitchToDragAndDrop: false
        )

        return OrganizeTokensViewModel(
            userWalletModel: userWalletModel,
            tokenSectionsAdapter: tokenSectionsAdapter,
            optionsProviding: optionsManager,
            optionsEditing: optionsManager,
            coordinator: coordinator
        )
    }
}
