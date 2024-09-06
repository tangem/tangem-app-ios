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
    private let source: SendModel.PredefinedValues.Source

    init(
        viewModel: SendAmountViewModel,
        interactor: SendAmountInteractor,
        sendFeeLoader: SendFeeLoader,
        source: SendModel.PredefinedValues.Source
    ) {
        self.viewModel = viewModel
        self.interactor = interactor
        self.sendFeeLoader = sendFeeLoader
        self.source = source
    }
}

// MARK: - SendStep

extension SendAmountStep: SendStep {
    var title: String? { Localization.sendAmountLabel }

    var type: SendStepType { .amount(viewModel) }

    var sendStepViewAnimatable: any SendStepViewAnimatable { viewModel }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        interactor.isValidPublisher.eraseToAnyPublisher()
    }

    func willAppear(previous step: any SendStep) {
        switch (source, step.type.isSummary) {
        case (.staking, false):
            Analytics.log(.stakingAmountScreenOpened)
        case (.staking, true):
            Analytics.log(.stakingScreenReopened, params: [.source: .amount])
        case (_, true):
            Analytics.log(.sendScreenReopened, params: [.source: .amount])
        case (_, false):
            Analytics.log(.sendAmountScreenOpened)
        }
    }

    func willDisappear(next step: SendStep) {
        guard step.type.isSummary else {
            return
        }

        sendFeeLoader.updateFees()
    }
}

// MARK: - Constants

extension SendAmountStep {
    enum Constants {
        static let amountMinTextScale = 0.5
    }
}
