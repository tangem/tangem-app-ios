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

@MainActor
final class WCTransactionViewModel: ObservableObject & FloatingSheetContentViewModel {
    // MARK: Dependencies

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: FloatingSheetPresenter

    private let simulationService: WCTransactionSimulationService
    private let simulationDisplayService: WCTransactionSimulationDisplayService
    private let feeSelectorFactory: WCFeeSelectorFactory

    // MARK: Published properties

    @Published private(set) var presentationState: PresentationState = .transactionDetails
    @Published private(set) var simulationState: TransactionSimulationState = .notStarted

    // MARK: Fee management

    @Published private(set) var selectedFee: WCFee?

    // MARK: Approval editing

    @Published private(set) var currentTransaction: WalletConnectEthTransaction?

    private var feeInteractor: WCFeeInteractor?

    // MARK: Public properties

    let dappData: WalletConnectDAppData
    var transactionData: WCHandleTransactionData

    var userWalletName: String {
        transactionData.userWalletModel.name
    }

    var primariActionButtonTitle: String {
        switch transactionData.method {
        case .sendTransaction:
            "Send"
        default:
            "Sign"
        }
    }

    // MARK: - Simulation Display Model

    var simulationDisplayModel: WCTransactionSimulationDisplayModel {
        simulationDisplayService.createDisplayModel(
            from: simulationState,
            originalTransaction: currentTransaction,
            userWalletModel: transactionData.userWalletModel,
            onApprovalEdit: { [weak self] approvalInfo, asset in
                self?.handleViewAction(.editApproval(approvalInfo, asset))
            }
        )
    }

    init(
        dappData: WalletConnectDAppData,
        transactionData: WCHandleTransactionData,
        simulationService: WCTransactionSimulationService = CommonWCTransactionSimulationService(blockaidService: BlockaidFactory().makeBlockaidAPIService()),
        simulationDisplayService: WCTransactionSimulationDisplayService? = nil,
        feeSelectorFactory: WCFeeSelectorFactory = WCFeeSelectorFactory()
    ) {
        self.dappData = dappData
        self.transactionData = transactionData
        self.simulationService = simulationService
        self.simulationDisplayService = simulationDisplayService ?? WCTransactionSimulationDisplayService()
        self.feeSelectorFactory = feeSelectorFactory

        currentTransaction = parseEthTransaction()

        startTransactionSimulation()
        setupFeeManagement()
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
}

// MARK: - Transaction Simulation

private extension WCTransactionViewModel {
    func startTransactionSimulation() {
        Task {
            simulationState = .loading

            guard
                let address = transactionData.userWalletModel.walletModelsManager.walletModels.first(where: {
                    $0.tokenItem.blockchain.networkId == transactionData.blockchain.networkId
                })?.defaultAddressString
            else {
                return
            }

            simulationState = await simulationService.simulateTransaction(
                for: transactionData.method,
                address: address,
                blockchain: transactionData.blockchain,
                requestData: transactionData.requestData,
                domain: dappData.domain
            )
        }
    }
}

// MARK: - Fee Management

private extension WCTransactionViewModel {
    func setupFeeManagement() {
        guard let ethTransaction = currentTransaction else {
            return
        }

        guard let walletModel = getWalletModelForTransaction() else {
            return
        }

        let feeProvider = CommonWCFeeProvider()
        let interactor = WCFeeInteractor(
            transaction: ethTransaction,
            walletModel: walletModel,
            feeProvider: feeProvider,
            output: self
        )

        feeInteractor = interactor
    }

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

    func getWalletModelForTransaction() -> (any WalletModel)? {
        guard let ethTransaction = currentTransaction else {
            return nil
        }

        return transactionData.userWalletModel.walletModelsManager.walletModels.first { walletModel in
            walletModel.tokenItem.blockchain.networkId == transactionData.blockchain.networkId &&
                walletModel.defaultAddressString.caseInsensitiveCompare(ethTransaction.from) == .orderedSame
        }
    }

