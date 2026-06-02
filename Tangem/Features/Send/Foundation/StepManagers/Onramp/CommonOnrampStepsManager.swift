//
//  CommonOnrampStepsManager.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemExpress
import TangemLocalization

final class CommonOnrampStepsManager {
    @Injected(\.alertPresenter)
    private var alertPresenter: any AlertPresenter

    private let onrampStep: OnrampSummaryStep
    private let offersSelectorViewModel: OnrampOffersSelectorViewModel
    private let finishStep: SendFinishStep
    private let summaryTitleProvider: SendSummaryTitleProvider
    private let onrampBaseDataBuilder: OnrampRouterDataBuilder
    private let shouldActivateKeyboard: Bool
    private weak var router: SendRoutable?

    private var stack: [SendStep]
    private weak var output: SendStepsManagerOutput?
    private var pendingKYCProceedToWidget: (() -> Void)?

    init(
        onrampStep: OnrampSummaryStep,
        offersSelectorViewModel: OnrampOffersSelectorViewModel,
        finishStep: SendFinishStep,
        summaryTitleProvider: SendSummaryTitleProvider,
        onrampBaseDataBuilder: OnrampRouterDataBuilder,
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
        ExpressLogger.tag("Onramp").info(self, "[StepsManager.next] step=\(String(describing: step.type)) output=\(output == nil ? "nil" : "set")")
        stack.append(step)
        output?.update(step: step)
        ExpressLogger.tag("Onramp").info(self, "[StepsManager.next] output.update returned")
    }
}

// MARK: - SendStepsManager

extension CommonOnrampStepsManager: SendStepsManager {
    var initialKeyboardState: Bool { shouldActivateKeyboard }
    var initialFlowActionType: SendFlowActionType { .onramp }
    var initialStep: any SendStep { onrampStep }

    var shouldShowDismissAlert: Bool {
        return false
    }

    var navigationBarSettings: SendStepNavigationBarSettings {
        switch currentStep().type {
        case .onramp:
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
        case .onramp: .init(action: .none)
        case .finish: .init(action: .close)
        default: .empty
        }
    }

    func set(output: SendStepsManagerOutput) {
        self.output = output
    }

    func performFinish() {
        ExpressLogger.tag("Onramp").info(self, "[StepsManager.performFinish] -> next(finishStep)")
        next(step: finishStep)
    }
}

// MARK: - OnrampSummaryRoutable

extension CommonOnrampStepsManager: OnrampModelRoutable {
    func openOnrampCountryBottomSheet(country: OnrampCountry) {
        let (repository, dataRepository) = onrampBaseDataBuilder.makeDataForOnrampCountryBottomSheet()
        router?.openOnrampCountryDetection(
            country: country,
            repository: repository,
            dataRepository: dataRepository,
            onCountrySelected: { [weak output] in
                output?.setKeyboardActive(true)
            }
        )
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
        ExpressLogger.tag("Onramp").info(self, "[StepsManager.openOnrampWebView] url=\(url.absoluteString) router=\(router == nil ? "nil" : "set")")
        router?.openOnrampWebView(url: url, onDismiss: onDismiss, onSuccess: onSuccess)
    }

    func openFinishStep() {
        ExpressLogger.tag("Onramp").info(self, "[StepsManager.openFinishStep] output=\(output == nil ? "nil" : "set") -> performFinish")
        performFinish()
    }

    func openOnrampKYCVerification(provider: OnrampProvider, onProceedToWidget: @escaping () -> Void) {
        ExpressLogger.tag("Onramp").info(self, "[StepsManager.openOnrampKYCVerification] provider=\(provider.provider.id) router=\(router == nil ? "nil" : "set"); storing pendingKYCProceedToWidget")
        pendingKYCProceedToWidget = onProceedToWidget
        router?.openOnrampKYCVerification(
            providerName: provider.provider.name,
            routable: self
        )
    }
}

// MARK: - OnrampKYCVerificationSheetRoutable

extension CommonOnrampStepsManager: OnrampKYCVerificationSheetRoutable {
    func onProceedToWidget() {
        ExpressLogger.tag("Onramp").info(self, "[StepsManager.onProceedToWidget] entry pendingKYCProceedToWidget=\(pendingKYCProceedToWidget == nil ? "nil" : "set")")
        let proceed = pendingKYCProceedToWidget
        pendingKYCProceedToWidget = nil
        ExpressLogger.tag("Onramp").info(self, "[StepsManager.onProceedToWidget] firing closure")
        proceed?()
        ExpressLogger.tag("Onramp").info(self, "[StepsManager.onProceedToWidget] closure returned")
    }

    func onChooseAnother() {
        ExpressLogger.tag("Onramp").info(self, "[StepsManager.onChooseAnother] entry -> openOnrampAllOffers")
        pendingKYCProceedToWidget = nil
        openOnrampAllOffers()
    }

    func onClose() {
        ExpressLogger.tag("Onramp").info(self, "[StepsManager.onClose] entry; clearing pendingKYCProceedToWidget")
        pendingKYCProceedToWidget = nil
    }
}

// MARK: - OnrampSummaryRoutable

extension CommonOnrampStepsManager: OnrampSummaryRoutable {
    func openOnrampAllOffers() {
        router?.openOnrampOffersSelector(viewModel: offersSelectorViewModel)
    }

    func openOnrampSettingsView() {
        let (repository, _) = onrampBaseDataBuilder.makeDataForOnrampCountrySelectorView()
        router?.openOnrampSettings(repository: repository, settingsRoutable: self)
    }

    func openOnrampCurrencySelector() {
        let (repository, dataRepository) = onrampBaseDataBuilder.makeDataForOnrampCountrySelectorView()
        router?.openOnrampCurrencySelector(repository: repository, dataRepository: dataRepository)
    }
}

// MARK: - OnrampSettingsRoutable

extension CommonOnrampStepsManager: OnrampSettingsRoutable {
    func openOnrampCountrySelector() {
        openOnrampCountrySelectorView()
    }
}
