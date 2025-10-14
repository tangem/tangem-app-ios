//
//  NewTokenSelectorItemViewModelMapper.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

protocol NewTokenSelectorItemViewModelMapper {
    func mapToNewTokenSelectorWalletItemViewModel(wallet: NewTokenSelectorWallet) -> NewTokenSelectorWalletItemViewModel

    func mapToNewTokenSelectorAccountViewModel(
        header: NewTokenSelectorAccountViewModel.HeaderType,
        account: NewTokenSelectorAccount
    ) -> NewTokenSelectorAccountViewModel

    func mapToNewTokenSelectorItemViewModel(item: NewTokenSelectorItem) -> NewTokenSelectorItemViewModel
}
