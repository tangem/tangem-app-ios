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
    @Published private(set) var accountModel: AccountSelectorAccountItem
    @Published private(set) var fiatBalanceState: LoadableTokenBalanceView.State = .loading()

    private var bag = Set<AnyCancellable>()

    init(accountModel: AccountSelectorAccountItem) {
        self.accountModel = accountModel

        bind()
    }

    private func bind() {
        accountModel.domainModel.fiatAvailableBalanceProvider.formattedBalanceTypePublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, balanceType in
                viewModel.fiatBalanceState = LoadableTokenBalanceViewStateBuilder().build(type: balanceType)
            }
            .store(in: &bag)
    }
}
