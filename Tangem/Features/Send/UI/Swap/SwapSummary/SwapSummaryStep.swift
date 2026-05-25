//
//  SwapSummaryStep.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

class SwapSummaryStep {
    private let viewModel: SwapSummaryViewModel
    private let interactor: SwapSummaryInteractor
    private let autoupdatingTimer: AutoupdatingTimer
    private let analyticsLogger: SendSummaryAnalyticsLogger

    init(
        viewModel: SwapSummaryViewModel,
        interactor: SwapSummaryInteractor,
        autoupdatingTimer: AutoupdatingTimer,
        analyticsLogger: SendSummaryAnalyticsLogger,
    ) {
        self.viewModel = viewModel
        self.interactor = interactor
        self.autoupdatingTimer = autoupdatingTimer
        self.analyticsLogger = analyticsLogger
    }

    func set(router: SwapSummaryStepRoutable) {
        viewModel.router = router
    }

    func makeFormVariantMenu() -> (
        selectedId: String,
        items: [SendStepNavigationLeadingViewType.DotsMenuItem],
        onOpen: () -> Void
    ) {
        viewModel.makeFormVariantMenu()
    }
}

// MARK: - SendStep

extension SwapSummaryStep: SendStep {
    var type: SendStepType { .swap(viewModel) }

    var isUpdatingPublisher: AnyPublisher<Bool, Never> {
        interactor.isUpdatingPublisher.eraseToAnyPublisher()
    }

    var isValidPublisher: AnyPublisher<Bool, Never> {
        interactor.isReadyToSendPublisher.eraseToAnyPublisher()
    }

    func initialAppear() {
        analyticsLogger.logSummaryStepOpened()
        logSwapTypeScreenOpenedIfNeeded()
        autoupdatingTimer.resumeTimer()
    }

    func willAppear(previous step: any SendStep) {
        analyticsLogger.logSummaryStepOpened()
        logSwapTypeScreenOpenedIfNeeded()
        autoupdatingTimer.resumeTimer()
    }

    func willDisappear(next step: any SendStep) {
        autoupdatingTimer.pauseTimer()
    }

    private func logSwapTypeScreenOpenedIfNeeded() {
        guard FeatureProvider.isAvailable(.swapSimpleMode) else { return }
        viewModel.logScreenOpened()
    }
}
