//
//  TangemPayMainCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import TangemFoundation

class TangemPayMainCoordinator: CoordinatorObject {
    let dismissAction: Action<DismissOptions?>
    let popToRootAction: Action<PopToRootOptions>

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter
    @Injected(\.mailComposePresenter) private var mailPresenter: MailComposePresenter
    @Injected(\.safariManager) private var safariManager: SafariManager

    // MARK: - Root view model

    @Published private(set) var rootViewModel: TangemPayMainViewModel?

    // MARK: - Child coordinators

    @Published var expressCoordinator: ExpressCoordinator?

    // MARK: - Child view models

    @Published var addToApplePayGuideViewModel: TangemPayAddToAppPayGuideViewModel?
    @Published var tangemPayPinViewModel: TangemPayPinViewModel?
    @Published var termsAndLimitsViewModel: WebViewContainerViewModel?
    @Published var pendingExpressTxStatusBottomSheet: PendingExpressTxStatusBottomSheetViewModel?

    required init(
        dismissAction: @escaping Action<DismissOptions?>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        rootViewModel = .init(
            userWalletInfo: options.userWalletInfo,
            tangemPayAccount: options.tangemPayAccount,
            coordinator: self
        )
    }
}

// MARK: - Options

extension TangemPayMainCoordinator {
    struct Options {
        let userWalletInfo: UserWalletInfo
        let tangemPayAccount: TangemPayAccount
    }

    typealias DismissOptions = FeeCurrencyNavigatingDismissOption
}

// MARK: - Private

extension TangemPayMainCoordinator {
    func openExpress(factory: ExpressModulesFactory) {
        let dismissAction: ExpressCoordinator.DismissAction = { [weak self] options in
            self?.expressCoordinator = nil
            self?.dismiss(with: options)
        }

        let coordinator = ExpressCoordinator(
            factory: factory,
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )

        coordinator.start(with: .default)
        expressCoordinator = coordinator
    }
}

// MARK: - TangemPayMainRoutable

extension TangemPayMainCoordinator: TangemPayMainRoutable {
    func openAddToApplePayGuide(viewModel: TangemPayCardDetailsViewModel) {
        addToApplePayGuideViewModel = TangemPayAddToAppPayGuideViewModel(
            tangemPayCardDetailsViewModel: viewModel,
            coordinator: self
        )
    }

    func openTangemPaySetPin(tangemPayAccount: TangemPayAccount) {
        tangemPayPinViewModel = TangemPayPinViewModel(
            tangemPayAccount: tangemPayAccount,
            coordinator: self
        )
    }

