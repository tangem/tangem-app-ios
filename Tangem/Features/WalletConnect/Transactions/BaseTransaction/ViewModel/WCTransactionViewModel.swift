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
import TangemAssets

@MainActor
final class WCTransactionViewModel: ObservableObject & FloatingSheetContentViewModel & WCTransactionViewModelDisplayData {
    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter
    @Injected(\.connectedDAppRepository) private var connectedDAppRepository: any WalletConnectConnectedDAppRepository

    private let analyticsLogger: any WalletConnectTransactionAnalyticsLogger
    private let simulationManager: WCTransactionSimulationManager
    private let securityManager: WCTransactionSecurityManager
    private let customAllowanceManager: WCCustomAllowanceManager
    private let requestDetailsInputFactory: WCRequestDetailsInputFactory
    private let toastFactory = WCToastFactory()
    private let notificationManager: WCNotificationManager
    private let validationService: WCTransactionValidationService

    lazy var displayModel: WCTransactionDisplayModel = CommonWCTransactionDisplayModel(
        transactionData: transactionData,
        simulationManager: simulationManager,
        securityManager: securityManager,
        viewModel: self
    )

    @Published private(set) var presentationState: PresentationState = .transactionDetails
    @Published private(set) var simulationState: TransactionSimulationState = .loading

    @Published private(set) var selectedFee: WCFee?
    @Published private(set) var feeRowViewModel: WCFeeRowViewModel?

    @Published private(set) var feeValidationInputs: [NotificationViewInput] = []
    @Published private(set) var simulationValidationInputs: [NotificationViewInput] = []

    private(set) var sendableTransaction: WCSendableTransaction?

    private(set) var feeInteractor: (any WCFeeInteractorType)?
    private var bag = Set<AnyCancellable>()

    let transactionData: WCHandleTransactionData
    let addressRowViewModel: WCTransactionAddressRowViewModel?
    let feeManager: WCTransactionFeeManager

    private(set) var isDappVerified: Bool = false

    init(
        transactionData: WCHandleTransactionData,
        feeManager: WCTransactionFeeManager,
        simulationManager: WCTransactionSimulationManager = CommonWCTransactionSimulationManager(),
        securityManager: WCTransactionSecurityManager = CommonWCTransactionSecurityManager(),
        customAllowanceManager: WCCustomAllowanceManager = CommonWCCustomAllowanceManager(),
        requestDetailsInputFactory: WCRequestDetailsInputFactory = CommonWCRequestDetailsInputFactory(),
        notificationManager: WCNotificationManager = WCNotificationManager(),
        validationService: WCTransactionValidationService = CommonWCTransactionValidationService(),
        analyticsLogger: some WalletConnectTransactionAnalyticsLogger
    ) {
        self.transactionData = transactionData
        self.addressRowViewModel = Self.makeAddressRowViewModel(from: transactionData)
        self.feeManager = feeManager
        self.simulationManager = simulationManager
        self.securityManager = securityManager
        self.customAllowanceManager = customAllowanceManager
        self.requestDetailsInputFactory = requestDetailsInputFactory
        self.notificationManager = notificationManager
        self.validationService = validationService
        self.analyticsLogger = analyticsLogger

        Task {
            self.isDappVerified = (try? await securityManager.getDAppVerificationStatus(
                for: transactionData.topic,
                connectedDAppRepository: connectedDAppRepository
            )) ?? false

            sendableTransaction = parseEthTransaction()

            bind()

            await saveSuggestedDappGas()
            await setupFeeManagement()
            await startTransactionSimulation()
        }
    }

    private func saveSuggestedDappGas() async {
        guard
            let gasString = sendableTransaction?.gas,
            let gasPriceString = sendableTransaction?.gasPrice,
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
        guard let ethTransaction = sendableTransaction else {
            return nil
        }

        let walletModels: [any WalletModel]

        do {
            walletModels = try WCWalletModelsResolver.resolveWalletModels(
                account: transactionData.account, userWalletModel: transactionData.userWalletModel
            )
        } catch {
            WCLogger.error(error: error)
            return nil
        }

        return walletModels.first { walletModel in
            walletModel.tokenItem.blockchain.networkId == transactionData.blockchain.networkId &&
                walletModel.walletConnectAddress.caseInsensitiveCompare(ethTransaction.from) == .orderedSame
        }
    }

