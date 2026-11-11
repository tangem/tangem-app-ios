//
//  LendingWithdrawCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import BlockchainSdk
import TangemUI

final class LendingWithdrawCoordinator: CoordinatorObject {
    let dismissAction: Action<OutputOptions>
    let popToRootAction: Action<PopToRootOptions>

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter
    @Injected(\.safariManager) private var safariManager: SafariManager
    @Injected(\.mailComposePresenter) private var mailPresenter: MailComposePresenter
    @Injected(\.quotesRepository) private var quotesRepository: TokenQuotesRepository

    @Published var path: [Route] = []
    @Published private(set) var amountViewModel: LendingWithdrawAmountViewModel?
    @Published private(set) var confirmViewModel: LendingWithdrawConfirmViewModel?

    private var analyticsLogger: LendingAnalyticsLogger?
    private var feeSelectorOutput: LendingFeeSelectorOutput?
    private var options: Options?
    private var model: LendingWithdrawModel?

    required init(
        dismissAction: @escaping Action<OutputOptions>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        let tokenItem = options.token.tokenItem
        let analyticsLogger = LendingAnalyticsLogger(
            transactionType: .withdraw,
            isWithUpgrade: options.upgradeImplementation != nil,
            usdPrice: { [quotesRepository] in quotesRepository.quote(for: tokenItem)?.priceUsd }
        )
        let model = LendingWithdrawModel(
            sourceToken: options.token,
            yieldModule: options.yieldModule,
            upgradeImplementation: options.upgradeImplementation,
            positionBalance: options.positionBalance,
            availableToWithdraw: options.availableToWithdraw,
            liquidityProvider: options.liquidityProvider,
            pendingTransactions: options.pendingTransactions
        )

        self.options = options
        self.model = model
        self.analyticsLogger = analyticsLogger
        feeSelectorOutput = LendingFeeSelectorOutput(output: model, analyticsLogger: analyticsLogger)
        amountViewModel = LendingWithdrawAmountViewModel(
            model: model,
            sourceToken: options.token,
            analyticsLogger: analyticsLogger,
            router: self
        )
    }
}

// MARK: - Options

extension LendingWithdrawCoordinator {
    struct Options {
        let token: SendTransferableToken
        let yieldModule: String
        let upgradeImplementation: String?
        let positionBalance: Decimal
        let availableToWithdraw: Decimal?
        let liquidityProvider: YieldModuleLendingLiquidityProvider?
        let pendingTransactions: AnyPublisher<[PendingTransactionRecord], Never>
    }
}

// MARK: - OutputOptions

extension LendingWithdrawCoordinator {
    enum OutputOptions {
        case close
        case withdrawn
    }
}

// MARK: - Route

extension LendingWithdrawCoordinator {
    enum Route: Hashable {
        case confirmation
    }
}

// MARK: - LendingWithdrawAmountRoutable

extension LendingWithdrawCoordinator: LendingWithdrawAmountRoutable {
    func openHowItWorks() {
        // [REDACTED_TODO_COMMENT]
    }

    func openFeeSelector() {
        guard let model, let analyticsLogger, let feeSelectorOutput else { return }

        analyticsLogger.startFeeSelection(
            on: path.isEmpty ? analyticsLogger.amountScreen : .confirm,
            from: model.tokenFeeProvidersManager?.selectedTokenFee.option ?? .market
        )

        let builder = SendFeeSelectorBuilder(
            tokenFeeManagerProviding: model,
            feeSelectorOutput: feeSelectorOutput,
            analyticsLogger: analyticsLogger
        )

        guard let viewModel = builder.makeSendFeeSelector(router: self) else { return }

        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openConfirmation() {
        guard let options, let model, let analyticsLogger else { return }

        Task { @MainActor in
            confirmViewModel = LendingWithdrawConfirmViewModel(
                model: model,
                sourceToken: options.token,
                mailDataBuilder: CommonSendMailDataBuilder(baseDataInput: model, sourceTokenInput: model),
                analyticsLogger: analyticsLogger,
                router: self
            )
            path.append(.confirmation)
            analyticsLogger.logConfirmScreenOpened(amount: model.sourceAmount.value?.crypto, currentApy: nil, performanceFee: nil)
        }
    }

    func closeWithdrawal() {
        dismissAction(.close)
    }
}

// MARK: - LendingWithdrawConfirmRoutable

extension LendingWithdrawCoordinator: LendingWithdrawConfirmRoutable {
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

    func withdrawalDidSend() {
        dismissAction(.withdrawn)
    }
}

// MARK: - SendFeeSelectorRoutable

extension LendingWithdrawCoordinator: SendFeeSelectorRoutable {
    func closeFeeSelector() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}
