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
    private let interactorSaver: SendNewDestinationInteractorSaver
    private let analyticsLogger: SendDestinationAnalyticsLogger

    init(
        viewModel: SendNewDestinationViewModel,
        interactor: any SendNewDestinationInteractor,
        interactorSaver: any SendNewDestinationInteractorSaver,
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

extension SendNewDestinationStep: SendStep {
    var type: SendStepType { .newDestination(viewModel) }

    var sendStepViewAnimatable: any SendStepViewAnimatable { viewModel }

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
    }
}