    func startTransactionSimulation() async {
        simulationState = .loading

        let walletModels: [any WalletModel]

        do {
            walletModels = try WCWalletModelsResolver.resolveWalletModels(
                account: transactionData.account, userWalletModel: transactionData.userWalletModel
            )
        } catch {
            WCLogger.error(error: error)

            simulationState = .simulationFailed(error: error.localizedDescription)

            analyticsLogger.logSignatureRequestReceived(
                transactionData: transactionData,
                simulationState: simulationState
            )

            return
        }

        simulationState = await simulationManager.startSimulation(
            for: transactionData,
            walletModels: walletModels
        )

        analyticsLogger.logSignatureRequestReceived(
            transactionData: transactionData,
            simulationState: simulationState
        )
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

    func parseEthTransaction() -> WCSendableTransaction? {
        guard let transaction = try? JSONDecoder().decode(WalletConnectEthTransaction.self, from: transactionData.requestData) else {
            return nil
        }
        return WCSendableTransaction(from: transaction)
    }

    func showFeeSelector() {
        guard
            let walletModel = getWalletModelForTransaction(),
            let feeInteractor = feeInteractor as? WCFeeInteractor
        else {
            return
        }

        let feeSelectorViewModel = feeManager.createFeeSelector(
            walletModel: walletModel,
            feeInteractor: feeInteractor,
            output: self
        )

        presentationState = .feeSelector(feeSelectorViewModel)
    }

    func setupFeeManagement() async {
        guard
            shouldShowFeeSelector(),
            let ethTransaction = sendableTransaction,
            let walletModel = getWalletModelForTransaction()
        else {
            return
        }

        feeInteractor = await feeManager.setupFeeManagement(
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
            output: self
        )

        updateFeeRowViewModel()
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
            currentTransaction: sendableTransaction,
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

        let viewModel = WCCustomAllowanceViewModel(input: input)

        presentationState = .customAllowance(viewModel)
    }

    func updateApprovalTransaction(approvalInfo: ApprovalInfo, newAmount: BigUInt) async {
        guard let transaction = sendableTransaction else {
            return
        }

        let newData = WCApprovalAnalyzer.createApprovalData(
            spender: approvalInfo.spender,
            amount: newAmount
        )

        let updatedTransaction = transaction.withUpdatedData(newData)

        sendableTransaction = updatedTransaction
        transactionData.updateSendableTransaction(updatedTransaction)
        presentationState = .transactionDetails
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
        guard let currentTx = sendableTransaction else {
            return
        }

        if let updatedTx = feeManager.updateTransactionWithFee(fee, currentTransaction: currentTx) {
            sendableTransaction = updatedTx
            transactionData.updateSendableTransaction(updatedTx)
        }

        if let feeValue = fee.value.value, let walletModel = getWalletModelForTransaction() {
            validateFeeNotifications(fee: feeValue, transaction: currentTx, walletModel: walletModel)
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

                let viewModel = WCTransactionSecurityAlertViewModel(
                    state: securityAlert.state,
                    input: securityAlert.input
                )

                presentationState = .securityAlert(viewModel)
            } else {
                await validateAndSignTransaction()
            }
        }
    }

    private func validateAndSignTransaction() async {
        presentationState = .signing
        await signTransaction(onComplete: returnToTransactionDetails)
    }

