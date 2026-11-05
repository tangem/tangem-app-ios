//
//  TangemPayMoneyAccountFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import SwiftUI

enum TangemPayMoneyAccountFactory {
    @MainActor
    static func makeView(
        userWalletModel: any UserWalletModel,
        moneyAccount: any TangemPayMoneyAccountModel,
        output: @escaping (TangemPayMoneyAccountViewModel.Output) -> Void
    ) -> some View {
        TangemPayMoneyAccountView(
            viewModel: TangemPayMoneyAccountViewModel(
                userWalletModel: userWalletModel,
                moneyAccount: moneyAccount,
                output: output
            )
        )
    }
}
