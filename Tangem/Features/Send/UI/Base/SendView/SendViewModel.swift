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
import TangemAssets
import TangemExpress
import TangemFoundation
import TangemLocalization
import TangemUI
import struct TangemUIUtils.AlertBinder

protocol SendViewAlertPresenter: AnyObject {
    func showAlert(_ alert: AlertBinder)
}

final class SendViewModel: ObservableObject {
    // MARK: - Injections

    @Injected(\.alertPresenter) private var alertPresenter: any AlertPresenter

    // MARK: - ViewState

    @Published var step: SendStep
    @Published var flowActionType: SendFlowActionType
    @Published var isKeyboardActive: Bool = false

    @Published var closeButtonDisabled = false
    @Published var trailingButtonDisabled = false
    @Published var isUserInteractionDisabled = false
    @Published var mainButtonLoading: Bool = false
    @Published var actionIsAvailable: Bool = false

    var navigationBarSettings: SendStepNavigationBarSettings { stepsManager.navigationBarSettings }
    var shouldShowBottomOverlay: Bool { step.shouldShowBottomOverlay }
    var bottomBarSettings: SendStepBottomBarSettings { stepsManager.bottomBarSettings }

    var shouldShowDismissAlert: Bool {
        stepsManager.shouldShowDismissAlert
    }

    let tangemIconProvider: TangemIconProvider

    private let interactor: SendBaseInteractor
    private let stepsManager: SendStepsManager
    private let alertBuilder: SendAlertBuilder
    private let dataBuilder: SendGenericBaseDataBuilder
    private let analyticsLogger: SendBaseViewAnalyticsLogger
    private let blockchainSDKNotificationMapper: BlockchainSDKNotificationMapper
    private weak var coordinator: SendRoutable?

    private var bag: Set<AnyCancellable> = []

    private var sendTask: Task<Void, Never>?
    private var isValidSubscription: AnyCancellable?
    private var isUpdatingSubscription: AnyCancellable?
    private var isValidContinueSubscription: AnyCancellable?

    init(
        interactor: SendBaseInteractor,
        stepsManager: SendStepsManager,
        alertBuilder: SendAlertBuilder,
        dataBuilder: SendGenericBaseDataBuilder,
        analyticsLogger: SendBaseViewAnalyticsLogger,
        blockchainSDKNotificationMapper: BlockchainSDKNotificationMapper,
        tangemIconProvider: TangemIconProvider,
        coordinator: SendRoutable
    ) {
        self.interactor = interactor
        self.stepsManager = stepsManager
        self.alertBuilder = alertBuilder
        self.analyticsLogger = analyticsLogger
        self.blockchainSDKNotificationMapper = blockchainSDKNotificationMapper
        self.dataBuilder = dataBuilder
        self.tangemIconProvider = tangemIconProvider
        self.coordinator = coordinator

        step = stepsManager.initialStep
        flowActionType = stepsManager.initialFlowActionType
        isKeyboardActive = stepsManager.initialKeyboardState

        bind()
        bind(step: stepsManager.initialStep)

        stepsManager.set(output: self)
        stepsManager.initialStep.initialAppear()
    }

    func onAppear() {
        analyticsLogger.logSendBaseViewOpened()
    }

    func onDisappear() {}

    func userDidTapActionButton(mainButtonType: SendMainButtonType) {
        analyticsLogger.logMainActionButton(type: mainButtonType, flow: flowActionType)

        switch mainButtonType {
        case .next:
            stepsManager.performNext()
        case .continue:
            stepsManager.performContinue()
        case .action where flowActionType == .approve:
            performApprove()
        case .action where flowActionType == .onramp:
            performOnramp()
        case .action:
            performAction()
        case .close:
            coordinator?.dismiss(reason: .mainButtonTap(type: mainButtonType))
        }
    }

    func userDidTapBackButton() {
        stepsManager.performBack()
    }

    func onAppear(newStep: any SendStep) {
        switch (step.type, newStep.type) {
        case (_, .summary), (_, .finish):
            isKeyboardActive = false
        default:
            break
        }
    }

    func onDisappear(oldStep: any SendStep) {
        switch (oldStep.type, step.type) {
        case (_, .amount), (_, .destination):
            isKeyboardActive = true
        default:
            break
        }
    }

    func dismiss() {
        analyticsLogger.logCloseButton(stepType: step.type, isAvailableToAction: actionIsAvailable)

        switch bottomBarSettings.action {
        case .continue:
            // When `mainButtonType == .continue` means we're in the `edit` mode
            // We perform the back action with no save changes in new UI
            stepsManager.performBack()
        case _ where shouldShowDismissAlert:
            showAlert(alertBuilder.makeDismissAlert { [weak self] in
                self?.coordinator?.dismiss(reason: .other)
            })
        case .none:
            coordinator?.dismiss(reason: .other)
        case .some(let mainButtonType):
            coordinator?.dismiss(reason: .mainButtonTap(type: mainButtonType))
        }
    }
}

