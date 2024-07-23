//
//  SendAmountStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

class SendAmountStep {
    private let viewModel: SendAmountViewModel
    private let interactor: SendAmountInteractor
    private let sendFeeLoader: SendFeeLoader

    init(
        viewModel: SendAmountViewModel,
        interactor: SendAmountInteractor,
        sendFeeLoader: SendFeeLoader
    ) {
        self.viewModel = viewModel
        self.interactor = interactor
        self.sendFeeLoader = sendFeeLoader
    }
}

// MARK: - SendStep

extension SendAmountStep: SendStep {
    var title: String? { Localization.sendAmountLabel }

    var type: SendStepType { .amount(viewModel) }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        interactor.isValidPublisher.eraseToAnyPublisher()
    }

    func willAppear(previous step: any SendStep) {
        guard step.type.isSummary else {
            return
        }

        viewModel.setAnimatingAuxiliaryViewsOnAppear()
    }

    func willDisappear(next step: SendStep) {
        UIApplication.shared.endEditing()

        guard step.type.isSummary else {
            return
        }

        sendFeeLoader.updateFees()
    }
}
