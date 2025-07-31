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
    private let interactor: SendNewSummaryInteractor
    private let sendFeeProvider: SendFeeProvider

    init(
        viewModel: SendNewSummaryViewModel,
        interactor: SendNewSummaryInteractor,
        sendFeeProvider: SendFeeProvider
    ) {
        self.viewModel = viewModel
        self.interactor = interactor
        self.sendFeeProvider = sendFeeProvider
    }

    func set(router: SendSummaryStepsRoutable) {
        viewModel.router = router
    }
}

// MARK: - SendStep

extension SendNewSummaryStep: SendStep {
    var title: String? { interactor.title }

    var type: SendStepType { .newSummary(viewModel) }

    var navigationLeadingViewType: SendStepNavigationLeadingViewType? { .none }
    var navigationTrailingViewType: SendStepNavigationTrailingViewType? { .closeButton }

    var sendStepViewAnimatable: any SendStepViewAnimatable { viewModel }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        interactor.isReadyToSendPublisher.eraseToAnyPublisher()
    }

    func willAppear(previous step: any SendStep) {
        sendFeeProvider.updateFees()
    }
}