// MARK: - Private

private extension SendViewModel {
    func performOnramp() {
        do {
            if let demoAlertMessage = try dataBuilder.onrampBuilder().demoAlertMessage() {
                showAlert(AlertBuilder.makeDemoAlert(demoAlertMessage))
                return
            }

            isKeyboardActive = false
            let onrampRedirectingBuilder = try dataBuilder.onrampBuilder().makeDataForOnrampRedirecting()
            coordinator?.openOnrampRedirecting(onrampRedirectingBuilder: onrampRedirectingBuilder)
        } catch {
            showAlert(error.alertBinder)
        }
    }

    func performApprove() {
        do {
            let input = try dataBuilder.approveViewModelProvider().makeExpressApproveViewModelInput()
            coordinator?.openApproveView(expressApproveViewModelInput: input)
        } catch {
            showAlert(error.alertBinder)
        }
    }

    func performAction() {
        sendTask?.cancel()
        sendTask = runTask(in: self) { viewModel in
            do {
                let result = try await viewModel.interactor.action()
                await viewModel.proceed(result: result)
            } catch let error as TransactionDispatcherResult.Error {
                // The demo alert doesn't show without delay
                try? await Task.sleep(for: .seconds(1))
                await viewModel.proceed(error: error)
            } catch _ as CancellationError {
                // Do nothing
            } catch let error as ValidationError {
                let mapper = viewModel.blockchainSDKNotificationMapper
                let validationErrorEvent = mapper.mapToValidationErrorEvent(error)
                let message = validationErrorEvent.description ?? error.localizedDescription
                let alertBinder = AlertBinder(title: Localization.commonError, message: message)
                AppLogger.error(error: error)
                await runOnMain { viewModel.showAlert(alertBinder) }
            } catch {
                AppLogger.error(error: error)
                await runOnMain { viewModel.showAlert(error.alertBinder) }
            }
        }
    }

    @MainActor
    func proceed(result _: TransactionDispatcherResult) {
        stepsManager.performFinish()
    }

    @MainActor
    func proceed(error: TransactionDispatcherResult.Error) {
        switch error {
        case .userCancelled, .transactionNotFound, .actionNotSupported:
            break
        case .informationRelevanceServiceError:
            showAlert(alertBuilder.makeFeeRetryAlert { [weak self] in
                self?.interactor.actualizeInformation()
            })
        case .informationRelevanceServiceFeeWasIncreased:
            showAlert(AlertBuilder.makeOkGotItAlert(message: Localization.sendNotificationHighFeeTitle))
        case .sendTxError(let transaction, let sendTxError):
            showAlert(alertBuilder.makeTransactionFailedAlert(sendTxError: sendTxError) { [weak self] in
                self?.openMail(transaction: transaction, error: sendTxError)
            })
        case .loadTransactionInfo(let error):
            showAlert(alertBuilder.makeTransactionFailedAlert(sendTxError: .init(error: error)) { [weak self] in
                self?.openMail(error: error)
            })
        case .demoAlert:
            showAlert(AlertBuilder.makeDemoAlert())
        }
    }

    func openMail(error: UniversalError) {
        analyticsLogger.logRequestSupport()

        do {
            let (emailDataCollector, recipient) = try dataBuilder.stakingBuilder().makeMailData(stakingRequestError: error)
            coordinator?.openMail(with: emailDataCollector, recipient: recipient)
        } catch {
            showAlert(error.alertBinder)
        }
    }

    func openMail(transaction: TransactionDispatcherTransactionType, error: SendTxError) {
        analyticsLogger.logRequestSupport()

        do {
            switch transaction {
            case .transfer(let transaction):
                let builder = try dataBuilder.sendBuilder()
                let (emailDataCollector, recipient) = builder.makeMailData(transaction: transaction, error: error)
                coordinator?.openMail(with: emailDataCollector, recipient: recipient)

            case .staking(let stakingTransactionAction):
                let builder = try dataBuilder.stakingBuilder()
                let (emailDataCollector, recipient) = builder.makeMailData(action: stakingTransactionAction, error: error)
                coordinator?.openMail(with: emailDataCollector, recipient: recipient)

            case .approve(let approveData):
                let builder = try dataBuilder.sendBuilder()
                let (emailDataCollector, recipient) = try builder.makeMailData(approveTransaction: approveData, error: error)
                coordinator?.openMail(with: emailDataCollector, recipient: recipient)

            case .cex(let expressTransaction, _), .dex(let expressTransaction, _):
                let builder = try dataBuilder.sendBuilder()
                let (emailDataCollector, recipient) = try builder.makeMailData(expressTransaction: expressTransaction, error: error)
                coordinator?.openMail(with: emailDataCollector, recipient: recipient)
            }
        } catch {
            showAlert(error.alertBinder)
        }
    }

