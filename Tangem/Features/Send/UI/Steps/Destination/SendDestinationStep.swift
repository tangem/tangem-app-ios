//
//  SendDestinationStep.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization
import Combine
import SwiftUI

class SendDestinationStep {
    private let viewModel: SendDestinationViewModel
    private let interactor: SendDestinationInteractor
    private let interactorSaver: SendDestinationInteractorSaver
    private let analyticsLogger: SendDestinationAnalyticsLogger

    init(
        viewModel: SendDestinationViewModel,
        interactor: any SendDestinationInteractor,
        interactorSaver: any SendDestinationInteractorSaver,
        analyticsLogger: any SendDestinationAnalyticsLogger
    ) {
        self.viewModel = viewModel
        self.interactor = interactor
        self.interactorSaver = interactorSaver
        self.analyticsLogger = analyticsLogger
    }

    func set(stepRouter: SendDestinationStepRoutable) {
        viewModel.stepRouter = stepRouter
    }

    func cancelChanges() {
        interactorSaver.cancelChanges()
    }
}

// MARK: - SendStep

extension SendDestinationStep: SendStep {
    var type: SendStepType { .destination(viewModel) }

    var shouldShowBottomOverlay: Bool { true }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        interactor.allFieldsIsValid.eraseToAnyPublisher()
    }

    func initialAppear() {
        analyticsLogger.logDestinationStepOpened()
    }

    func willAppear(previous step: any SendStep) {
        step.type.isSummary ? analyticsLogger.logDestinationStepReopened() : analyticsLogger.logDestinationStepOpened()

        interactorSaver.captureValue()
        viewModel.setIgnoreDestinationAddressClearButton(false)
    }

    func willDisappear(next step: any SendStep) {
        viewModel.setIgnoreDestinationAddressClearButton(true)
    }
}
