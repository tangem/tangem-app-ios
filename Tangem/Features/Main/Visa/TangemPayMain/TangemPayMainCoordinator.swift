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
import TangemPay
import TangemVisa

class TangemPayMainCoordinator: CoordinatorObject {
    let dismissAction: Action<DismissOptions?>
    let popToRootAction: Action<PopToRootOptions>

    @Injected(\.floatingSheetPresenter) private var floatingSheetPresenter: any FloatingSheetPresenter
    @Injected(\.mailComposePresenter) private var mailPresenter: MailComposePresenter
    @Injected(\.safariManager) private var safariManager: SafariManager
    @Injected(\.tangemPayAssembly) private var tangemPayAssembly: TangemPayAssembly

    // MARK: - Root view model

    @Published private(set) var rootViewModel: TangemPayMainViewModel?

    // MARK: - Child coordinators

    @Published var sendCoordinator: SendCoordinator?

    // MARK: - Child view models (push navigation)

    @Published var cardManagementViewModel: TangemPayCardManagementViewModel?

    // MARK: - Child view models (sheets)

    @Published var addToApplePayGuideViewModel: TangemPayAddToAppPayGuideViewModel?
    @Published var tangemPayPinViewModel: TangemPayPinViewModel?
    @Published var tangemPayDailyLimitViewModel: TangemPayDailyLimitViewModel?
    @Published var termsAndLimitsViewModel: WebViewContainerViewModel?
    @Published var pendingExpressTxStatusBottomSheet: PendingExpressTxStatusBottomSheetViewModel?

    private var options: Options?
    private var tokenEntriesDerivator: TokenEntriesDerivator?

    required init(
        dismissAction: @escaping Action<DismissOptions?>,
        popToRootAction: @escaping Action<PopToRootOptions>
    ) {
        self.dismissAction = dismissAction
        self.popToRootAction = popToRootAction
    }

    func start(with options: Options) {
        self.options = options
        rootViewModel = TangemPayMainViewModel(
            userWalletInfo: options.userWalletInfo,
            tangemPayAccount: options.tangemPayAccount,
            cardDetailsRepository: tangemPayAssembly.makeCardDetailsRepository(for: options.tangemPayAccount),
            coordinator: self
        )
    }
}

// MARK: - Options

extension TangemPayMainCoordinator {
    struct Options {
        let userWalletInfo: UserWalletInfo
        let tangemPayAccount: TangemPayAccount
        let userWalletModel: any UserWalletModel
    }

    typealias DismissOptions = FeeCurrencyNavigatingDismissOption
}

// MARK: - Private

extension TangemPayMainCoordinator {
    func openSwap(parameters: PredefinedSwapParameters) {
        let dismissAction: Action<SendCoordinator.DismissOptions?> = { [weak self] options in
            self?.sendCoordinator = nil

            switch options {
            case .none, .closeButtonTap:
                break
            case .openFeeCurrency(let feeCurrency):
                self?.dismiss(with: feeCurrency)
            }
        }

        let coordinator = SendCoordinator(
            dismissAction: dismissAction,
            popToRootAction: popToRootAction
        )

        coordinator.start(with: .init(type: .swap(parameters), source: .main))
        sendCoordinator = coordinator
    }
}

// MARK: - TangemPayMainRoutable

extension TangemPayMainCoordinator: TangemPayMainRoutable {
    func renewTangemPaySession() {
        guard let userWalletModel = options?.userWalletModel else { return }

        tokenEntriesDerivator = TokenEntriesDerivator(
            userWalletModel: userWalletModel,
            onStart: {},
            onFinish: { [weak self] in
                self?.tokenEntriesDerivator = nil
            }
        )
        tokenEntriesDerivator?.derive()
    }

    func openCardManagement() {
        guard let options else {
            assertionFailure("TangemPayMainCoordinator.Options not found")
            return
        }

        cardManagementViewModel = TangemPayCardManagementViewModel(
            userWalletInfo: options.userWalletInfo,
            tangemPayAccount: options.tangemPayAccount,
            cardDetailsRepository: tangemPayAssembly.makeCardDetailsRepository(for: options.tangemPayAccount),
            coordinator: self
        )
    }

