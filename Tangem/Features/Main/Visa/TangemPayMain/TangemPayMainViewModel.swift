//
//  TangemPayMainViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import PassKit
import TangemUI
import TangemSdk
import TangemVisa
import TangemUIUtils
import TangemFoundation
import TangemLocalization
import TangemPay

final class TangemPayMainViewModel: ObservableObject {
    let tangemPayCardDetailsViewModel: TangemPayCardDetailsViewModel
    lazy var refreshScrollViewStateObject = RefreshScrollViewStateObject { [weak self] in
        guard let self else { return }

        async let balanceUpdate: Void = tangemPayAccount.loadBalance()
        async let transactionsUpdate: Void = transactionHistoryService.reloadHistory()

        _ = await (balanceUpdate, transactionsUpdate)
    }

    lazy var contactSupportNotificationInput = NotificationViewInput(
        style: .withButtons([.init(
            action: { [weak self] _, _ in
                self?.contactSupport()
            },
            actionType: .support,
            isWithLoader: false
        )]),
        severity: .critical,
        settings: .init(event: TangemPayNotificationEvent.tangemPayIsNowBeta, dismissAction: nil)
    )

    @Published private(set) var balance: LoadableTokenBalanceView.State
    @Published private(set) var tangemPayTransactionHistoryState: TransactionsListView.State = .loading
    @Published private(set) var freezingState: TangemPayFreezingState = .normal
    @Published private(set) var pendingExpressTransactions: [PendingExpressTransactionView.Info] = []
    @Published private(set) var shouldDisplayAddToApplePayGuide: Bool = false
    @Published private(set) var isWithdrawButtonLoading: Bool = false
    @Published var alert: AlertBinder?

    private let userWalletInfo: UserWalletInfo
    private let tangemPayAccount: TangemPayAccount
    private weak var coordinator: TangemPayMainRoutable?

    @Injected(\.mailComposePresenter) private var mailPresenter: MailComposePresenter

    private let transactionHistoryService: TangemPayTransactionHistoryService
    private let pendingExpressTransactionsManager: PendingExpressTransactionsManager
    private let cardDetailsRepository: TangemPayCardDetailsRepository

    private var nextViewOpeningTask: Task<Void, Error>?
    private var bag = Set<AnyCancellable>()

    init(
        userWalletInfo: UserWalletInfo,
        tangemPayAccount: TangemPayAccount,
        coordinator: TangemPayMainRoutable
    ) {
        self.userWalletInfo = userWalletInfo
        self.tangemPayAccount = tangemPayAccount
        self.coordinator = coordinator

        cardDetailsRepository = .init(
            lastFourDigits: tangemPayAccount.card?.cardNumberEnd ?? "",
            customerService: tangemPayAccount.customerService
        )

        balance = tangemPayAccount.mainHeaderBalanceProvider.balance

        transactionHistoryService = TangemPayTransactionHistoryService(
            apiService: tangemPayAccount.customerService
        )

        pendingExpressTransactionsManager = ExpressPendingTransactionsFactory(
            userWalletInfo: userWalletInfo,
            tokenItem: TangemPayUtilities.usdcTokenItem,
            // We don't handle update after transaction is done here yet.
            walletModelUpdater: nil
        )
        .makePendingExpressTransactionsManager()

        tangemPayCardDetailsViewModel = TangemPayCardDetailsViewModel(
            repository: cardDetailsRepository
        )

        bind()
        reloadHistory()
    }

    func reloadHistory() {
        runTask { [self] in
            await transactionHistoryService.reloadHistory()
        }
    }

    @MainActor
    func fetchNextTransactionHistoryPage() -> FetchMore? {
        transactionHistoryService.fetchNextTransactionHistoryPage()
    }

    func addFunds() {
        Analytics.log(.visaScreenButtonVisaAddFunds)

        nextViewOpeningTask?.cancel()
        nextViewOpeningTask = Task { @MainActor in
            guard let depositAddress = tangemPayAccount.depositAddress,
                  let tangemPayWalletWrapper = makeExpressInteractorTangemPayWalletWrapper() else {
                coordinator?.openTangemPayNoDepositAddressSheet()
                return
            }

            coordinator?.openTangemPayAddFundsSheet(
                input: .init(
                    userWalletInfo: userWalletInfo,
                    address: depositAddress,
                    tangemPayWalletWrapper: tangemPayWalletWrapper
                )
            )
        }
    }

    func onPin() {
        Analytics.log(.visaScreenPinCodeClicked)
        guard tangemPayAccount.card?.isPinSet == true else {
            setPin()
            return
        }

        runTask(in: self) { viewModel in
            do {
                _ = try await BiometricsUtil.requestAccess(
                    localizedReason: Localization.biometryTouchIdReason
                )
                viewModel.checkPin()
            } catch {
                VisaLogger.error("Failed to receive biometry for PIN", error: error)
                return
            }
        }
    }

