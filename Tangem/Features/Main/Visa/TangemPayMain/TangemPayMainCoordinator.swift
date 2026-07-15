//
//  TangemPayMainCoordinator.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Foundation
import Combine
import UIKit
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
    @Published var currentPlanCoordinator: TangemPayCurrentPlanCoordinator?

    // MARK: - Child view models (sheets)

    @Published var addToApplePayGuideViewModel: TangemPayAddToAppPayGuideViewModel?
    @Published var tangemPayPinViewModel: TangemPayPinViewModel?
    @Published var tangemPayDailyLimitViewModel: TangemPayDailyLimitViewModel?
    @Published var termsAndLimitsViewModel: WebViewContainerViewModel?
    @Published var pendingExpressTxStatusBottomSheet: PendingExpressTxStatusBottomSheetViewModel?
    @Published var virtualAccountSuccessViewModel: TangemPayVirtualAccountSuccessViewModel?

    private var options: Options?

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
            // Swap redirect is unreachable here: TangemPay opens only `.swap`-type flows,
            // and the receive-token list exists only in the Send-with-Swap flow.
            case .none, .closeButtonTap, .openSwap:
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
        guard
            let userWalletModel = options?.userWalletModel,
            let tangemPayAccountModel = userWalletModel.accountModelsManager.tangemPayAccountModel
        else {
            return
        }

        tangemPayAccountModel.renewSession(
            authorizingInteractor: userWalletModel.tangemPayAuthorizingInteractor,
            completion: {}
        )
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

    func openCardManagement(entry: TangemPayCardEntry) {
        guard let options else {
            assertionFailure("TangemPayMainCoordinator.Options not found")
            return
        }

        cardManagementViewModel = TangemPayCardManagementViewModel(
            userWalletInfo: options.userWalletInfo,
            tangemPayAccount: options.tangemPayAccount,
            initialEntry: entry,
            coordinator: self
        )
    }

    func openCurrentPlan() {
        guard
            let tangemPayAccount = options?.tangemPayAccount,
            let customerTariffPlan = tangemPayAccount.customerTariffPlan
        else {
            return
        }

        let coordinator = TangemPayCurrentPlanCoordinator(
            dismissAction: { [weak self] in
                self?.currentPlanCoordinator = nil
            },
            popToRootAction: popToRootAction
        )
        coordinator.start(with: .init(
            customerTariffPlan: customerTariffPlan,
            customerService: tangemPayAccount.customerService,
            closeFlow: { [weak self] in
                self?.currentPlanCoordinator = nil
                self?.dismiss(with: nil)
            }
        ))
        currentPlanCoordinator = coordinator
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
        Task { @MainActor in
            let viewModel = TangemPayIssueAdditionalCardCostPopupViewModel(
                offer: offer,
                fee: fee,
                userWalletId: options.userWalletInfo.id,
                tangemPayAccount: options.tangemPayAccount,
                issueCard: issueCard,
                coordinator: self
            )
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
        customerId: String,
        cardName: String?,
        cardNumberEnd: String?
    ) {
        let viewModel = TangemPayTransactionDetailsViewModel(
            transaction: transaction,
            userWalletId: userWalletId,
            customerId: customerId,
            cardName: cardName,
            cardNumberEnd: cardNumberEnd,
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

// MARK: - TangemPayUnfreezeSheetRoutable

extension TangemPayMainCoordinator: TangemPayUnfreezeSheetRoutable {
    func closeUnfreezeSheet() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}

// MARK: - TangemPayCloseCardSheetRoutable

extension TangemPayMainCoordinator: TangemPayCloseCardSheetRoutable {
    func closeCloseCardSheet() {
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

    func addFundsSheetRequestBankTransfer() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()

            // Give some time to hide sheet with animation
            try? await Task.sleep(for: .seconds(0.2))
            routeVirtualAccountEntry()
        }
    }

    func closeAddFundsSheet() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}

// MARK: - Virtual Account

private extension TangemPayMainCoordinator {
    func routeVirtualAccountEntry() {
        guard let tangemPayAccount = options?.tangemPayAccount else { return }

        switch tangemPayAccount.virtualAccountEntry {
        case .none:
            openVirtualAccountInfoSheet()
        case .preparing:
            openVirtualAccountPreparingPopup()
        case .active(let productInstanceId):
            loadVirtualAccountBankDetails(productInstanceId: productInstanceId)
        }
    }

    func openVirtualAccountInfoSheet() {
        guard let tangemPayAccount = options?.tangemPayAccount else { return }

        Task { @MainActor in
            let viewModel = TangemPayVirtualAccountInfoSheetViewModel(
                tangemPayAccount: tangemPayAccount,
                coordinator: self
            )
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openVirtualAccountPreparingPopup() {
        Task { @MainActor in
            let viewModel = TangemPayVirtualAccountPreparingPopupViewModel(
                onClose: { [weak self] in
                    Task { @MainActor in
                        self?.floatingSheetPresenter.removeActiveSheet()
                    }
                }
            )
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func loadVirtualAccountBankDetails(productInstanceId: String) {
        guard let tangemPayAccount = options?.tangemPayAccount else { return }

        Task { @MainActor in
            do {
                let credentials = try await tangemPayAccount.loadBankCredentials(productInstanceId: productInstanceId)
                let viewModel = TangemPayVirtualAccountBankDetailsViewModel(
                    credentials: credentials,
                    onClose: { [weak self] in
                        Task { @MainActor in
                            self?.floatingSheetPresenter.removeActiveSheet()
                        }
                    }
                )
                floatingSheetPresenter.enqueue(sheet: viewModel)
            } catch {
                VisaLogger.error("Failed to load virtual account bank credentials", error: error)
                openVirtualAccountBankDetailsErrorPopup(productInstanceId: productInstanceId)
            }
        }
    }

    func openVirtualAccountBankDetailsErrorPopup(productInstanceId: String) {
        Task { @MainActor in
            let viewModel = TangemPayVirtualAccountBankDetailsErrorPopupViewModel(
                onRetry: { [weak self] in
                    Task { @MainActor in
                        self?.floatingSheetPresenter.removeActiveSheet()
                        try? await Task.sleep(for: .seconds(0.2))
                        self?.loadVirtualAccountBankDetails(productInstanceId: productInstanceId)
                    }
                },
                onContactSupport: { [weak self] in
                    Task { @MainActor in
                        self?.floatingSheetPresenter.removeActiveSheet()
                        self?.rootViewModel?.contactSupport()
                    }
                },
                onClose: { [weak self] in
                    Task { @MainActor in
                        self?.floatingSheetPresenter.removeActiveSheet()
                    }
                }
            )
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }
}

// MARK: - TangemPayVirtualAccountInfoSheetRoutable

extension TangemPayMainCoordinator: TangemPayVirtualAccountInfoSheetRoutable {
    func virtualAccountInfoSheetDidCreateOrder() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
            try? await Task.sleep(for: .seconds(0.2))
            virtualAccountSuccessViewModel = TangemPayVirtualAccountSuccessViewModel(
                onClose: { [weak self] in
                    self?.virtualAccountSuccessViewModel = nil
                }
            )
        }
    }

    func closeVirtualAccountInfoSheet() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }

    func openVirtualAccountURL(_ url: URL) {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
            safariManager.openURL(url)
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
        let logsComposer = LogsComposer(infoProvider: dataCollector, includeSystemLogs: false)
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

    func openTangemPaySetPin(card: TangemPayCard) {
        guard let options else { return }
        tangemPayPinViewModel = TangemPayPinViewModel(
            card: card,
            tangemPayAccount: options.tangemPayAccount,
            userWalletId: options.userWalletInfo.id,
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

    func openTangemPayCheckPin(card: TangemPayCard) {
        guard let options else { return }
        let viewModel = TangemPayPinCheckViewModel(
            card: card,
            userWalletId: options.userWalletInfo.id,
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

    func openTangemPayUnfreezeSheet(userWalletId: UserWalletId, unfreezeAction: @escaping () -> Void) {
        Task { @MainActor in
            let viewModel = TangemPayUnfreezeSheetViewModel(
                userWalletId: userWalletId,
                coordinator: self,
                unfreezeAction: unfreezeAction
            )
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openTangemPayBiometryNotSetSheet() {
        Task { @MainActor in
            let viewModel = TangemPayBiometryNotSetPopupViewModel(
                onSetBiometry: { [weak self] in
                    self?.floatingSheetPresenter.removeActiveSheet()
                    UIApplication.openSystemSettings()
                },
                onClose: { [weak self] in
                    self?.floatingSheetPresenter.removeActiveSheet()
                }
            )
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func openChangeDailyLimit(tangemPayAccount: TangemPayAccount) {
        tangemPayDailyLimitViewModel = TangemPayDailyLimitViewModel(tangemPayAccount: tangemPayAccount, coordinator: self)
    }

    func openChangeDailyLimit(card: TangemPayCard) {
        guard let options else { return }
        tangemPayDailyLimitViewModel = TangemPayDailyLimitViewModel(
            card: card,
            userWalletId: options.userWalletInfo.id,
            coordinator: self
        )
    }

    func openTangemPayReissueSheet(
        userWalletId: UserWalletId,
        tangemPayAccount: TangemPayAccount,
        onLoadingChange: @escaping (Bool) -> Void,
        onError: @escaping () -> Void
    ) {
        Task { @MainActor in
            onLoadingChange(true)
            defer { onLoadingChange(false) }
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
                let balanceText = Self.formatFee(amount: balance.fiat.availableBalance, currency: feeResponse.currency)
                let isInsufficientFunds = balance.fiat.availableBalance < feeResponse.amount

                let viewModel = TangemPayReissueSheetViewModel(
                    userWalletId: userWalletId,
                    tangemPayAccount: tangemPayAccount,
                    feeText: feeText,
                    balanceText: balanceText,
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

    func openTangemPayReissueSheet(
        userWalletId: UserWalletId,
        card: TangemPayCard,
        onLoadingChange: @escaping (Bool) -> Void,
        onError: @escaping () -> Void
    ) {
        guard let options else { return }
        Task { @MainActor in
            onLoadingChange(true)
            defer { onLoadingChange(false) }
            do {
                let feeResponse: TangemPayFeeResponse
                if let cached = await options.tangemPayAccount.feeRepository.getFee(for: .cardReplacement) {
                    feeResponse = cached
                } else {
                    feeResponse = try await card.customerService.getFee(type: .cardReplacement)
                    await options.tangemPayAccount.feeRepository.setFee(feeResponse, for: .cardReplacement)
                }
                let balance = try await card.customerService.getBalance()

                let feeText = Self.formatFee(amount: feeResponse.amount, currency: feeResponse.currency)
                let balanceText = Self.formatFee(amount: balance.fiat.availableBalance, currency: feeResponse.currency)
                let isInsufficientFunds = balance.fiat.availableBalance < feeResponse.amount

                let viewModel = TangemPayReissueSheetViewModel(
                    userWalletId: userWalletId,
                    card: card,
                    feeText: feeText,
                    balanceText: balanceText,
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

    func openTangemPayCloseCardSheet(
        userWalletId: UserWalletId,
        card: TangemPayCard,
        onError: @escaping () -> Void
    ) {
        Task { @MainActor in
            let viewModel = TangemPayCloseCardSheetViewModel(
                userWalletId: userWalletId,
                coordinator: self,
                closeAction: { try await card.close() },
                onError: onError
            )
            floatingSheetPresenter.enqueue(sheet: viewModel)
        }
    }

    func popToCardListScreen() {
        cardManagementViewModel = nil
    }

    private static func formatFee(amount: Decimal, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_US")
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
            rootViewModel?.showCardIssueFailureAlert()
        }
    }

    func issueCostPopupDidCancel() {
        Task { @MainActor in
            floatingSheetPresenter.removeActiveSheet()
        }
    }
}
