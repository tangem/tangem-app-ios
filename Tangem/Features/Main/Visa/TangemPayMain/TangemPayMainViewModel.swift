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

final class TangemPayMainViewModel: ObservableObject {
    lazy var refreshScrollViewStateObject = RefreshScrollViewStateObject { [weak self] in
        guard let self else { return }

        async let balanceUpdate: Void = tangemPayAccount.loadBalance()
        async let transactionsUpdate: Void = transactionHistoryService.reloadHistory()

        _ = await (balanceUpdate, transactionsUpdate)
    }

    @Published private(set) var balance: LoadableBalanceView.State
    @Published private(set) var tangemPayTransactionHistoryState: TransactionsListView.State = .loading
    @Published private(set) var freezingState: TangemPayFreezingState = .normal
    @Published private(set) var pendingExpressTransactions: [PendingExpressTransactionView.Info] = []
    @Published private(set) var shouldDisplayAddToApplePayGuide: Bool = false
    @Published private(set) var isWithdrawButtonLoading: Bool = false
    @Published var alert: AlertBinder?

    var cardNumberEnd: String {
        cardDetailsRepository.lastFourDigits
    }

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
        Analytics.log(.visaScreenButtonVisaAddFunds, contextParams: .userWallet(userWalletInfo.id))

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

    func openCardManagement() {
        Analytics.log(.visaScreenCardSettingsClicked, contextParams: .userWallet(userWalletInfo.id))
        coordinator?.openCardManagement()
    }

    func openFakedoorSheet() {
        coordinator?.openFakedoorSheet()
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
            await tangemPayAccount.loadBalance()
        }
    }

    func onDisappear() {
        runTask { [tangemPayAccount] in
            await tangemPayAccount.loadCustomerInfo()
        }
    }

    func openAddToApplePayGuide() {
        Analytics.log(.visaScreenAddToWalletClicked, contextParams: .userWallet(userWalletInfo.id))
        coordinator?.openAddToApplePayGuide(
            viewModel: .init(
                userWalletId: userWalletInfo.id,
                repository: cardDetailsRepository
            )
        )
    }

    func dismissAddToApplePayGuideBanner() {
        AppSettings.shared.tangemPayShowAddToApplePayGuide = false
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
