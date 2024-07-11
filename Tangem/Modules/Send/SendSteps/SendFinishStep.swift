//
//  SendFinishStep.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

class SendFinishStep {
    private let viewModel: SendFinishViewModel

    init(viewModel: SendFinishViewModel) {
        self.viewModel = viewModel
    }
}

// MARK: - SendStep

extension SendFinishStep: SendStep {
    var title: String? { nil }

    var type: SendStepType { .finish(viewModel) }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        .just(output: true)
    }
}

// MARK: - SendFinishViewModelSetupable

extension SendFinishStep: SendFinishViewModelSetupable {
    func setup(sendFinishInput: any SendFinishInput) {
        viewModel.setup(sendFinishInput: sendFinishInput)
    }

    func setup(sendDestinationInput: any SendDestinationInput) {
        viewModel.setup(sendDestinationInput: sendDestinationInput)
    }

    func setup(sendAmountInput: any SendAmountInput) {
        viewModel.setup(sendAmountInput: sendAmountInput)
    }

    func setup(sendFeeInteractor: any SendFeeInteractor) {
        viewModel.setup(sendFeeInteractor: sendFeeInteractor)
    }
}
