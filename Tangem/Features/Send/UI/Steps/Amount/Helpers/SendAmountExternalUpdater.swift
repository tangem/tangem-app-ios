//
//  SendAmountExternalUpdater.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation

protocol SendAmountExternalUpdatableViewModel {
    func externalUpdate(amount: SendAmount?)
}

struct SendAmountExternalUpdater {
    private let viewModel: any SendAmountExternalUpdatableViewModel
    private let interactor: any SendAmountInteractor

    init(viewModel: any SendAmountExternalUpdatableViewModel, interactor: any SendAmountInteractor) {
        self.viewModel = viewModel
        self.interactor = interactor
    }

    func externalUpdate(amount: Decimal?) {
        let amount = try? interactor.update(amount: amount)
        viewModel.externalUpdate(amount: amount)
    }
}
