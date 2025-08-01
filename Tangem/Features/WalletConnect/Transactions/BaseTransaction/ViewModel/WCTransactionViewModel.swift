//
//  WCTransactionViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import SwiftUI
import BigInt
import protocol TangemUI.FloatingSheetContentViewModel
import Foundation
import BlockchainSdk
import TangemUI
import TangemLocalization
import TangemUIUtils

@MainActor
final class WCTransactionViewModel: ObservableObject & FloatingSheetContentViewModel & WCTransactionViewModelDisplayData {
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter
    @Injected(\.userWalletRepository) private var userWalletRepository: UserWalletRepository
    @Injected(\.connectedDAppRepository) private var connectedDAppRepository: any WalletConnectConnectedDAppRepository

    private let analyticsLogger: any WalletConnectTransactionAnalyticsLogger
    private let simulationManager: WCTransactionSimulationManager
    private let securityManager: WCTransactionSecurityManager
    private let customAllowanceManager: WCCustomAllowanceManager
    private let requestDetailsInputFactory: WCRequestDetailsInputFactory
    private let toastFactory: WCToastFactory
    private let notificationManager: WCNotificationManager
    private let validationService: WCTransactionValidationService

    lazy var displayModel: WCTransactionDisplayModel = CommonWCTransactionDisplayModel(
        transactionData: transactionData,
        userWalletRepository: userWalletRepository,
        simulationManager: simulationManager,
        securityManager: securityManager,
        viewModel: self
    )

    @Published private(set) var presentationState: PresentationState = .transactionDetails
    @Published private(set) var simulationState: TransactionSimulationState = .notStarted

    @Published private(set) var selectedFee: WCFee?
    @Published private(set) var feeRowViewModel: WCFeeRowViewModel?

    @Published private(set) var feeValidationInputs: [NotificationViewInput] = []
    @Published private(set) var simulationValidationInputs: [NotificationViewInput] = []

    private(set) var currentTransaction: WalletConnectEthTransaction?

    private(set) var feeInteractor: (any WCFeeInteractorType)?
    private var bag = Set<AnyCancellable>()

    let transactionData: WCHandleTransactionData
    let feeManager: WCTransactionFeeManager

    private(set) var isDappVerified: Bool = false

    init(
        transactionData: WCHandleTransactionData,
        feeManager: WCTransactionFeeManager,
        simulationManager: WCTransactionSimulationManager = CommonWCTransactionSimulationManager(),
        securityManager: WCTransactionSecurityManager = CommonWCTransactionSecurityManager(),
        customAllowanceManager: WCCustomAllowanceManager = CommonWCCustomAllowanceManager(),
        requestDetailsInputFactory: WCRequestDetailsInputFactory = CommonWCRequestDetailsInputFactory(),
        toastFactory: WCToastFactory = CommonWCToastFactory(),
        notificationManager: WCNotificationManager = WCNotificationManager(),
        validationService: WCTransactionValidationService = CommonWCTransactionValidationService(),
        analyticsLogger: some WalletConnectTransactionAnalyticsLogger
    ) {
        self.transactionData = transactionData
        self.feeManager = feeManager
        self.simulationManager = simulationManager
        self.securityManager = securityManager
        self.customAllowanceManager = customAllowanceManager
        self.requestDetailsInputFactory = requestDetailsInputFactory
        self.toastFactory = toastFactory
        self.notificationManager = notificationManager
        self.validationService = validationService
        self.analyticsLogger = analyticsLogger

        Task {
            self.isDappVerified = (try? await securityManager.getDAppVerificationStatus(
                for: transactionData.topic,
                connectedDAppRepository: connectedDAppRepository
            )) ?? false

            currentTransaction = parseEthTransaction()

            bindSimulationState()
            bindSimulationStateToNotifications()

            await saveSuggestedDappGas()
            await setupFeeManagement()
            await startTransactionSimulation()
        }
    }

