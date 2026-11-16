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
    @Injected(\.quotesRepository) private var quotesRepository: TokenQuotesRepository

    @Published var path: [Route] = []
    @Published private(set) var amountViewModel: LendingDepositAmountViewModel?
    @Published private(set) var confirmViewModel: LendingDepositConfirmViewModel?
    @Published private(set) var resultViewModel: LendingDepositResultViewModel?

    private var analyticsLogger: LendingAnalyticsLogger?
    private var feeSelectorOutput: LendingFeeSelectorOutput?
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
        let analyticsLogger = LendingAnalyticsLogger(
            transactionType: .deposit,
            isWithUpgrade: options.request.isWithUpgrade,
            usdPrice: { [quotesRepository] in quotesRepository.quote(for: token.tokenItem)?.priceUsd }
        )
        let transferModel = TransferModel(
            userWalletId: token.userWalletInfo.id,
            userToken: token,
            transactionSigner: token.userWalletInfo.signerFactory.makeSigner(),
            feeIncludedCalculator: CommonFeeIncludedCalculator(validator: token.transactionValidator),
            analyticsLogger: analyticsLogger,
            sendAlertBuilder: CommonSendAlertBuilder(),
            predefinedValues: TransferModel.PredefinedValues(
                destination: SendDestination(value: .plain(options.request.yieldModule), source: .textField),
                contractCallData: YieldLendingTransactionProvider.depositCallData(
                    upgradeImplementation: options.request.upgradeImplementation
                ),
                preparation: options.request.preparation
            )
        )

        transferModel.informationRelevanceService = CommonInformationRelevanceService(input: transferModel, provider: transferModel)

        self.options = options
        self.transferModel = transferModel
        self.analyticsLogger = analyticsLogger
        feeSelectorOutput = LendingFeeSelectorOutput(output: transferModel, analyticsLogger: analyticsLogger)
        projection = LendingDepositProjection(currentApy: options.currentApy, performanceFee: options.performanceFee)
        amountViewModel = LendingDepositAmountViewModel(
            transferModel: transferModel,
            sourceToken: token,
            analyticsLogger: analyticsLogger,
            router: self
        )
        analyticsLogger.logDepositScreenOpened(source: options.source, currentApy: options.currentApy)
    }
}

// MARK: - Options

extension LendingDepositCoordinator {
    struct Options {
        let token: SendTransferableToken
        let request: LendingDepositRequest
        let currentApy: Decimal
        let performanceFee: Decimal
        let source: LendingAnalyticsLogger.Source
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
        guard let transferModel, let analyticsLogger, let feeSelectorOutput else { return }

        analyticsLogger.startFeeSelection(
            on: path.isEmpty ? analyticsLogger.amountScreen : .confirm,
            from: transferModel.tokenFeeProvidersManager?.selectedTokenFee.option ?? .market
        )

        let builder = SendFeeSelectorBuilder(
            tokenFeeManagerProviding: transferModel,
            feeSelectorOutput: feeSelectorOutput,
            analyticsLogger: analyticsLogger
        )

        guard let viewModel = builder.makeSendFeeSelector(router: self) else { return }

        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openConfirmation() {
        guard let options, let transferModel, let projection, let analyticsLogger else { return }

        Task { @MainActor in
            confirmViewModel = LendingDepositConfirmViewModel(
                transferModel: transferModel,
                sourceToken: options.token,
                projection: projection,
                mailDataBuilder: CommonSendMailDataBuilder(baseDataInput: transferModel, sourceTokenInput: transferModel),
                analyticsLogger: analyticsLogger,
                coordinator: self
            )
            path.append(.confirmation)
            analyticsLogger.logConfirmScreenOpened(
                amount: transferModel.sourceAmount.value?.crypto,
                currentApy: options.currentApy,
                performanceFee: options.performanceFee
            )
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

        amountViewModel = nil
        confirmViewModel = nil
        resultViewModel = LendingDepositResultViewModel(
            sourceToken: options.token,
            amount: amount,
            currentApy: projection.currentApy,
            router: self
        )
        analyticsLogger?.logSuccessScreenOpened(currentApy: options.currentApy)
    }
}

// MARK: - LendingDepositResultRoutable

extension LendingDepositCoordinator: LendingDepositResultRoutable {
    func openToken() {
        analyticsLogger?.logResultAction(.token)
        dismissAction(.token)
    }

    func openYield() {
        analyticsLogger?.logResultAction(.yield)
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