    func showFeeSelector() {
        guard let feeInteractor, let walletModel = getWalletModelForTransaction() else { return }

        let feeSelectorViewModel = feeSelectorFactory.createFeeSelectorFromInteractor(
            feeInteractor: feeInteractor,
            walletModel: walletModel
        )

        presentationState = .feeSelector(feeSelectorViewModel)
    }
}

// MARK: - Custom Allowance

private extension WCTransactionViewModel {
    func showCustomAllowanceEditor(approvalInfo: ApprovalInfo, asset: BlockaidChainScanResult.Asset) {
        guard let tokenInfo = determineTokenInfoForApproval(approvalInfo: approvalInfo) else { return }

        let input = WCCustomAllowanceInput(
            approvalInfo: approvalInfo,
            tokenInfo: tokenInfo,
            asset: asset,
            updateAction: { [weak self] newAmount in
                Task { @MainActor in
                    await self?.updateApprovalTransaction(approvalInfo: approvalInfo, newAmount: newAmount)
                }
            },
            backAction: { [weak self] in
                self?.returnToTransactionDetails()
            }
        )

        presentationState = .customAllowance(input)
    }

    func updateApprovalTransaction(approvalInfo: ApprovalInfo, newAmount: BigUInt) async {
        guard let originalTransaction = currentTransaction else {
            return
        }

        guard let updatedTransaction = WCApprovalAnalyzer.createUpdatedApproval(
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

            setupFeeManagement()

            presentationState = .transactionDetails
        }
    }

    func determineTokenInfoForApproval(approvalInfo: ApprovalInfo) -> WCApprovalHelpers.TokenInfo? {
        guard let transaction = currentTransaction else {
            return WCApprovalHelpers.TokenInfo(
                symbol: "",
                decimals: 18,
                source: .wallet
            )
        }

        let simulationResult = getSimulationResult()

        return WCApprovalHelpers.determineTokenInfo(
            contractAddress: transaction.to,
            amount: approvalInfo.amount,
            userWalletModel: transactionData.userWalletModel,
            simulationResult: simulationResult
        )
    }

    private func getSimulationResult() -> BlockaidChainScanResult? {
        if case .simulationSucceeded(let result) = simulationState {
            return result
        }
        return nil
    }
}

// MARK: - WCFeeInteractorOutput

extension WCTransactionViewModel: @preconcurrency WCFeeInteractorOutput {
    func feeDidChanged(fee: WCFee) {
        Task { @MainActor in
            selectedFee = fee

            updateTransactionWithFee(fee: fee)
        }
    }

    func returnToTransactionDetails() {
        presentationState = .transactionDetails
    }

