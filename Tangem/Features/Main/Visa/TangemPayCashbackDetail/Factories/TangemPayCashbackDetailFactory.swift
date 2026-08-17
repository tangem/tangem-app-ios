//
//  TangemPayCashbackDetailFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation

enum TangemPayCashbackDetailFactory {
    @MainActor
    static func makeViewModel(
        summary: TangemPayCashback.Summary,
        userWalletId: UserWalletId,
        dataProvider: some TangemPayCashbackDataProviding,
        dismiss handler: @escaping () -> Void
    ) -> TangemPayCashbackDetailViewModel {
        let useCase = TangemPayLoadCashbackDetailsUseCase(provider: dataProvider)
        let viewModel = TangemPayCashbackDetailViewModel(
            summary: summary,
            userWalletId: userWalletId,
            cashbackDetailsUseCase: useCase
        )
        viewModel.dismissHandler = handler

        return viewModel
    }
}
