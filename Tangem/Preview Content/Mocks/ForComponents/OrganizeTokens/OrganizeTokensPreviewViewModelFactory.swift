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
        let walletModelComponentsBuilder = WalletModelComponentsBuilder(
            supportedBlockchains: userWalletModel.config.supportedBlockchains
        )
        let organizeTokensSectionsAdapter = OrganizeTokensSectionsAdapter(
            userTokenListManager: userWalletModel.userTokenListManager,
            walletModelComponentsBuilder: walletModelComponentsBuilder,
            organizeTokensOptionsProviding: optionsManager
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
