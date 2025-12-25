//
//  OrganizeTokensPreviewViewModelFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Foundation

@available(iOS, deprecated: 100000.0, message: "Will be removed after accounts migration is complete ([REDACTED_INFO])")
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