    func openTangemPayCheckPin(tangemPayAccount: TangemPayAccount) {
        let viewModel = TangemPayPinCheckViewModel(
            account: tangemPayAccount,
            coordinator: self
        )
        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openTangemPayAddFundsSheet(input: TangemPayAddFundsSheetViewModel.Input) {
        let viewModel = TangemPayAddFundsSheetViewModel(input: input, coordinator: self)
        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openTangemPayWithdraw(input: ExpressDependenciesInput) {
        Task { @MainActor in
            let factory = CommonExpressModulesFactory(input: input)
            let viewModel = TangemPayWithdrawNoteSheetViewModel(coordinator: self) { [weak self] in
                Task { @MainActor in
                    self?.floatingSheetPresenter.removeActiveSheet()
                    try? await Task.sleep(for: .seconds(0.2))
                    self?.openExpress(factory: factory)
                }
            }

            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openTangemWithdrawInProgressSheet() {
        let viewModel = TangemPayWithdrawInProgressSheetViewModel(coordinator: self)

        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openTangemPayNoDepositAddressSheet() {
        let viewModel = TangemPayNoDepositAddressSheetViewModel(coordinator: self)

        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openTangemPayFreezeSheet(freezeAction: @escaping () -> Void) {
        Task { @MainActor in
            let viewModel = TangemPayFreezeSheetViewModel(
                coordinator: self,
                freezeAction: freezeAction
            )
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openTangemPayTransactionDetailsSheet(
        transaction: TangemPayTransactionRecord,
        userWalletId: String,
        customerId: String
    ) {
        let viewModel = TangemPayTransactionDetailsViewModel(
            transaction: transaction,
            userWalletId: userWalletId,
            customerId: customerId,
            coordinator: self
        )

        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openPendingExpressTransactionDetails(
        pendingTransaction: PendingTransaction,
        userWalletInfo: UserWalletInfo,
        tokenItem: TokenItem,
        pendingTransactionsManager: any PendingExpressTransactionsManager
    ) {
        pendingExpressTxStatusBottomSheet = PendingExpressTxStatusBottomSheetViewModel(
            pendingTransaction: pendingTransaction,
            currentTokenItem: tokenItem,
            userWalletInfo: userWalletInfo,
            pendingTransactionsManager: pendingTransactionsManager,
            router: self
        )
    }

    func openTermsAndLimits() {
        termsAndLimitsViewModel = .init(
            url: AppConstants.tangemPayTermsAndLimitsURL,
            title: "",
            withCloseButton: true
        )
    }
}

// MARK: - TangemPayNoDepositAddressSheetRoutable

extension TangemPayMainCoordinator: TangemPayNoDepositAddressSheetRoutable {
    func closeNoDepositAddressSheet() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}

// MARK: - TangemPayWithdrawNoteSheetRoutable

extension TangemPayMainCoordinator: TangemPayWithdrawNoteSheetRoutable {
    func closeWithdrawNoteSheetPopup() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}

// MARK: - TangemPayWithdrawInProgressSheetRoutable

extension TangemPayMainCoordinator: TangemPayWithdrawInProgressSheetRoutable {
    func closeWithdrawInProgressSheet() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}

// MARK: - TangemPayFreezeSheetRoutable

extension TangemPayMainCoordinator: TangemPayFreezeSheetRoutable {
    func closeFreezeSheet() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}

// MARK: - TangemPayAddToAppPayGuideRoutable

extension TangemPayMainCoordinator: TangemPayAddToAppPayGuideRoutable {
    func closeAddToAppPayGuide() {
        addToApplePayGuideViewModel = nil
    }
}

// MARK: - TangemPayPinRoutable

extension TangemPayMainCoordinator: TangemPayPinRoutable {
    func closeTangemPayPin() {
        tangemPayPinViewModel = nil
    }
}

// MARK: - TangemPayAddFundsSheetRoutable

extension TangemPayMainCoordinator: TangemPayAddFundsSheetRoutable {
    func addFundsSheetRequestReceive(viewModel: ReceiveMainViewModel) {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
            try? await Task.sleep(for: .seconds(0.2))
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func addFundsSheetRequestSwap(input: ExpressDependenciesDestinationInput) {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()

            // Give some time to hide sheet with animation
            try? await Task.sleep(for: .seconds(0.2))
            let factory = CommonExpressModulesFactory(input: input)
            openExpress(factory: factory)
        }
    }

    func closeAddFundsSheet() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}

// MARK: - TangemPayTransactionDetailsRoutable

extension TangemPayMainCoordinator: TangemPayTransactionDetailsRoutable {
    func transactionDetailsDidRequestClose() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }

    func transactionDetailsDidRequestDispute(dataCollector: EmailDataCollector, subject: VisaEmailSubject) {
        let logsComposer = LogsComposer(infoProvider: dataCollector, includeZipLogs: false)
        let mailViewModel = MailViewModel(
            logsComposer: logsComposer,
            recipient: EmailConfig.visaDefault(subject: subject).recipient,
            emailType: .visaFeedback(subject: subject)
        )

        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
            mailPresenter.present(viewModel: mailViewModel)
        }
    }
}

// MARK: - PendingExpressTxStatusRoutable

extension TangemPayMainCoordinator: PendingExpressTxStatusRoutable {
    func openURL(_ url: URL) {
        safariManager.openURL(url)
    }

    func openRefundCurrency(walletModel: any WalletModel, userWalletModel: any UserWalletModel) {
        pendingExpressTxStatusBottomSheet = nil
        dismiss(with: .init(userWalletId: walletModel.userWalletId, tokenItem: walletModel.tokenItem))
    }

    func dismissPendingTxSheet() {
        pendingExpressTxStatusBottomSheet = nil
    }
}

// MARK: - TangemPayPinCheckRoutable

extension TangemPayMainCoordinator: TangemPayPinCheckRoutable {
    func closePinCheck() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}
