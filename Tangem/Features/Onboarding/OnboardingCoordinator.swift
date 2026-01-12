//
//  OnboardingCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2022 Tangem AG. All rights reserved.
//

import Foundation
import TangemVisa

final class OnboardingCoordinator: CoordinatorObject {
    var dismissAction: Action<OutputOptions>
    var popToRootAction: Action<PopToRootOptions>

    // MARK: - Dependencies

    @Injected(\.mailComposePresenter) private var mailPresenter: MailComposePresenter
    @Injected(\.safariManager) private var safariManager: SafariManager

    // MARK: - Main view models

    @Published private(set) var viewState: ViewState? = nil

    // MARK: - Child view models

    @Published var modalWebViewModel: WebViewContainerViewModel? = nil
    @Published var accessCodeModel: OnboardingAccessCodeViewModel? = nil
    @Published var supportChatViewModel: SupportChatViewModel? = nil

    // MARK: - Child coordinators

    // MARK: - Helpers

    /// For non-dismissable presentation
    var onDismissalAttempt: () -> Void = {}

    // MARK: - Private

    private var safariHandle: SafariHandle?

    required init(dismissAction: @escaping Action<OutputOptions>, popToRootAction: @escaping Action<PopToRootOptions>) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: OnboardingCoordinator.Options) {
        switch options {
        case .input(let onboardingInput):
            handle(input: onboardingInput)
            logOnboardingStartedAnalytics(contextParams: options.contextParams)
        case .mobileInput(let mobileOnboardingInput):
            handle(input: mobileOnboardingInput)
            if mobileOnboardingInput.shouldLogOnboardingStartedAnalytics {
                logOnboardingStartedAnalytics(contextParams: options.contextParams)
            }
        }
    }
}

// MARK: - Options

extension OnboardingCoordinator {
    enum Options {
        case input(OnboardingInput)
        case mobileInput(MobileOnboardingInput)

        var contextParams: Analytics.ContextParams {
            switch self {
            case .input(let onboardingInput):
                return onboardingInput.cardInput.getContextParams()
            case .mobileInput:
                return .custom(AnalyticsContextData.mobileWallet)
            }
        }
    }

    enum OutputOptions {
        case main(userWalletModel: UserWalletModel)
        case dismiss(isSuccessful: Bool)

        var isSuccessful: Bool {
            switch self {
            case .main:
                return true
            case .dismiss(let isSuccessful):
                return isSuccessful
            }
        }
    }
}

// MARK: - OnboardingBrowserRoutable

extension OnboardingCoordinator: OnboardingBrowserRoutable {
    func openBrowser(at url: URL, onSuccess: @escaping (URL) -> Void) {
        safariHandle = safariManager.openURL(url, onSuccess: { [weak self] onSuccessURL in
            onSuccess(onSuccessURL)
            self?.safariHandle = nil
        })
    }
}

// MARK: - WalletOnboardingRoutable

extension OnboardingCoordinator: WalletOnboardingRoutable {
    func openAccessCodeView(analyticsContextParams: Analytics.ContextParams, callback: @escaping (String) -> Void) {
        accessCodeModel = .init(analyticsContextParams: analyticsContextParams, successHandler: { [weak self] code in
            self?.accessCodeModel = nil
            callback(code)
        })
    }

    func openMail(with dataCollector: EmailDataCollector, recipient: String, emailType: EmailType) {
        let logsComposer = LogsComposer(infoProvider: dataCollector)
        let mailViewModel = MailViewModel(logsComposer: logsComposer, recipient: recipient, emailType: emailType)

        Task { @MainActor in
            mailPresenter.present(viewModel: mailViewModel)
        }
    }

    func openSupportChat(input: SupportChatInputModel) {
        supportChatViewModel = SupportChatViewModel(input: input)
    }

    func openWebView(with url: URL) {
        modalWebViewModel = WebViewContainerViewModel(
            url: url,
            title: "",
            addLoadingIndicator: true,
            withCloseButton: true
        )
    }
}

// MARK: - OnboardingRoutable

extension OnboardingCoordinator: OnboardingRoutable {
    func onboardingDidFinish(userWalletModel: UserWalletModel?) {
        if let userWalletModel {
            dismiss(with: .main(userWalletModel: userWalletModel))
        } else {
            dismiss(with: .dismiss(isSuccessful: true))
        }
    }

    func closeOnboarding() {
        dismiss(with: .dismiss(isSuccessful: false))
    }
}

extension OnboardingCoordinator: VisaOnboardingRoutable {}

// MARK: - MobileOnboardingRoutable

extension OnboardingCoordinator: MobileOnboardingRoutable {
    func mobileOnboardingDidComplete() {
        dismiss(with: .dismiss(isSuccessful: true))
    }
}

// MARK: - Input handlers

private extension OnboardingCoordinator {
    func handle(input: OnboardingInput) {
        switch input.steps {
        case .singleWallet:
            let model = SingleCardOnboardingViewModel(input: input, coordinator: self)
            onDismissalAttempt = model.backButtonAction
            viewState = .singleCard(model)
        case .twins:
            let model = TwinsOnboardingViewModel(input: input, coordinator: self)
            onDismissalAttempt = model.backButtonAction
            viewState = .twins(model)
        case .wallet:
            let model = WalletOnboardingViewModel(input: input, coordinator: self)
            onDismissalAttempt = model.backButtonAction
            viewState = .wallet(model)
        case .visa:
            let model = VisaOnboardingViewModelBuilder().makeOnboardingViewModel(
                onboardingInput: input,
                coordinator: self
            )
            onDismissalAttempt = model.backButtonAction
            viewState = .visa(model)
        }
    }

    func handle(input: MobileOnboardingInput) {
        let model = MobileOnboardingViewModel(input: input, coordinator: self)
        onDismissalAttempt = model.onDismissalAttempt
        viewState = .mobile(model)
    }
}

// MARK: - Analytics

private extension OnboardingCoordinator {
    func logOnboardingStartedAnalytics(contextParams: Analytics.ContextParams) {
        Analytics.log(.onboardingStarted, contextParams: contextParams)
    }
}

// MARK: ViewState

extension OnboardingCoordinator {
    enum ViewState {
        case singleCard(SingleCardOnboardingViewModel)
        case twins(TwinsOnboardingViewModel)
        case wallet(WalletOnboardingViewModel)
        case visa(VisaOnboardingViewModel)
        case mobile(MobileOnboardingViewModel)
    }
}
