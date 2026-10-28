//
//  TangemPayMoneyAccountViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

@MainActor
final class TangemPayMoneyAccountViewModel: ObservableObject {
    @Published private(set) var stateModel: TangemPayMoneyAccountStateModel

    private let userWalletModel: any UserWalletModel
    private let output: (Output) -> Void

    init(
        userWalletModel: any UserWalletModel,
        output: @escaping (Output) -> Void
    ) {
        self.userWalletModel = userWalletModel
        self.output = output

        stateModel = TangemPayMoneyAccountStateModel()
    }

    func handleAction(_ action: TangemPayMoneyAccountAction) {
        switch action {
        case .topup:
            output(.topup)

        case .withdraw:
            output(.withdraw)
        }
    }
}

// MARK: - Output

extension TangemPayMoneyAccountViewModel {
    enum Output {
        case topup
        case withdraw
    }
}
