//
//  SendNewSummaryStep.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

class SendNewSummaryStep {
    private let viewModel: SendNewSummaryViewModel
    private let input: SendSummaryInput
    private let sendFeeProvider: SendFeeProvider
    private let _title: String?

    init(
        viewModel: SendNewSummaryViewModel,
        input: SendSummaryInput,
        sendFeeProvider: SendFeeProvider,
        title: String?
    ) {
        self.viewModel = viewModel
        self.input = input
        self.sendFeeProvider = sendFeeProvider
        _title = title
    }

    func set(router: SendSummaryStepsRoutable) {
        viewModel.router = router
    }
}

// MARK: - SendStep

extension SendNewSummaryStep: SendStep {
    var title: String? { _title }

    var type: SendStepType { .newSummary(viewModel) }

    var navigationLeadingViewType: SendStepNavigationLeadingViewType? { .none }
    var navigationTrailingViewType: SendStepNavigationTrailingViewType? { .closeButton }

    var sendStepViewAnimatable: any SendStepViewAnimatable { viewModel }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        input.isReadyToSendPublisher.eraseToAnyPublisher()
    }

    func willAppear(previous step: any SendStep) {
        sendFeeProvider.updateFees()
    }
}
