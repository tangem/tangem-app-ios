//
//  AccountSelectorAccountCellViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

@MainActor
final class AccountSelectorAccountCellViewModel: ObservableObject {
    // MARK: Public Properties

    let accountModel: AccountSelectorAccountItem

    // MARK: Published Properties

    @Published private(set) var fiatBalanceState: LoadableTokenBalanceView.State = .loading()

    // MARK: Private Properties

    private var bag = Set<AnyCancellable>()

    init(accountModel: AccountSelectorAccountItem) {
        self.accountModel = accountModel

        bind()
    }

    // MARK: Private Methods

    private func bind() {
        accountModel.formattedBalanceTypePublisher
            .withWeakCaptureOf(self)
            .sink { viewModel, balanceState in
                viewModel.fiatBalanceState = balanceState
            }
            .store(in: &bag)
    }
}
