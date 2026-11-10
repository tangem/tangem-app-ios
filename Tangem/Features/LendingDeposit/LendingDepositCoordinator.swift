//
//  LendingDepositCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemUI

final class LendingDepositCoordinator: CoordinatorObject {
    let dismissAction: Action<Void>
    let popToRootAction: Action<PopToRootOptions>

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter
    @Injected(\.safariManager) private var safariManager: SafariManager
    @Injected(\.mailComposePresenter) private var mailPresenter: MailComposePresenter

    @Published var path: [Route] = []
    @Published private(set) var amountViewModel: LendingDepositAmountViewModel?
    @Published private(set) var confirmViewModel: LendingDepositConfirmViewModel?

    private let analyticsLogger = LendingDepositAnalyticsLogger()
    private var options: Options?
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

        transferModel.informationRelevanceService = CommonInformationRelevanceService(input: transferModel, provider: transferModel)

        self.options = options
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
        let currentApy: Decimal
        let performanceFee: Decimal
    }
}

// MARK: - Route

extension LendingDepositCoordinator {
    enum Route: Hashable {
        case confirmation
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
        guard let options, let transferModel else { return }

        Task { @MainActor in
            confirmViewModel = LendingDepositConfirmViewModel(
                transferModel: transferModel,
                sourceToken: options.token,
                projection: LendingDepositProjection(currentApy: options.currentApy, performanceFee: options.performanceFee),
                mailDataBuilder: CommonSendMailDataBuilder(baseDataInput: transferModel, sourceTokenInput: transferModel),
                coordinator: self
            )
            path.append(.confirmation)
        }
    }

    func closeDeposit() {
        dismissAction(())
    }
}

// MARK: - LendingDepositConfirmRoutable

extension LendingDepositCoordinator: LendingDepositConfirmRoutable {
    func openURL(_ url: URL) {
        safariManager.openURL(url)
    }

    func openMail(with dataCollector: EmailDataCollector, recipient: String) {
        let mailViewModel = MailViewModel(
            logsComposer: LogsComposer(infoProvider: dataCollector),
            recipient: recipient,
            emailType: .failedToSendTx
        )

        Task { @MainActor in
            mailPresenter.present(viewModel: mailViewModel)
        }
    }

    func depositDidSend() {
        // [REDACTED_TODO_COMMENT]
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
