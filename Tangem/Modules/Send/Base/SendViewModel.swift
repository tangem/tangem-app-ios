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

    @Published var step: SendStep
    @Published var mainButtonType: SendMainButtonType
    @Published var flowActionType: SendFlowActionType
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
        mainButtonType.shouldShowDismissAlert
    }

    private let interactor: SendBaseInteractor
    private let stepsManager: SendStepsManager
    private let userWalletModel: UserWalletModel
    private let feeTokenItem: TokenItem

    private weak var coordinator: SendRoutable?

    private var bag: Set<AnyCancellable> = []

    private var sendTask: Task<Void, Never>?
    private var isValidSubscription: AnyCancellable?

    init(
        interactor: SendBaseInteractor,
        stepsManager: SendStepsManager,
        userWalletModel: UserWalletModel,
        feeTokenItem: TokenItem,
        coordinator: SendRoutable
    ) {
        self.interactor = interactor
        self.stepsManager = stepsManager
        self.userWalletModel = userWalletModel
        self.feeTokenItem = feeTokenItem
        self.coordinator = coordinator

        step = stepsManager.initialState.step
        mainButtonType = stepsManager.initialState.action
        flowActionType = stepsManager.initialFlowActionType

        bind()
        bind(step: stepsManager.initialState.step)
    }

    func userDidTapActionButton() {
        switch mainButtonType {
        case .next:
            stepsManager.performNext()
        case .continue:
            stepsManager.performContinue()
        case .action where flowActionType == .approve:
            performApprove()
        case .action:
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
    func performApprove() {
        guard let (settings, approveViewModelInput) = interactor.makeDataForExpressApproveViewModel() else {
            return
        }

        coordinator?.openApproveView(settings: settings, approveViewModelInput: approveViewModelInput)
    }

    func performSend() {
        sendTask?.cancel()
        sendTask = runTask(in: self) { viewModel in
            do {
                let result = try await viewModel.interactor.send()
                await viewModel.proceed(result: result)
            } catch let error as SendTransactionDispatcherResult.Error {
                await viewModel.proceed(error: error)
            } catch {
                AppLog.shared.error(error)
                await runOnMain { viewModel.showAlert(error.alertBinder) }
            }
        }
    }

    @MainActor
    func proceed(result: SendTransactionDispatcherResult) {
        transactionURL = result.url
        stepsManager.performFinish()
    }

    @MainActor
    func proceed(error: SendTransactionDispatcherResult.Error) {
        switch error {
        case .userCancelled, .transactionNotFound, .stakingUnsupported:
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

    func openMail(transaction: SendTransactionType, error: SendTxError) {
        Analytics.log(.requestSupport, params: [.source: .transactionSourceSend])

        let (emailDataCollector, recipient) = interactor.makeMailData(transaction: transaction, error: error)
        coordinator?.openMail(with: emailDataCollector, recipient: recipient)
    }

    func bind(step: SendStep) {
        isValidSubscription = step.isValidPublisher
            .map { !$0 }
            .receive(on: DispatchQueue.main)
            .assign(to: \.mainButtonDisabled, on: self, ownership: .weak)
    }

    func bind() {
        interactor.isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: \.closeButtonDisabled, on: self, ownership: .weak)
            .store(in: &bag)

        interactor.isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: \.mainButtonLoading, on: self, ownership: .weak)
            .store(in: &bag)

        interactor.isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: \.isUserInteractionDisabled, on: self, ownership: .weak)
            .store(in: &bag)
    }
}

// MARK: - SendModelRoutable

extension SendViewModel: SendModelRoutable {
    func openNetworkCurrency() {
        let walletModels = userWalletModel.walletModelsManager.walletModels
        guard let feeCurrencyWalletModel = walletModels.first(where: { $0.tokenItem == feeTokenItem }) else {
            assertionFailure("Network currency WalletModel not found")
            return
        }

        coordinator?.openFeeCurrency(for: feeCurrencyWalletModel, userWalletModel: userWalletModel)
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
        step.willDisappear(next: state.step)
        step.sendStepViewAnimatable.viewDidChangeVisibilityState(
            .disappearing(nextStep: state.step.type)
        )

        state.step.willAppear(previous: step)
        state.step.sendStepViewAnimatable.viewDidChangeVisibilityState(
            .appearing(previousStep: step.type)
        )

        mainButtonType = state.action
        showBackButton = state.backButtonVisible

        // Give some time to update `transitions`
        DispatchQueue.main.async {
            self.step = state.step
            self.bind(step: state.step)
        }
    }

    func update(flowActionType: SendFlowActionType) {
        DispatchQueue.main.async {
            self.flowActionType = flowActionType
        }
    }
}

extension SendMainButtonType {
    var shouldShowDismissAlert: Bool {
        switch self {
        case .continue, .action:
            return true
        case .next, .close:
            return false
        }
    }
}