    func bind(step: SendStep) {
        isValidSubscription = step.isValidPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.actionIsAvailable, on: self, ownership: .weak)

        isUpdatingSubscription = step.isUpdatingPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.mainButtonLoading, on: self, ownership: .weak)
    }

    func bind() {
        interactor.actionInProcessing
            .receive(on: DispatchQueue.main)
            .assign(to: \.closeButtonDisabled, on: self, ownership: .weak)
            .store(in: &bag)

        interactor.actionInProcessing
            .receive(on: DispatchQueue.main)
            .assign(to: \.trailingButtonDisabled, on: self, ownership: .weak)
            .store(in: &bag)

        interactor.actionInProcessing
            .receive(on: DispatchQueue.main)
            .assign(to: \.isUserInteractionDisabled, on: self, ownership: .weak)
            .store(in: &bag)

        interactor.actionInProcessing
            .receive(on: DispatchQueue.main)
            .assign(to: \.mainButtonLoading, on: self, ownership: .weak)
            .store(in: &bag)
    }
}

// MARK: - SendModelRoutable

extension SendViewModel: SendModelRoutable {
    func openNetworkCurrency() {
        do {
            let builder = try dataBuilder.feeCurrencyProvider()
            let feeCurrency = builder.makeFeeCurrencyData()
            coordinator?.openFeeCurrency(feeCurrency: feeCurrency)
        } catch {
            showAlert(error.alertBinder)
        }
    }

    func openApproveSheet() {
        performApprove()
    }

    func openHighPriceImpactWarningSheetViewModel(viewModel: HighPriceImpactWarningSheetViewModel) {
        coordinator?.openHighPriceImpactWarningSheetViewModel(viewModel: viewModel)
    }

    func resetFlow() {
        stepsManager.resetFlow()
    }

    func openAccountInitializationFlow(viewModel: BlockchainAccountInitializationViewModel) {
        coordinator?.openAccountInitializationFlow(viewModel: viewModel)
    }
}

// MARK: - SendAmountRoutable

extension SendViewModel: SendAmountRoutable {
    func openReceiveTokensList() {
        do {
            isKeyboardActive = false
            let builder = try dataBuilder.sendBuilder()
            let tokensListBuilder = builder.makeSendReceiveTokensList()
            coordinator?.openReceiveTokensList(tokensListBuilder: tokensListBuilder)
        } catch {
            showAlert(error.alertBinder)
        }
    }
}

// MARK: - OnrampModelRoutable

extension SendViewModel: OnrampModelRoutable {
    // [REDACTED_TODO_COMMENT]
    func openOnrampCountryBottomSheet(country: OnrampCountry) {
        do {
            isKeyboardActive = false
            let builder = try dataBuilder.onrampBuilder()
            let (repository, dataRepository) = builder.makeDataForOnrampCountryBottomSheet()
            coordinator?.openOnrampCountryDetection(
                country: country,
                repository: repository,
                dataRepository: dataRepository,
                onCountrySelected: {}
            )
        } catch {
            showAlert(error.alertBinder)
        }
    }

    func openOnrampCountrySelectorView() {
        do {
            let builder = try dataBuilder.onrampBuilder()
            let (repository, dataRepository) = builder.makeDataForOnrampCountrySelectorView()
            coordinator?.openOnrampCountrySelector(
                repository: repository,
                dataRepository: dataRepository
            )
        } catch {
            showAlert(error.alertBinder)
        }
    }

    func openOnrampRedirecting() {
        // The new onramp performed straight from onramp model
        performOnramp()
    }

    func openOnrampWebView(url: URL, onDismiss: @escaping () -> Void, onSuccess: @escaping (URL) -> Void) {
        coordinator?.openOnrampWebView(url: url, onDismiss: onDismiss, onSuccess: onSuccess)
    }

    func openFinishStep() {
        stepsManager.performFinish()
    }
}

// MARK: - SendViewAlertPresenter

extension SendViewModel: SendViewAlertPresenter {
    func showAlert(_ alert: AlertBinder) {
        alertPresenter.present(alert: alert)
    }
}

// MARK: - SendStepsManagerOutput

extension SendViewModel: SendStepsManagerOutput {
    func setKeyboardActive(_ isActive: Bool) {
        isKeyboardActive = isActive
    }

    func update(step newStep: any SendStep) {
        step.willDisappear(next: newStep)
        newStep.willAppear(previous: step)

        // Give some time to update `transitions`
        DispatchQueue.main.async {
            self.step = newStep
            self.bind(step: newStep)
        }
    }

    func update(flowActionType: SendFlowActionType) {
        DispatchQueue.main.async {
            self.flowActionType = flowActionType
        }
    }
}