    private func validateFeeNotifications(fee: Fee, transaction: WCSendableTransaction, walletModel: any WalletModel) {
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

    private func bind() {
        $simulationState
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, state in
                let events = viewModel.validationService.validateSimulationResult(state)
                viewModel.simulationValidationInputs = viewModel.notificationManager.updateSimulationValidationNotifications(events)
            }
            .store(in: &bag)

        $selectedFee
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, fee in
                if case .failure = fee?.value, let fee {
                    viewModel.handleFeeLoadingError(fee)
                }
            }
            .store(in: &bag)
    }

    @MainActor
    func signTransaction(onComplete: (() -> Void)? = nil) async {
        do {
            analyticsLogger.logSignButtonTapped(transactionData: transactionData)

            switch try await transactionData.validate() {
            case .empty:
                try await transactionData.accept()
                successSignTransaction(onComplete: onComplete)
            case .multipleTransactions:
                let input = WCMultipleTransactionAlertInput(
                    primaryAction: { [weak self] in
                        do {
                            try await self?.handleMultipleSignTransaction(onComplete: onComplete)
                        } catch {
                            self?.errorSignTransaction(with: error, onComplete: onComplete)
                        }
                    },
                    secondaryAction: { [weak self] in self?.returnToTransactionDetails() },
                    backAction: { [weak self] in self?.returnToTransactionDetails() }
                )

                let state = WCMultipleTransactionsAlertFactory.makeMultipleTransactionAlertState(tangemIconProvider: CommonTangemIconProvider(config: transactionData.userWalletModel.config))
                let viewModel = WCMultipleTransactionAlertViewModel(state: state, input: input)

                presentationState = .multipleTransactionsAlert(viewModel)
            }
        } catch {
            errorSignTransaction(with: error, onComplete: onComplete)
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
        case .failure:
            let networkFeeEvent = WCNotificationEvent.networkFeeUnreachable
            feeValidationInputs = notificationManager.updateFeeValidationNotifications([networkFeeEvent], buttonAction: { [weak self] _, actionType in
                self?.handleNotificationButtonAction(actionType)
            })
        case .loading, .success:
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
        guard let selectedFee = selectedFee, let feeTokenItem = getFeeTokenItem() else {
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
        let walletModels: [any WalletModel]

        do {
            walletModels = try WCWalletModelsResolver.resolveWalletModels(
                account: transactionData.account, userWalletModel: transactionData.userWalletModel
            )
        } catch {
            WCLogger.error(error: error)
            return nil
        }

        guard let walletModel = walletModels.first(where: {
            $0.tokenItem.blockchain.networkId == transactionData.blockchain.networkId
        }) else {
            return nil
        }

        return walletModel.feeTokenItem
    }

    private static func makeAddressRowViewModel(from transactionData: WCHandleTransactionData) -> WCTransactionAddressRowViewModel? {
        let walletModels: [any WalletModel]

        do {
            walletModels = try WCWalletModelsResolver.resolveWalletModels(
                account: transactionData.account, userWalletModel: transactionData.userWalletModel
            )
        } catch {
            WCLogger.error(error: error)
            return nil
        }

        let filteredWalletModels = walletModels
            .filter { walletModel in
                let isCoin = walletModel.tokenItem.blockchain.networkId == transactionData.blockchain.networkId && walletModel.isMainToken
                let isTokenInOtherBlockchain = walletModel.tokenItem.token?.id == transactionData.blockchain.networkId

                return isCoin || isTokenInOtherBlockchain
            }

        guard
            filteredWalletModels.count > 1,
            let mainAddress = filteredWalletModels.first(where: { $0.isMainToken })?.walletConnectAddress
        else {
            return nil
        }

        return WCTransactionAddressRowViewModel(address: mainAddress)
    }

    private func successSignTransaction(onComplete: (() -> Void)? = nil) {
        onComplete?()

        analyticsLogger.logSignatureRequestHandled(transactionData: transactionData, simulationState: simulationState)

        toastFactory.makeSuccessToast(with: Localization.sendTransactionSuccess)

        floatingSheetPresenter.removeActiveSheet()
    }

    private func errorSignTransaction(with error: Error, onComplete: (() -> Void)? = nil) {
        onComplete?()

        analyticsLogger.logSignatureRequestFailed(transactionData: transactionData, error: error)

        toastFactory.makeWarningToast(with: error.localizedDescription)
    }

    private func handleMultipleSignTransaction(onComplete: (() -> Void)? = nil) async throws {
        do {
            presentationState = .loading
            try await transactionData.accept()
            successSignTransaction(onComplete: onComplete)
        } catch let error as WalletConnectTransactionRequestProcessingError {
            if case .eraseMultipleTransactions = error {
                successSignTransaction(onComplete: onComplete)
                return
            }

            throw error
        }
    }
}