    private func saveSuggestedDappGas() async {
        guard
            let gasString = currentTransaction?.gas,
            let gasPriceString = currentTransaction?.gasPrice,
            let gasLimit = BigUInt(gasString.removeHexPrefix(), radix: 16),
            let gasPrice = BigUInt(gasPriceString.removeHexPrefix(), radix: 16)
        else {
            return
        }

        await feeManager.feeRepository.saveSuggestedFeeFromDApp(
            gasLimit: gasLimit,
            gasPrice: gasPrice,
            for: transactionData.blockchain.networkId
        )
    }

    func handleViewAction(_ action: ViewAction) {
        switch action {
        case .cancel:
            cancel()
        case .dismissTransactionView:
            cancel()
            floatingSheetPresenter.removeActiveSheet()
        case .returnTransactionDetails:
            presentationState = .transactionDetails
        case .sign:
            sign()
        case .showRequestData:
            showRequestData()
        case .showFeeSelector:
            showFeeSelector()
        case .editApproval(let approvalInfo, let asset):
            showCustomAllowanceEditor(approvalInfo: approvalInfo, asset: asset)
        }
    }

    func getWalletModelForTransaction() -> (any WalletModel)? {
        guard let ethTransaction = currentTransaction else {
            return nil
        }

        return transactionData.userWalletModel.walletModelsManager.walletModels.first { walletModel in
            walletModel.tokenItem.blockchain.networkId == transactionData.blockchain.networkId &&
                walletModel.defaultAddressString.caseInsensitiveCompare(ethTransaction.from) == .orderedSame
        }
    }
}

private extension WCTransactionViewModel {
    func startTransactionSimulation() async {
        await simulationManager.startSimulation(
            for: transactionData,
            userWalletModel: transactionData.userWalletModel
        )

        analyticsLogger.logSignatureRequestReceived(
            transactionData: transactionData,
            simulationState: simulationState
        )
    }

    func bindSimulationState() {
        simulationManager.simulationState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                Task { @MainActor in
                    self?.simulationState = state
                }
            }
            .store(in: &bag)
    }
}

private extension WCTransactionViewModel {
    func shouldShowFeeSelector() -> Bool {
        switch transactionData.method {
        case .sendTransaction, .signTransaction:
            return true
        default:
            return false
        }
    }

    func parseEthTransaction() -> WalletConnectEthTransaction? {
        guard let transaction = try? JSONDecoder().decode(WalletConnectEthTransaction.self, from: transactionData.requestData) else {
            return nil
        }
        return transaction
    }

    func showFeeSelector() {
        guard
            let ethTransaction = currentTransaction,
            let walletModel = getWalletModelForTransaction(),
            let feeInteractor = feeInteractor as? WCFeeInteractor
        else {
            return
        }

        let feeSelectorViewModel = feeManager.createFeeSelector(
            for: ethTransaction,
            walletModel: walletModel,
            validationService: validationService,
            notificationManager: notificationManager,
            feeInteractor: feeInteractor,
            onValidationUpdate: { [weak self] inputs in
                Task { @MainActor in
                    guard let self = self, self.displayModel.isDataReady else { return }
                    self.feeValidationInputs = inputs
                }
            },
            output: self
        )

        presentationState = .feeSelector(feeSelectorViewModel)
    }

    func setupFeeManagement() async {
        guard
            shouldShowFeeSelector(),
            let ethTransaction = currentTransaction,
            let walletModel = getWalletModelForTransaction()
        else {
            return
        }

        let wcFeeInteractor = await feeManager.setupFeeManagement(
            for: ethTransaction,
            walletModel: walletModel,
            validationService: validationService,
            notificationManager: notificationManager,
            onValidationUpdate: { [weak self] inputs in
                Task { @MainActor in
                    guard let self, self.displayModel.isDataReady else { return }
                    self.feeValidationInputs = inputs
                }
            },
            onFeeChanged: { [weak self] fee in
                Task { @MainActor in
                    self?.feeDidChanged(fee:)
                }
            },
            output: self
        )

        feeInteractor = wcFeeInteractor

        wcFeeInteractor.selectedFeePublisher
            .sink { [weak self] newSelectedFee in
                Task { @MainActor in
                    self?.selectedFee = newSelectedFee
                    self?.updateFeeRowViewModel()
                    self?.handleFeeLoadingError(newSelectedFee)
                }
            }
            .store(in: &bag)
    }
}

