//
//  LendingDepositCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import TangemUI

final class LendingDepositCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter

    @Published private(set) var amountViewModel: LendingDepositAmountViewModel?

    private let analyticsLogger = LendingDepositAnalyticsLogger()
    private var transferModel: TransferModel?

    required init(
        dismissAction: @escaping Action<Void>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        let token = options.token
        let transferModel = TransferModel(
            userWalletId: token.userWalletInfo.id,
            userToken: token,
            transactionSigner: token.userWalletInfo.signerFactory.makeSigner(),
            feeIncludedCalculator: CommonFeeIncludedCalculator(validator: token.transactionValidator),
            analyticsLogger: analyticsLogger,
            sendAlertBuilder: CommonSendAlertBuilder(),
            predefinedValues: TransferModel.PredefinedValues(
                destination: SendDestination(value: .plain(options.yieldModule), source: .textField),
                contractCallData: YieldLendingTransactionProvider.depositCallData(
                    upgradeImplementation: options.upgradeImplementation
                )
            )
        )

        self.transferModel = transferModel
        amountViewModel = LendingDepositAmountViewModel(transferModel: transferModel, sourceToken: token, router: self)
    }
}

// MARK: - Options

extension LendingDepositCoordinator {
    struct Options {
        let token: SendTransferableToken
        let yieldModule: String
        let upgradeImplementation: String?
    }
}

// MARK: - LendingDepositAmountRoutable

extension LendingDepositCoordinator: LendingDepositAmountRoutable {
    func openHowItWorks() {
        // [REDACTED_TODO_COMMENT]
    }

    func openFeeSelector() {
        guard let transferModel else { return }

        let builder = SendFeeSelectorBuilder(
            tokenFeeManagerProviding: transferModel,
            feeSelectorOutput: transferModel,
            analyticsLogger: analyticsLogger
        )

        guard let viewModel = builder.makeSendFeeSelector(router: self) else { return }

        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openConfirmation() {
        // [REDACTED_TODO_COMMENT]
    }

    func closeDeposit() {
        dismissAction(())
    }
}

// MARK: - SendFeeSelectorRoutable

extension LendingDepositCoordinator: SendFeeSelectorRoutable {
    func closeFeeSelector() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}
