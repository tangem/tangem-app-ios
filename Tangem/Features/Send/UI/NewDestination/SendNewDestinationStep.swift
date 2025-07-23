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
    private let interactor: SendNewDestinationInteractor
    private let analyticsLogger: SendDestinationAnalyticsLogger

    private var isEditMode: Bool = false

    init(
        viewModel: SendNewDestinationViewModel,
        interactor: any SendNewDestinationInteractor,
        analyticsLogger: SendDestinationAnalyticsLogger
    ) {
        self.viewModel = viewModel
        self.interactor = interactor
        self.analyticsLogger = analyticsLogger
    }

    func set(stepRouter: SendDestinationStepRoutable) {
        viewModel.stepRouter = stepRouter
    }
}

// MARK: - SendStep

extension SendNewDestinationStep: SendStep {
    var title: String? { Localization.sendRecipientLabel }

    var type: SendStepType { .newDestination(viewModel) }
    var navigationLeadingViewType: SendStepNavigationLeadingViewType? { isEditMode ? .none : .backButton }
    var navigationTrailingViewType: SendStepNavigationTrailingViewType? { .closeButton }

    var sendStepViewAnimatable: any SendStepViewAnimatable { viewModel }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        interactor.allFieldsIsValid.eraseToAnyPublisher()
    }

    func saveChangesIfNeeded() {
        interactor.saveChanges()
    }

    func initialAppear() {
        analyticsLogger.logDestinationStepOpened()
    }

    func willAppear(previous step: any SendStep) {
        isEditMode = step.type.isSummary
        step.type.isSummary ? analyticsLogger.logDestinationStepReopened() : analyticsLogger.logDestinationStepOpened()
    }
}
