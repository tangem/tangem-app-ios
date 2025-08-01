//
//  WCTransactionDisplayModel.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import TangemLocalization

@MainActor
protocol WCTransactionViewModelDisplayData: AnyObject {
    var simulationState: TransactionSimulationState { get }
    var feeValidationInputs: [NotificationViewInput] { get }
    var selectedFee: WCFee? { get }
    var currentTransaction: WalletConnectEthTransaction? { get }
    var feeInteractor: (any WCFeeInteractorType)? { get }
    var feeManager: WCTransactionFeeManager { get }

    func getWalletModelForTransaction() -> (any WalletModel)?
    func handleViewAction(_ action: WCTransactionViewModel.ViewAction)
}

@MainActor
protocol WCTransactionDisplayModel {
    var userWalletName: String { get }
    var isWalletRowVisible: Bool { get }
    var primaryActionButtonTitle: String { get }
    var isActionButtonBlocked: Bool { get }
    var isDataReady: Bool { get }
    var simulationDisplayModel: WCTransactionSimulationDisplayModel? { get }
}

@MainActor
final class CommonWCTransactionDisplayModel: WCTransactionDisplayModel {
    private let transactionData: WCHandleTransactionData
    private let userWalletRepository: UserWalletRepository
    private let simulationManager: WCTransactionSimulationManager
    private let securityManager: WCTransactionSecurityManager

    private weak var viewModel: WCTransactionViewModelDisplayData?

    init(
        transactionData: WCHandleTransactionData,
        userWalletRepository: UserWalletRepository,
        simulationManager: WCTransactionSimulationManager,
        securityManager: WCTransactionSecurityManager = CommonWCTransactionSecurityManager(),
        viewModel: WCTransactionViewModelDisplayData
    ) {
        self.transactionData = transactionData
        self.userWalletRepository = userWalletRepository
        self.simulationManager = simulationManager
        self.securityManager = securityManager
        self.viewModel = viewModel
    }

    var userWalletName: String {
        transactionData.userWalletModel.name
    }

    var isWalletRowVisible: Bool {
        userWalletRepository.models.filter {
            !$0.isUserWalletLocked
        }.count > 1
    }

    var primaryActionButtonTitle: String {
        if case .simulationSucceeded(let result) = viewModel?.simulationState {
            switch result.validationStatus {
            case .malicious, .warning:
                return Localization.commonContinue
            case .benign, .none:
                break
            }
        }

        return transactionData.method == .sendTransaction ? Localization.commonSend : Localization.commonSign
    }

    var isActionButtonBlocked: Bool {
        return viewModel?.feeValidationInputs.contains { input in
            guard let event = input.settings.event as? WCNotificationEvent else { return false }

            switch event {
            case .insufficientBalance, .insufficientBalanceForFee:
                return true
            default:
                return false
            }
        } ?? false
    }

    var isDataReady: Bool {
        let isFeeReady: Bool
        if let selectedFee = viewModel?.selectedFee {
            isFeeReady = !selectedFee.value.isLoading && selectedFee.value.value != nil
        } else {
            isFeeReady = false
        }

        let isBalanceReady = viewModel?.getWalletModelForTransaction()?.availableBalanceProvider.balanceType.value != nil

        return isFeeReady && isBalanceReady
    }

    var simulationDisplayModel: WCTransactionSimulationDisplayModel? {
        guard let viewModel = viewModel else { return nil }

        return simulationManager.createDisplayModel(
            from: viewModel.simulationState,
            originalTransaction: viewModel.currentTransaction,
            userWalletModel: transactionData.userWalletModel,
            onApprovalEdit: { [weak viewModel] approvalInfo, asset in
                viewModel?.handleViewAction(.editApproval(approvalInfo, asset))
            }
        )
    }
}
