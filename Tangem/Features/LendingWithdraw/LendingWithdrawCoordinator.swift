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

    @Published var path: [Route] = []
    @Published private(set) var amountViewModel: LendingWithdrawAmountViewModel?
    @Published private(set) var confirmViewModel: LendingWithdrawConfirmViewModel?

    private let analyticsLogger = LendingWithdrawAnalyticsLogger()
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
        amountViewModel = LendingWithdrawAmountViewModel(model: model, sourceToken: options.token, router: self)
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
        guard let model else { return }

        let builder = SendFeeSelectorBuilder(
            tokenFeeManagerProviding: model,
            feeSelectorOutput: model,
            analyticsLogger: analyticsLogger
        )

        guard let viewModel = builder.makeSendFeeSelector(router: self) else { return }

        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openConfirmation() {
        guard let options, let model else { return }

        Task { @MainActor in
            confirmViewModel = LendingWithdrawConfirmViewModel(
                model: model,
                sourceToken: options.token,
                mailDataBuilder: CommonSendMailDataBuilder(baseDataInput: model, sourceTokenInput: model),
                router: self
            )
            path.append(.confirmation)
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
