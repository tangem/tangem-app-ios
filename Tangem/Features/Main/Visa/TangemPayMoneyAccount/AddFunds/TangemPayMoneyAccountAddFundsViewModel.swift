//
//  TangemPayMoneyAccountAddFundsViewModel.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

final class TangemPayMoneyAccountAddFundsViewModel: Identifiable {
    let options: [TangemPayMoneyAccountAddFundsOption] = [.swap, .receive, .bankTransfer]

    private let onSelect: (TangemPayMoneyAccountAddFundsOption) -> Void

    init(onSelect: @escaping (TangemPayMoneyAccountAddFundsOption) -> Void) {
        self.onSelect = onSelect
    }

    func select(_ option: TangemPayMoneyAccountAddFundsOption) {
        onSelect(option)
    }
}