    func openFakedoorSheet() {
        guard let options else {
            assertionFailure("TangemPayMainCoordinator.Options not found")
            return
        }

        Task { @MainActor in
            let viewModel = TangemPayFakedoorSheetViewModel(
                userWalletId: options.userWalletInfo.id,
                coordinator: self
            )
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openMaximumCardsIssuedSheet() {
        let viewModel = TangemPayMaximumCardsIssuedSheetViewModel(
            onClose: { [weak self] in
                Task { @MainActor in
                    self?.floatingSheetPresenter.removeActiveSheet()
                }
            }
        )
        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openIssueAdditionalCardCostPopup(
        offer: TangemPayCustomerOffer,
        fee: TangemPayCustomerOffer.Fee,
        issueCard: @escaping () async throws -> Void
    ) {
        guard let options else { return }
        let viewModel = TangemPayIssueAdditionalCardCostPopupViewModel(
            offer: offer,
            fee: fee,
            userWalletId: options.userWalletInfo.id,
            tangemPayAccount: options.tangemPayAccount,
            issueCard: issueCard,
            coordinator: self
        )
        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openAddToApplePayGuide(viewModel: TangemPayCardDetailsViewModel) {
        addToApplePayGuideViewModel = TangemPayAddToAppPayGuideViewModel(
            tangemPayCardDetailsViewModel: viewModel,
            coordinator: self
        )
    }

    func openTangemPayAddFundsSheet(input: TangemPayAddFundsSheetViewModel.Input) {
        let viewModel = TangemPayAddFundsSheetViewModel(input: input, coordinator: self)
        Task { @MainActor in
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openTangemPayWithdraw(input: PredefinedSwapParameters) {
        Task { @MainActor in
            let viewModel = TangemPayWithdrawNoteSheetViewModel(coordinator: self) { [weak self] in
                Task { @MainActor in
                    self?.floatingSheetPresenter.removeActiveSheet()
                    try? await Task.sleep(for: .seconds(0.2))
                    self?.openSwap(parameters: input)
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

    func openTangemPayTransactionDetailsSheet(
        transaction: TangemPayTransactionRecord,
        userWalletId: UserWalletId,
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

    func addFundsSheetRequestSwap(input: PredefinedSwapParameters) {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()

            // Give some time to hide sheet with animation
            try? await Task.sleep(for: .seconds(0.2))
            openSwap(parameters: input)
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

// MARK: - TangemPayFakedoorSheetRoutable

extension TangemPayMainCoordinator: TangemPayFakedoorSheetRoutable {
    func closeFakedoorSheet() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}

// MARK: - TangemPayCardManagementRoutable

extension TangemPayMainCoordinator: TangemPayCardManagementRoutable {
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

    func openTangemPayFreezeSheet(userWalletId: UserWalletId, freezeAction: @escaping () -> Void) {
        Task { @MainActor in
            let viewModel = TangemPayFreezeSheetViewModel(
                userWalletId: userWalletId,
                coordinator: self,
                freezeAction: freezeAction
            )
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openChangeDailyLimit(tangemPayAccount: TangemPayAccount) {
        tangemPayDailyLimitViewModel = TangemPayDailyLimitViewModel(tangemPayAccount: tangemPayAccount, coordinator: self)
    }

    func openTangemPayReissueSheet(
        userWalletId: UserWalletId,
        tangemPayAccount: TangemPayAccount,
        onError: @escaping () -> Void
    ) {
        Task { @MainActor in
            do {
                let feeResponse: TangemPayFeeResponse
                if let cached = await tangemPayAccount.feeRepository.getFee(for: .cardReplacement) {
                    feeResponse = cached
                } else {
                    feeResponse = try await tangemPayAccount.customerService.getFee(type: .cardReplacement)
                    await tangemPayAccount.feeRepository.setFee(feeResponse, for: .cardReplacement)
                }
                let balance = try await tangemPayAccount.customerService.getBalance()

                let feeText = Self.formatFee(amount: feeResponse.amount, currency: feeResponse.currency)
                let isInsufficientFunds = balance.fiat.availableBalance < feeResponse.amount

                let viewModel = TangemPayReissueSheetViewModel(
                    userWalletId: userWalletId,
                    tangemPayAccount: tangemPayAccount,
                    feeText: feeText,
                    isInsufficientFunds: isInsufficientFunds,
                    coordinator: self,
                    onError: onError
                )
                floatingSheetPresenter.enqueue(sheet: viewModel)
            } catch {
                VisaLogger.error("Failed to load reissue fee", error: error)
                onError()
            }
        }
    }

    private static func formatFee(amount: Decimal, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(amount) \(currency)"
    }
}

// MARK: - TangemPayReissueSheetRoutable

extension TangemPayMainCoordinator: TangemPayReissueSheetRoutable {
    func closeReissueSheet() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }

    func openAddFundsFromReissueSheet() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
            try? await Task.sleep(for: .seconds(0.2))
            rootViewModel?.addFunds()
        }
    }
}

// MARK: - TangemPayDailyLimitRoutable

extension TangemPayMainCoordinator: TangemPayDailyLimitRoutable {
    func closeTangemPayDailyLimit() {
        tangemPayDailyLimitViewModel = nil
    }
}

// MARK: - TangemPayIssueAdditionalCardCostPopupRoutable

extension TangemPayMainCoordinator: TangemPayIssueAdditionalCardCostPopupRoutable {
    func issueCostPopupDidConfirm() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }

    func issueCostPopupDidRequestAddFunds() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
            try? await Task.sleep(for: .seconds(0.2))
            rootViewModel?.addFunds()
        }
    }

    func issueCostPopupDidFail(error: Error) {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
            try? await Task.sleep(for: .seconds(0.2))
            rootViewModel?.alert = error.alertBinder
        }
    }

    func issueCostPopupDidCancel() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}