private extension WCTransactionViewModel {
    func showCustomAllowanceEditor(approvalInfo: ApprovalInfo, asset: BlockaidChainScanResult.Asset) {
        let simulationResult: BlockaidChainScanResult?
        if case .simulationSucceeded(let result) = simulationState {
            simulationResult = result
        } else {
            simulationResult = nil
        }

        guard let input = customAllowanceManager.createCustomAllowanceInput(
            approvalInfo: approvalInfo,
            asset: asset,
            currentTransaction: currentTransaction,
            transactionData: transactionData,
            simulationResult: simulationResult,
            updateAction: { [weak self] newAmount in
                await self?.updateApprovalTransaction(approvalInfo: approvalInfo, newAmount: newAmount)
            },
            backAction: { [weak self] in
                self?.returnToTransactionDetails()
            }
        )
        else {
            return
        }

        presentationState = .customAllowance(input)
    }

    func updateApprovalTransaction(approvalInfo: ApprovalInfo, newAmount: BigUInt) async {
        guard let originalTransaction = currentTransaction else { return }

        guard let updatedTransaction = customAllowanceManager.updateApprovalTransaction(
            originalTransaction: originalTransaction,
            newAmount: newAmount
        ) else {
            await MainActor.run {
                presentationState = .transactionDetails
            }
            return
        }

        await MainActor.run {
            currentTransaction = updatedTransaction
            transactionData.updateTransaction(updatedTransaction)
            presentationState = .transactionDetails
        }
    }
}

extension WCTransactionViewModel: @preconcurrency WCFeeInteractorOutput {
    func feeDidChanged(fee: WCFee) {
        Task { @MainActor in
            selectedFee = fee
            updateFeeRowViewModel()
            updateTransactionWithFee(fee: fee)
        }
    }

    func returnToTransactionDetails() {
        presentationState = .transactionDetails
    }

    private func updateTransactionWithFee(fee: WCFee) {
        guard let currentTx = currentTransaction else { return }

        guard let updatedTx = feeManager.updateTransactionWithFee(fee, currentTransaction: currentTx) else { return }

        currentTransaction = updatedTx
        transactionData.updateTransaction(updatedTx)

        if let feeValue = fee.value.value,
           let walletModel = getWalletModelForTransaction() {
            validateFeeNotifications(fee: feeValue, transaction: updatedTx, walletModel: walletModel)
        }
    }
}

private extension WCTransactionViewModel {
    func sign() {
        Task { @MainActor [weak self] in
            guard let self else { return }

            let securityResult = securityManager.validateTransactionSecurity(
                simulationState: simulationState
            )

            if let securityResult = securityResult {
                guard let securityAlert = securityManager.createSecurityAlert(
                    for: securityResult,
                    primaryAction: { [weak self] in self?.returnToTransactionDetails() },
                    secondaryAction: { [weak self] in await self?.signTransaction() },
                    backAction: { [weak self] in self?.returnToTransactionDetails() }
                ) else {
                    await validateAndSignTransaction()
                    return
                }

                presentationState = .securityAlert(state: securityAlert.state, input: securityAlert.input)
            } else {
                await validateAndSignTransaction()
            }
        }
    }

    @MainActor
    private func validateAndSignTransaction() async {
        presentationState = .signing
        await signTransaction(onComplete: returnToTransactionDetails)
    }