    private func updateTransactionWithFee(fee: WCFee) {
        guard let currentTx = currentTransaction else {
            return
        }

        guard let feeValue = fee.value.value else {
            return
        }

        guard let ethereumFeeParameters = feeValue.parameters as? EthereumFeeParameters else {
            return
        }

        let updatedTx: WalletConnectEthTransaction

        switch ethereumFeeParameters.parametersType {
        case .legacy(let legacyParams):
            let gasLimitHex = String(legacyParams.gasLimit, radix: 16).addHexPrefix()
            let gasPriceHex = String(legacyParams.gasPrice, radix: 16).addHexPrefix()

            updatedTx = WalletConnectEthTransaction(
                from: currentTx.from,
                to: currentTx.to,
                value: currentTx.value,
                data: currentTx.data,
                gas: gasLimitHex,
                gasLimit: gasLimitHex,
                gasPrice: gasPriceHex,
                nonce: currentTx.nonce
            )

        case .eip1559(let eip1559Params):
            let gasLimitHex = String(eip1559Params.gasLimit, radix: 16).addHexPrefix()
            let maxFeeHex = String(eip1559Params.maxFeePerGas, radix: 16).addHexPrefix()

            updatedTx = WalletConnectEthTransaction(
                from: currentTx.from,
                to: currentTx.to,
                value: currentTx.value,
                data: currentTx.data,
                gas: gasLimitHex,
                gasLimit: gasLimitHex,
                gasPrice: maxFeeHex,
                nonce: currentTx.nonce
            )
        }

        currentTransaction = updatedTx

        transactionData.updateTransaction(updatedTx)
    }
}

// MARK: - Action methods

private extension WCTransactionViewModel {
    func sign() {
        Task { @MainActor [weak self] in
            switch self?.simulationState {
            case .simulationSucceeded(let result) where result.validationStatus == .warning || result.validationStatus == .malicious:
                guard
                    let validationStatus = result.validationStatus,
                    let securityAlertViewModel = WCTransactionSecurityAlertFactory.makeSecurityAlertViewModel(
                        input: .init(
                            validationStatus: validationStatus,
                            primaryAction: { self?.cancel() },
                            secondaryAction: {
                                Task { [weak self] in
                                    await self?.signTransaction()
                                }
                            },
                            closeAction: { self?.cancel() }
                        )
                    )
                else {
                    return
                }

                self?.presentationState = .securityAlert(securityAlertViewModel)
            default:
                self?.presentationState = .signing
                await self?.signTransaction(onComplete: self?.returnToTransactionDetails)
            }
        }
    }

    @MainActor
    func signTransaction(onComplete: (() -> Void)? = nil) async {
        do {
            try await transactionData.accept()

            onComplete?()

            makeSuccessToast(with: Localization.sendTransactionSuccess)

            floatingSheetPresenter.removeActiveSheet()
        } catch {
            onComplete?()

            makeWarningToast(with: error.localizedDescription)
        }
    }

    func cancel() {
        Task {
            try? await transactionData.reject()
            floatingSheetPresenter.removeActiveSheet()
        }
    }

    func showRequestData() {
        let input = WCRequestDetailsInput(
            builder: .init(
                method: transactionData.method,
                source: transactionData.requestData
            ),
            rawTransaction: transactionData.rawTransaction,
            backAction: returnToTransactionDetails
        )

        presentationState = .requestData(input)
    }
}

// MARK: - Factory methods

extension WCTransactionViewModel {
    private func makeWarningToast(with text: String) {
        Toast(view: WarningToast(text: text))
            .present(
                layout: .top(padding: 20),
                type: .temporary()
            )
    }

    private func makeSuccessToast(with text: String) {
        Toast(view: SuccessToast(text: text))
            .present(
                layout: .top(padding: 20),
                type: .temporary()
            )
    }
}

extension WCTransactionViewModel {
    enum ViewAction {
        case dismissTransactionView
        case cancel
        case sign
        case returnTransactionDetails
        case showRequestData
        case showFeeSelector
        case editApproval(ApprovalInfo, BlockaidChainScanResult.Asset)
    }

    enum PresentationState: Equatable {
        case signing
        case transactionDetails
        case requestData(WCRequestDetailsInput)
        case feeSelector(FeeSelectorContentViewModel)
        case customAllowance(WCCustomAllowanceInput)
        case securityAlert(WCTransactionSecurityAlertViewModel)

        static func == (lhs: PresentationState, rhs: PresentationState) -> Bool {
            switch (lhs, rhs) {
            case (.signing, .signing),
                 (.transactionDetails, .transactionDetails):
                return true
            case (.requestData(let lhsInput), .requestData(let rhsInput)):
                return lhsInput == rhsInput
            case (.feeSelector, .feeSelector):
                return true
            case (.customAllowance(let lhsInput), .customAllowance(let rhsInput)):
                return lhsInput == rhsInput
            case (.securityAlert(let lhsStatus), .securityAlert(let rhsStatus)):
                return lhsStatus == rhsStatus
            default:
                return false
            }
        }
    }
}
