//
//  SendExternalAmountUpdater.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol SendExternalAmountUpdatableViewModel {
    func externalUpdate(amount: SendAmount?)
}

struct SendExternalAmountUpdater {
    private let viewModel: any SendExternalAmountUpdatableViewModel
    private let interactor: any SendNewAmountInteractor

    init(viewModel: any SendExternalAmountUpdatableViewModel, interactor: any SendNewAmountInteractor) {
        self.viewModel = viewModel
        self.interactor = interactor
    }

    func externalUpdate(amount: Decimal?) {
        let amount = try? interactor.update(amount: amount)
        viewModel.externalUpdate(amount: amount)
    }
}