    func withdraw() {
        Analytics.log(.visaScreenWithdrawClicked)
        guard let tangemPayWalletWrapper = makeExpressInteractorTangemPayWalletWrapper() else {
            coordinator?.openTangemPayNoDepositAddressSheet()
            return
        }

        nextViewOpeningTask?.cancel()
        nextViewOpeningTask = runWithDelayedLoading(onLongRunning: { @MainActor [weak self] in
            self?.isWithdrawButtonLoading = true
        }, onCancel: { [weak self] in
            self?.isWithdrawButtonLoading = false
        }) { @MainActor [weak self] in
            do {
                try await self?.openWithdraw(tangemPayWalletWrapper: tangemPayWalletWrapper)
            } catch is CancellationError {
                // Do nothing
            } catch {
                self?.alert = error.alertBinder
            }

            self?.isWithdrawButtonLoading = false
        }
    }

    func onAppear() {
        Analytics.log(.visaScreenVisaMainScreenOpened)

        runTask { [tangemPayAccount] in
            await tangemPayAccount.loadBalance()
        }
    }

    func onDisappear() {
        runTask { [tangemPayAccount] in
            await tangemPayAccount.loadCustomerInfo()
        }
    }

    func openAddToApplePayGuide() {
        Analytics.log(.visaScreenAddToWalletClicked)
        coordinator?.openAddToApplePayGuide(
            viewModel: .init(repository: cardDetailsRepository)
        )
    }

    func dismissAddToApplePayGuideBanner() {
        AppSettings.shared.tangemPayShowAddToApplePayGuide = false
    }

    func showFreezePopup() {
        Analytics.log(.visaScreenFreezeCardClicked)
        coordinator?.openTangemPayFreezeSheet { [weak self] in
            self?.freeze()
        }
    }

    func unfreeze() {
        Analytics.log(.visaScreenUnfreezeCardClicked)
        freezingState = .unfreezingInProgress
        tangemPayCardDetailsViewModel.state = .loading(isFrozen: tangemPayCardDetailsViewModel.state.isFrozen)

        Task { @MainActor in
            do {
                try await tangemPayAccount.unfreeze()
            } catch {
                freezingState = .frozen
                showFreezeUnfreezeErrorToast(freeze: false)
            }
        }
    }

    func setPin() {
        coordinator?.openTangemPaySetPin(tangemPayAccount: tangemPayAccount)
    }

    func checkPin() {
        coordinator?.openTangemPayCheckPin(tangemPayAccount: tangemPayAccount)
    }

    func termsAndLimits() {
        Analytics.log(.visaScreenTermsAndLimitsClicked)
        coordinator?.openTermsAndLimits()
    }

    func contactSupport() {
        Analytics.log(.visaScreenGoToSupportOnBetaBannerClicked)
        let dataCollector = TangemPaySupportDataCollector(
            source: .permanentBanner,
            userWalletId: userWalletInfo.id.stringValue,
            customerId: tangemPayAccount.customerId
        )
        let logsComposer = LogsComposer(infoProvider: dataCollector, includeZipLogs: false)
        let mailViewModel = MailViewModel(
            logsComposer: logsComposer,
            recipient: EmailConfig.visaDefault(subject: .default).recipient,
            emailType: .visaFeedback(subject: .default)
        )

        Task { @MainActor in
            mailPresenter.present(viewModel: mailViewModel)
        }
    }

    private func freeze() {
        freezingState = .freezingInProgress
        tangemPayCardDetailsViewModel.state = .loading(isFrozen: tangemPayCardDetailsViewModel.state.isFrozen)

        Task { @MainActor in
            do {
                try await tangemPayAccount.freeze()
            } catch {
                freezingState = .normal
                showFreezeUnfreezeErrorToast(freeze: true)
            }
        }
    }

    private func showFreezeUnfreezeErrorToast(freeze: Bool) {
        let message = freeze
            ? Localization.tangemPayFreezeCardFailed
            : Localization.tangemPayUnfreezeCardFailed

        Toast(view: WarningToast(text: message))
            .present(
                layout: .top(padding: 20),
                type: .temporary()
            )
    }

    @MainActor
    func openTransactionDetails(id: String) {
        guard let transaction = transactionHistoryService.getTransaction(id: id) else {
            assertionFailure("Transaction not found")
            return
        }
        Analytics.log(
            event: .visaScreenTransactionInListClicked,
            params: [
                .status: transaction.record.analyticsStatus,
                .type: transaction.transactionType.rawValue,
            ]
        )
        coordinator?.openTangemPayTransactionDetailsSheet(
            transaction: transaction,
            userWalletId: userWalletInfo.id.stringValue,
            customerId: tangemPayAccount.customerId
        )
    }

