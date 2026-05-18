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
import TangemUIUtils
import TangemFoundation
import TangemLocalization
import TangemPay
import TangemVisa

final class TangemPayMainViewModel: ObservableObject {
    lazy var refreshScrollViewStateObject = RefreshScrollViewStateObject { [weak self] in
        guard let self else { return }

        if !isDeactivated {
            async let transactionsUpdate: Void = transactionHistoryService.reloadHistory()
            async let customerInfoUpdate: Void = tangemPayAccount.loadCustomerInfo()
            async let offersUpdate: Void = tangemPayAccount.loadOffers()
            async let resumePolling: Void = tangemPayAccount.resumeAdditionalCardIssuePolling()
            _ = await (transactionsUpdate, customerInfoUpdate, offersUpdate, resumePolling)
        } else {
            await tangemPayAccount.loadBalance()
        }
    }

    @Published private(set) var balance: LoadableBalanceView.State
    @Published private(set) var tangemPayTransactionHistoryState: TransactionsListView.State = .loading
    @Published private(set) var pendingExpressTransactions: [PendingExpressTransactionView.Info] = []
    @Published private(set) var isWithdrawButtonLoading: Bool = false
    @Published private(set) var inlineNotifications: [NotificationViewInput] = []

    @Published private(set) var cardEntries: [TangemPayCardEntry] = []
    @Published private(set) var additionalCardIssueOffer: TangemPayCustomerOffer?
    @Published private(set) var shouldDisplayAddToApplePayGuide: Bool = false
    /// Mirrors `tangemPayAccount.anyCardReissuingPublisher`. The view doesn't read this
    /// directly — it's published purely so `card.isReissuing` (a sync getter) is re-read
    /// during the in-flight reissue window. Without this, the `.replacing` small-card
    /// state would only appear after the next `loadCustomerInfo` (i.e. on reissue
    /// completion), losing the visual feedback during the operation itself.
    @Published private(set) var isAnyCardReissuing: Bool = false

    let cardDeactivatedNotificationInput: NotificationViewInput?
    @Published var alert: AlertBinder?

    var isStale: Bool {
        !inlineNotifications.isEmpty
    }

    var isDeactivated: Bool {
        tangemPayAccount.isDeactivated
    }

    var hasIssuingEntry: Bool {
        cardEntries.contains { $0.isIssuing }
    }

    @Injected(\.mailComposePresenter) private var mailPresenter: MailComposePresenter
    @Injected(\.tangemPayAssembly) private var tangemPayAssembly: TangemPayAssembly

    private let userWalletInfo: UserWalletInfo
    private let tangemPayAccount: TangemPayAccount
    private weak var coordinator: TangemPayMainRoutable?

    private let transactionHistoryService: TangemPayTransactionHistoryService
    private let pendingExpressTransactionsManager: PendingExpressTransactionsManager

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

        cardDeactivatedNotificationInput = tangemPayAccount.isDeactivated
            ? NotificationsFactory().buildNotificationInput(for: TangemPayCardDeactivatedNotificationEvent())
            : nil

        balance = tangemPayAccount.mainHeaderBalanceProvider.balance

        transactionHistoryService = TangemPayTransactionHistoryService(
            apiService: tangemPayAccount.customerService,
            tangemPayAccount: tangemPayAccount,
            cacheStorage: AppSettings.shared,
            customerWalletId: userWalletInfo.id.stringValue
        )

        pendingExpressTransactionsManager = ExpressPendingTransactionsFactory(
            userWalletInfo: userWalletInfo,
            tokenItem: TangemPayUtilities.usdcTokenItem,
            // We don't handle update after transaction is done here yet.
            walletModelUpdater: nil
        )
        .makePendingExpressTransactionsManager()

