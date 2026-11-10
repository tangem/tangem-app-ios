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
    let dismissAction: Action<OutputOptions>
    let popToRootAction: Action<PopToRootOptions>

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter
    @Injected(\.safariManager) private var safariManager: SafariManager
    @Injected(\.mailComposePresenter) private var mailPresenter: MailComposePresenter

    @Published var path: [Route] = []
    @Published private(set) var amountViewModel: LendingDepositAmountViewModel?
    @Published private(set) var confirmViewModel: LendingDepositConfirmViewModel?
    @Published private(set) var resultViewModel: LendingDepositResultViewModel?

    private let analyticsLogger = LendingDepositAnalyticsLogger()
    private var options: Options?
    private var transferModel: TransferModel?
    private var projection: LendingDepositProjection?

    required init(
        dismissAction: @escaping Action<OutputOptions>,
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
        projection = LendingDepositProjection(currentApy: options.currentApy, performanceFee: options.performanceFee)
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

// MARK: - OutputOptions

extension LendingDepositCoordinator {
    enum OutputOptions {
        case close
        case token
        case yield
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
        guard let options, let transferModel, let projection else { return }

        Task { @MainActor in
            confirmViewModel = LendingDepositConfirmViewModel(
                transferModel: transferModel,
                sourceToken: options.token,
                projection: projection,
                mailDataBuilder: CommonSendMailDataBuilder(baseDataInput: transferModel, sourceTokenInput: transferModel),
                coordinator: self
            )
            path.append(.confirmation)
        }
    }

    func closeDeposit() {
        dismissAction(.close)
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
        guard let options, let projection, let amount = transferModel?.sourceAmount.value?.crypto else { return }

        resultViewModel = LendingDepositResultViewModel(
            sourceToken: options.token,
            amount: amount,
            currentApy: projection.currentApy,
            router: self
        )
    }
}

// MARK: - LendingDepositResultRoutable

extension LendingDepositCoordinator: LendingDepositResultRoutable {
    func openToken() {
        dismissAction(.token)
    }

    func openYield() {
        dismissAction(.yield)
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
