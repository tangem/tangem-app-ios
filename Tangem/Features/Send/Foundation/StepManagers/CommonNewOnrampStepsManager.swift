//
//  CommonNewOnrampStepsManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import TangemLocalization

final class CommonNewOnrampStepsManager {
    @Injected(\.alertPresenter)
    private var alertPresenter: any AlertPresenter

    private let onrampStep: NewOnrampStep
    private let offersSelectorViewModel: OnrampOffersSelectorViewModel
    private let finishStep: SendFinishStep
    private let summaryTitleProvider: SendSummaryTitleProvider
    private let onrampBaseDataBuilder: OnrampBaseDataBuilder
    private let shouldActivateKeyboard: Bool
    private weak var router: SendRoutable?

    private var stack: [SendStep]
    private weak var output: SendStepsManagerOutput?

    init(
        onrampStep: NewOnrampStep,
        offersSelectorViewModel: OnrampOffersSelectorViewModel,
        finishStep: SendFinishStep,
        summaryTitleProvider: SendSummaryTitleProvider,
        onrampBaseDataBuilder: OnrampBaseDataBuilder,
        shouldActivateKeyboard: Bool,
        router: SendRoutable,
    ) {
        self.onrampStep = onrampStep
        self.offersSelectorViewModel = offersSelectorViewModel
        self.finishStep = finishStep
        self.summaryTitleProvider = summaryTitleProvider
        self.onrampBaseDataBuilder = onrampBaseDataBuilder
        self.shouldActivateKeyboard = shouldActivateKeyboard
        self.router = router

        stack = [onrampStep]
    }

    private func currentStep() -> SendStep {
        let last = stack.last
        return last ?? initialStep
    }

    private func next(step: SendStep) {
        stack.append(step)
        output?.update(step: step)
    }
}

// MARK: - SendStepsManager

extension CommonNewOnrampStepsManager: SendStepsManager {
    var initialKeyboardState: Bool { shouldActivateKeyboard }
    var initialFlowActionType: SendFlowActionType { .onramp }
    var initialStep: any SendStep { onrampStep }

    var shouldShowDismissAlert: Bool {
        return false
    }

    var navigationBarSettings: SendStepNavigationBarSettings {
        switch currentStep().type {
        case .newOnramp:
            return .init(title: summaryTitleProvider.title, leadingViewType: .closeButton, trailingViewType: .dotsButton { [weak self] in
                self?.onrampStep.openOnrampSettingsView()
            })
        case .finish:
            return .init(leadingViewType: .closeButton)
        default:
            return .empty
        }
    }

    var bottomBarSettings: SendStepBottomBarSettings {
        switch currentStep().type {
        case .newOnramp: .init(action: .none)
        case .finish: .init(action: .close)
        default: .empty
        }
    }

    func set(output: SendStepsManagerOutput) {
        self.output = output
    }

    func performFinish() {
        next(step: finishStep)
    }
}

// MARK: - OnrampSummaryRoutable

extension CommonNewOnrampStepsManager: OnrampModelRoutable {
    func openOnrampCountryBottomSheet(country: OnrampCountry) {
        let (repository, dataRepository) = onrampBaseDataBuilder.makeDataForOnrampCountryBottomSheet()
        router?.openOnrampCountryDetection(country: country, repository: repository, dataRepository: dataRepository)
    }

    func openOnrampCountrySelectorView() {
        let (repository, dataRepository) = onrampBaseDataBuilder.makeDataForOnrampCountrySelectorView()
        router?.openOnrampCountrySelector(repository: repository, dataRepository: dataRepository)
    }

    func openOnrampRedirecting() {
        if let demoAlertMessage = onrampBaseDataBuilder.demoAlertMessage() {
            alertPresenter.present(alert: AlertBuilder.makeDemoAlert(demoAlertMessage))
            return
        }

        // The new onramp performed straight from onramp model
        let onrampRedirectingBuilder = onrampBaseDataBuilder.makeDataForOnrampRedirecting()
        router?.openOnrampRedirecting(onrampRedirectingBuilder: onrampRedirectingBuilder)
    }

    func openOnrampWebView(url: URL, onDismiss: @escaping () -> Void, onSuccess: @escaping (URL) -> Void) {
        router?.openOnrampWebView(url: url, onDismiss: onDismiss, onSuccess: onSuccess)
    }

    func openFinishStep() {
        performFinish()
    }
}

// MARK: - OnrampSummaryRoutable

extension CommonNewOnrampStepsManager: OnrampSummaryRoutable {
    func onrampStepRequestEditProvider() {
        router?.openOnrampOffersSelector(viewModel: offersSelectorViewModel)
    }

    func openOnrampSettingsView() {
        let (repository, _) = onrampBaseDataBuilder.makeDataForOnrampCountrySelectorView()
        router?.openOnrampSettings(repository: repository)
    }

    func openOnrampCurrencySelectorView() {
        let (repository, dataRepository) = onrampBaseDataBuilder.makeDataForOnrampCountrySelectorView()
        router?.openOnrampCurrencySelector(repository: repository, dataRepository: dataRepository)
    }
}