    func onToolbarClicked() {
        Analytics.log(.visaScreenCardSettingsClicked)
    }
}

// MARK: - Private

private extension TangemPayMainViewModel {
    func bind() {
        tangemPayAccount.mainHeaderBalanceProvider
            .balancePublisher
            .receiveOnMain()
            .assign(to: \.balance, on: self, ownership: .weak)
            .store(in: &bag)

        transactionHistoryService
            .tangemPayTransactionHistoryState
            .receiveOnMain()
            .assign(to: &$tangemPayTransactionHistoryState)

        Publishers.CombineLatest(
            AppSettings.shared.$tangemPayShowAddToApplePayGuide,
            tangemPayAccount.statusPublisher
        )
        .map { tangemPayShowAddToApplePayGuide, status in
            PKPaymentAuthorizationViewController.canMakePayments()
                && status == .active
                && tangemPayShowAddToApplePayGuide
        }
        .receiveOnMain()
        .assign(to: \.shouldDisplayAddToApplePayGuide, on: self, ownership: .weak)
        .store(in: &bag)

        tangemPayAccount.statusPublisher
            .map { $0 == .blocked ? .frozen : .normal }
            .receiveOnMain()
            .assign(to: \.freezingState, on: self, ownership: .weak)
            .store(in: &bag)

        $freezingState
            .map(\.cardDetailsState)
            .receiveOnMain()
            .assign(to: \.state, on: tangemPayCardDetailsViewModel, ownership: .weak)
            .store(in: &bag)

        pendingExpressTransactionsManager
            .pendingTransactionsPublisher
            .map { [weak self] transactions in
                PendingExpressTransactionsConverter()
                    .convertToTokenDetailsPendingTxInfo(transactions) { [weak self] id in
                        self?.didTapPendingExpressTransaction(id: id)
                    }
            }
            .receiveOnMain()
            .assign(to: &$pendingExpressTransactions)
    }

    func makeExpressInteractorTangemPayWalletWrapper() -> ExpressInteractorTangemPayWalletWrapper? {
        guard let depositAddress = tangemPayAccount.depositAddress else {
            return nil
        }

        let tangemPayWalletWrapper = ExpressInteractorTangemPayWalletWrapper(
            tokenItem: TangemPayUtilities.usdcTokenItem,
            feeTokenItem: TangemPayUtilities.usdcTokenItem,
            defaultAddressString: depositAddress,
            availableBalanceProvider: tangemPayAccount.balancesProvider.availableBalanceProvider,
            cexTransactionProcessor: tangemPayAccount.expressCEXTransactionProcessor,
            transactionValidator: TangemPayExpressTransactionValidator(
                availableBalanceProvider: tangemPayAccount.balancesProvider.availableBalanceProvider,
            )
        )

        return tangemPayWalletWrapper
    }
}

// MARK: - Navigation

private extension TangemPayMainViewModel {
    @MainActor
    func openWithdraw(tangemPayWalletWrapper: ExpressInteractorTangemPayWalletWrapper) async throws {
        let restriction = try await tangemPayAccount.withdrawAvailabilityProvider.restriction()

        switch restriction {
        case .none, .zeroWalletBalance:
            coordinator?.openTangemPayWithdraw(input: ExpressDependenciesInput(
                userWalletInfo: userWalletInfo,
                source: tangemPayWalletWrapper,
                destination: .loadingAndSet
            ))
        case .hasPendingWithdrawOrder:
            coordinator?.openTangemWithdrawInProgressSheet()
        default:
            alert = TokenActionAvailabilityAlertBuilder().alert(for: restriction)
        }
    }

    func didTapPendingExpressTransaction(id: String) {
        let transactions = pendingExpressTransactionsManager.pendingTransactions
        guard let transaction = transactions.first(where: { $0.expressTransactionId == id }) else {
            return
        }

        let tokenItem = TangemPayUtilities.usdcTokenItem

        coordinator?.openPendingExpressTransactionDetails(
            pendingTransaction: transaction,
            userWalletInfo: userWalletInfo,
            tokenItem: tokenItem,
            pendingTransactionsManager: pendingExpressTransactionsManager
        )
    }
}

// MARK: - TangemPayFreezingState+TangemPayCardDetailsState

private extension TangemPayFreezingState {
    var cardDetailsState: TangemPayCardDetailsState {
        switch self {
        case .normal:
            .hidden(isFrozen: false)
        case .freezingInProgress:
            .loading(isFrozen: false)
        case .frozen:
            .hidden(isFrozen: true)
        case .unfreezingInProgress:
            .loading(isFrozen: true)
        }
    }
}

// MARK: - Private util

private extension TangemPayTransactionHistoryResponse.Record {
    var analyticsStatus: String {
        switch self {
        case .spend(let spend):
            return spend.status.rawValue
        case .collateral, .payment, .fee:
            return "unknown"
        }
    }
}
