//
//  MainNavigationViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemUI

final class MainNavigationViewModel: ObservableObject {
    @Published private(set) var balance: MainNavigationBalanceState

    private let balanceProvider: MainNavigationBalanceProvider

    init(balanceProvider: MainNavigationBalanceProvider) {
        self.balanceProvider = balanceProvider
        balance = balanceProvider.balance
        bind()
    }
}

private extension MainNavigationViewModel {
    func bind() {
        balanceProvider.balancePublisher
            .removeDuplicates()
            .receiveOnMain()
            .assign(to: &$balance)
    }
}
