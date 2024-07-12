//
//  SendViewModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2023 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import BlockchainSdk

protocol SendViewAlertPresenter: AnyObject {
    func showAlert(_ alert: AlertBinder)
}

final class SendViewModel: ObservableObject {
    // MARK: - ViewState

    @Published var stepAnimation: SendView.StepAnimation
    @Published var step: SendStep {
        willSet {
            step.willDisappear(next: newValue)
            newValue.willAppear(previous: step)
        } didSet {
            bind(step: step)
        }
    }

    @Published var mainButtonType: SendMainButtonType
    @Published var showBackButton = false

    @Published var transactionURL: URL?

    @Published var closeButtonDisabled = false
    @Published var isUserInteractionDisabled = false
    @Published var mainButtonLoading: Bool = false
    @Published var mainButtonDisabled: Bool = false

    @Published var alert: AlertBinder?

    var title: String? { step.title }
    var subtitle: String? { step.subtitle }

    var closeButtonColor: Color {
        closeButtonDisabled ? Colors.Text.disabled : Colors.Text.primary1
    }

    var shouldShowDismissAlert: Bool {
        if case .finish = step.type {
            return false
        }

        return mainButtonType == .send || mainButtonType == .continue
    }

    private let interactor: SendBaseInteractor
    private let stepsManager: SendStepsManager
    private weak var coordinator: SendRoutable?

    private var bag: Set<AnyCancellable> = []

    private var sendSubscription: AnyCancellable?
    private var isValidSubscription: AnyCancellable?

    init(
        interactor: SendBaseInteractor,
        stepsManager: SendStepsManager,
        coordinator: SendRoutable
    ) {
        self.interactor = interactor
        self.stepsManager = stepsManager
        self.coordinator = coordinator

        step = stepsManager.initialState.step
        stepAnimation = stepsManager.initialState.animation
        mainButtonType = stepsManager.initialState.mainButtonType

        bind()
        bind(step: stepsManager.initialState.step)
    }

    func onCurrentPageAppear() {
        step.didAppear()
    }

    func onCurrentPageDisappear() {
        step.didDisappear()
    }

    func userDidTapActionButton() {
        switch mainButtonType {
        case .next:
            stepsManager.performNext()
        case .continue:
            stepsManager.performContinue()
        case .send:
            performSend()
        case .close:
            coordinator?.dismiss()
        }
    }

    func userDidTapBackButton() {
        stepsManager.performBack()
    }

    func dismiss() {
        Analytics.log(.sendButtonClose, params: [
            .source: step.type.analyticsSourceParameterValue,
            .fromSummary: .affirmativeOrNegative(for: step.type.isSummary),
            .valid: .affirmativeOrNegative(for: !mainButtonDisabled),
        ])

        if shouldShowDismissAlert {
            alert = SendAlertBuilder.makeDismissAlert { [weak self] in
                self?.coordinator?.dismiss()
            }
        } else {
            coordinator?.dismiss()
        }
    }

    func share(url: URL) {
        Analytics.log(.sendButtonShare)
        coordinator?.openShareSheet(url: url)
    }

    func explore(url: URL) {
        Analytics.log(.sendButtonExplore)
        coordinator?.openExplorer(url: url)
    }
}

// MARK: - Private

private extension SendViewModel {
    private func performSend() {
        sendSubscription = interactor.send()
            .withWeakCaptureOf(self)
            .receive(on: DispatchQueue.main)
            .sink { viewModel, result in
                viewModel.proceed(result: result)
            }
    }

    private func proceed(result: SendTransactionDispatcherResult) {
        switch result {
        case .success(let url):
            transactionURL = url
            stepsManager.performFinish()
        case .userCancelled, .transactionNotFound:
            break
        case .informationRelevanceServiceError:
            alert = SendAlertBuilder.makeFeeRetryAlert { [weak self] in
                self?.performSend()
            }
        case .informationRelevanceServiceFeeWasIncreased:
            alert = AlertBuilder.makeOkGotItAlert(message: Localization.sendNotificationHighFeeTitle)
        case .sendTxError(let transaction, let sendTxError):
            alert = SendAlertBuilder.makeTransactionFailedAlert(sendTxError: sendTxError, openMailAction: { [weak self] in
                self?.openMail(transaction: transaction, error: sendTxError)
            })
        case .demoAlert:
            alert = AlertBuilder.makeAlert(
                title: "",
                message: Localization.alertDemoFeatureDisabled,
                primaryButton: .default(.init(Localization.commonOk)) { [weak self] in
                    self?.coordinator?.dismiss()
                }
            )
        }
    }

    private func openMail(transaction: BSDKTransaction, error: SendTxError) {
        Analytics.log(.requestSupport, params: [.source: .transactionSourceSend])

        let (emailDataCollector, recipient) = interactor.makeMailData(transaction: transaction, error: error)
        coordinator?.openMail(with: emailDataCollector, recipient: recipient)
    }

    private func bind(step: SendStep) {
        isValidSubscription = step.isValidPublisher
            .map { !$0 }
            .receive(on: DispatchQueue.main)
            .assign(to: \.mainButtonDisabled, on: self, ownership: .weak)
    }

    private func bind() {
        interactor.isLoading
            .assign(to: \.closeButtonDisabled, on: self, ownership: .weak)
            .store(in: &bag)

        interactor.isLoading
            .assign(to: \.mainButtonLoading, on: self, ownership: .weak)
            .store(in: &bag)

        interactor.isLoading
            .assign(to: \.isUserInteractionDisabled, on: self, ownership: .weak)
            .store(in: &bag)
    }
}

// MARK: - SendViewAlertPresenter

extension SendViewModel: SendViewAlertPresenter {
    func showAlert(_ alert: AlertBinder) {
        self.alert = alert
    }
}

// MARK: - SendStepsManagerOutput

extension SendViewModel: SendStepsManagerOutput {
    func update(state: SendStepsManagerViewState) {
        stepAnimation = state.animation
        mainButtonType = state.mainButtonType
        showBackButton = state.backButtonVisible

        // Give some time to update `stepAnimation`
        DispatchQueue.main.async {
            self.step = state.step
        }
    }
}