        bind()
        if !isDeactivated {
            reloadHistory()
        }
    }

    func reloadHistory() {
        guard !isDeactivated else { return }

        runTask { [self] in
            await transactionHistoryService.reloadHistory()
        }
    }

    func renewSession() {
        coordinator?.renewTangemPaySession()
    }

    @MainActor
    func fetchNextTransactionHistoryPage() -> FetchMore? {
        guard !isDeactivated else { return nil }
        return transactionHistoryService.fetchNextTransactionHistoryPage()
    }

    func addFunds() {
        Analytics.log(.visaScreenButtonVisaAddFunds, analyticsSystems: .all, contextParams: .userWallet(userWalletInfo.id))

        nextViewOpeningTask?.cancel()
        nextViewOpeningTask = Task { @MainActor in
            guard let depositAddress = tangemPayAccount.depositAddress,
                  let swapableToken = makeSendSwapableToken() else {
                coordinator?.openTangemPayNoDepositAddressSheet()
                return
            }

            coordinator?.openTangemPayAddFundsSheet(
                input: .init(
                    userWalletInfo: userWalletInfo,
                    address: depositAddress,
                    swapableToken: swapableToken
                )
            )
        }
    }

    func openCardManagement(entry: TangemPayCardEntry) {
        Analytics.log(.visaScreenCardSettingsClicked, contextParams: .userWallet(userWalletInfo.id))
        Analytics.log(.visaCardIconClicked, contextParams: .userWallet(userWalletInfo.id))
        coordinator?.openCardManagement(entry: entry)
    }

    func openAddToApplePayGuide() {
        guard let card = tangemPayAccount.activeCards.first else { return }
        Analytics.log(.visaScreenAddToWalletClicked, contextParams: .userWallet(userWalletInfo.id))
        coordinator?.openAddToApplePayGuide(
            viewModel: TangemPayCardDetailsViewModel(
                userWalletId: userWalletInfo.id,
                repository: tangemPayAssembly.makeCardDetailsRepository(for: card)
            )
        )
    }

    func dismissAddToApplePayGuideBanner() {
        AppSettings.shared.tangemPayShowAddToApplePayGuide = false
    }

    func showCardIssueFailureAlert() {
        alert = AlertBinder(
            title: Localization.commonSomethingWentWrong,
            message: Localization.commonTryAgainLater
        )
    }

    func tapAddCard() {
        Analytics.log(.visaAddExtraCardClicked, contextParams: .userWallet(userWalletInfo.id))

        guard tangemPayAccount.cardEntries.count < TangemPayAccount.maxCardsAllowed else {
            coordinator?.openMaximumCardsIssuedSheet()
            return
        }

        guard let offer = additionalCardIssueOffer, let fee = offer.fee else {
            showCardIssueFailureAlert()
            runTask { [tangemPayAccount] in
                await tangemPayAccount.loadOffers()
            }
            return
        }

        coordinator?.openIssueAdditionalCardCostPopup(
            offer: offer,
            fee: fee,
            issueCard: { [tangemPayAccount] in
                _ = try await tangemPayAccount.issueAdditionalCard()
            }
        )
    }

    func withdraw() {
        Analytics.log(.visaScreenWithdrawClicked, contextParams: .userWallet(userWalletInfo.id))
        guard let swapableToken = makeSendSwapableToken() else {
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
                try await self?.openWithdraw(swapableToken: swapableToken)
            } catch is CancellationError {
                // Do nothing
            } catch {
                self?.alert = error.alertBinder
            }

            self?.isWithdrawButtonLoading = false
        }
    }

    func onAppear() {
        Analytics.log(.visaScreenVisaMainScreenOpened, contextParams: .userWallet(userWalletInfo.id))

        runTask { [tangemPayAccount] in
            await tangemPayAccount.loadCustomerInfo()
            await tangemPayAccount.loadBalance()
            await tangemPayAccount.loadOffers()
            // Reconcile local `activeIssueOrdersSubject` against BFF's `findOrders`. Without
            // this, returning to the screen after a card finished issuing while the polling
            // task was suspended (background / killed) leaves the completed order in local
            // state and it renders as a duplicate "issuing" entry next to the issued card.
            await tangemPayAccount.resumeAdditionalCardIssuePolling()
        }
    }

    func termsAndLimits() {
        Analytics.log(.visaScreenTermsAndLimitsClicked, contextParams: .userWallet(userWalletInfo.id))
        coordinator?.openTermsAndLimits()
    }

    func contactSupport() {
        Analytics.log(.visaScreenGoToSupportOnBetaBannerClicked, contextParams: .userWallet(userWalletInfo.id))
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
            ],
            contextParams: .userWallet(userWalletInfo.id)
        )
        coordinator?.openTangemPayTransactionDetailsSheet(
            transaction: transaction,
            userWalletId: userWalletInfo.id,
            customerId: tangemPayAccount.customerId
        )
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

        tangemPayAccount.cardEntriesPublisher
            .receiveOnMain()
            .assign(to: &$cardEntries)

        tangemPayAccount.offersPublisher
            .receiveOnMain()
            .map { offers in offers.first { $0.type.isAdditionalCardIssue } }
            .assign(to: &$additionalCardIssueOffer)

        tangemPayAccount.anyCardReissuingPublisher
            .receiveOnMain()
            .assign(to: &$isAnyCardReissuing)

        Publishers.CombineLatest3(
            AppSettings.shared.$tangemPayShowAddToApplePayGuide,
            tangemPayAccount.statePublisher,
            tangemPayAccount.cardsPublisher
        )
        .map { showGuide, customerState, cards in
            PKPaymentAuthorizationViewController.canMakePayments()
                && customerState == .active
                && showGuide
                && cards.contains { $0.productInstance.status == .active }
        }
        .receiveOnMain()
        .assign(to: &$shouldDisplayAddToApplePayGuide)

        tangemPayAccount.cardIssueFailureSignal
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.showCardIssueFailureAlert()
            }
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

        bindInlineNotifications()
    }

    func bindInlineNotifications() {
        guard let accountModel = tangemPayAccount.account else { return }

        accountModel.statePublisher
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .map { viewModel, state -> [NotificationViewInput] in
                guard let event = state.errorNotificationEvent(icon: viewModel.mainButtonIcon) else {
                    return []
                }
                return [viewModel.makeInlineNotification(for: event)]
            }
            .assign(to: &$inlineNotifications)
    }

    func makeInlineNotification(for event: TangemPayNotificationEvent) -> NotificationViewInput {
        NotificationsFactory().buildNotificationInput(
            for: event,
            buttonAction: { [weak self] _, action in
                self?.handleInlineNotificationButtonTap(action)
            },
            dismissAction: nil
        )
    }

    func handleInlineNotificationButtonTap(_ action: NotificationButtonActionType) {
        switch action {
        case .renewTangemPaySession:
            renewSession()
        default:
            break
        }
    }

    var mainButtonIcon: MainButton.Icon? {
        CommonTangemIconProvider(config: userWalletInfo.config).getMainButtonIcon()
    }

    func makeSendSwapableToken() -> (any SendSwapableToken)? {
        guard let depositAddress = tangemPayAccount.depositAddress else {
            return nil
        }

        return TangemPaySwapableTokenFactory(
            userWalletInfo: userWalletInfo,
            account: tangemPayAccount.account,
            tokenItem: TangemPayUtilities.usdcTokenItem,
            feeTokenItem: TangemPayUtilities.usdcTokenItem,
            defaultAddressString: depositAddress,
            availableBalanceProvider: tangemPayAccount.balancesProvider.availableBalanceProvider,
            fiatAvailableBalanceProvider: tangemPayAccount.balancesProvider.fiatAvailableBalanceProvider,
            cexTransactionDispatcher: tangemPayAccount.expressCEXTransactionDispatcher,
            transactionValidator: TangemPayExpressTransactionValidator(
                availableBalanceProvider: tangemPayAccount.balancesProvider.availableBalanceProvider,
            ),
            operationType: .swap
        ).makeSwapableToken()
    }
}

// MARK: - Navigation

private extension TangemPayMainViewModel {
    @MainActor
    func openWithdraw(swapableToken: any SendSwapableToken) async throws {
        let restriction = try await tangemPayAccount.withdrawAvailabilityProvider.restriction()

        switch restriction {
        case .none, .zeroWalletBalance:
            coordinator?.openTangemPayWithdraw(input: .from(swapableToken))
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

