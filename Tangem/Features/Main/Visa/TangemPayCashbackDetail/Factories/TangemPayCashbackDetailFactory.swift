//
//  TangemPayCashbackDetailFactory.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation

enum TangemPayCashbackDetailFactory {
    @MainActor
    static func makeViewModel(
        summary: TangemPayCashback.Summary,
        dataProvider: some TangemPayCashbackDataProviding,
        dismiss handler: @escaping () -> Void
    ) -> TangemPayCashbackDetailViewModel {
        let useCase = TangemPayLoadCashbackDetailsUseCase(provider: dataProvider)
        let viewModel = TangemPayCashbackDetailViewModel(
            summary: summary,
            cashbackDetailsUseCase: useCase
        )
        viewModel.dismissHandler = handler

        return viewModel
    }
}