    private func validateFeeNotifications(fee: Fee, transaction: WalletConnectEthTransaction, walletModel: any WalletModel) {
        guard displayModel.isDataReady, let feeInteractor else { return }

        let selectedFee = feeInteractor.selectedFee

        let allEvents = feeManager.validateFeeAndBalance(
            fee: fee,
            transaction: transaction,
            walletModel: walletModel,
            validationService: validationService,
            feeInteractor: feeInteractor,
            selectedFeeOption: selectedFee.option
        )

        feeValidationInputs = notificationManager.updateFeeValidationNotifications(allEvents, buttonAction: { [weak self] _, actionType in
            self?.handleNotificationButtonAction(actionType)
        })
    }

    private func bindSimulationStateToNotifications() {
        $simulationState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                let events = validationService.validateSimulationResult(state)
                simulationValidationInputs = notificationManager.updateSimulationValidationNotifications(events)
            }
            .store(in: &bag)
    }

    @MainActor
    func signTransaction(onComplete: (() -> Void)? = nil) async {
        do {
            analyticsLogger.logSignButtonTapped(transactionData: transactionData)

            try await transactionData.accept()

            onComplete?()
            analyticsLogger.logSignatureRequestHandled(transactionData: transactionData)

            toastFactory.makeSuccessToast(with: Localization.sendTransactionSuccess)

            floatingSheetPresenter.removeActiveSheet()
        } catch {
            onComplete?()
            analyticsLogger.logSignatureRequestFailed(transactionData: transactionData, error: error)

            toastFactory.makeWarningToast(with: error.localizedDescription)
        }
    }

    func cancel() {
        Task {
            analyticsLogger.logCancelButtonTapped()
            try? await transactionData.reject()
            floatingSheetPresenter.removeActiveSheet()
        }
    }

    func showRequestData() {
        let simulationResult: BlockaidChainScanResult?
        if case .simulationSucceeded(let result) = simulationState {
            simulationResult = result
        } else {
            simulationResult = nil
        }

        let input = requestDetailsInputFactory.createRequestDetailsInput(
            transactionData: transactionData,
            simulationResult: simulationResult,
            backAction: returnToTransactionDetails
        )

        presentationState = .requestData(input)
        analyticsLogger.logTransactionDetailsOpened(transactionData: transactionData)
    }

    private func handleFeeLoadingError(_ selectedFee: WCFee) {
        switch selectedFee.value {
        case .failedToLoad:
            let networkFeeEvent = WCNotificationEvent.networkFeeUnreachable
            feeValidationInputs = notificationManager.updateFeeValidationNotifications([networkFeeEvent], buttonAction: { [weak self] _, actionType in
                self?.handleNotificationButtonAction(actionType)
            })
        case .loading, .loaded:
            let currentEvents = notificationManager.currentFeeValidationInputs(buttonAction: { [weak self] _, actionType in
                self?.handleNotificationButtonAction(actionType)
            })
            .compactMap { $0.settings.event as? WCNotificationEvent }
            .filter { !($0 == .networkFeeUnreachable) }

            feeValidationInputs = notificationManager.updateFeeValidationNotifications(currentEvents, buttonAction: { [weak self] _, actionType in
                self?.handleNotificationButtonAction(actionType)
            })
        }
    }

    func retryFeeLoading() {
        feeInteractor?.retryFeeLoading()
    }

    private func handleNotificationButtonAction(_ actionType: NotificationButtonActionType) {
        switch actionType {
        case .refreshFee:
            retryFeeLoading()
        default:
            break
        }
    }

    private func updateFeeRowViewModel() {
        guard let selectedFee = selectedFee,
              let feeTokenItem = getFeeTokenItem() else {
            feeRowViewModel = nil
            return
        }

        feeRowViewModel = WCFeeRowViewModel(
            selectedFee: selectedFee,
            blockchain: transactionData.blockchain,
            feeTokenItem: feeTokenItem,
            onTap: { [weak self] in
                self?.handleViewAction(.showFeeSelector)
            }
        )
    }

    private func getFeeTokenItem() -> TokenItem? {
        if let walletModel = transactionData.userWalletModel.walletModelsManager.walletModels.first(where: {
            $0.tokenItem.blockchain.networkId == transactionData.blockchain.networkId
        }) {
            return walletModel.feeTokenItem
        }

        return nil
    }
}
