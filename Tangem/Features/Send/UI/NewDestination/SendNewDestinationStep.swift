//
//  SendNewDestinationStep.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import Combine
import SwiftUI

class SendNewDestinationStep {
    private let viewModel: SendNewDestinationViewModel
    private let interactor: SendDestinationInteractor
    private let sendFeeInteractor: SendFeeInteractor
    private let tokenItem: TokenItem

    init(
        viewModel: SendNewDestinationViewModel,
        interactor: any SendDestinationInteractor,
        sendFeeInteractor: any SendFeeInteractor,
        tokenItem: TokenItem
    ) {
        self.viewModel = viewModel
        self.interactor = interactor
        self.sendFeeInteractor = sendFeeInteractor
        self.tokenItem = tokenItem
    }

    func set(stepRouter: SendDestinationStepRoutable) {
        viewModel.stepRouter = stepRouter
    }
}

// MARK: - SendStep

extension SendNewDestinationStep: SendStep {
    var title: String? { Localization.sendRecipientLabel }

    var type: SendStepType { .newDestination(viewModel) }
    var navigationLeadingViewType: SendStepNavigationLeadingViewType? { viewModel.isEditMode ? .none : .backButton }
    var navigationTrailingViewType: SendStepNavigationTrailingViewType? { .closeButton }

    var sendStepViewAnimatable: any SendStepViewAnimatable { viewModel }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        interactor.allFieldsIsValid.eraseToAnyPublisher()
    }

    func initialAppear() {
        Analytics.log(.sendAddressScreenOpened)
    }

    func willAppear(previous step: any SendStep) {
        if step.type.isSummary {
            Analytics.log(.sendScreenReopened, params: [.source: .address])
        }
    }

    func willDisappear(next step: SendStep) {
        guard step.type.isSummary else {
            return
        }

        sendFeeInteractor.updateFees()
    }
}
