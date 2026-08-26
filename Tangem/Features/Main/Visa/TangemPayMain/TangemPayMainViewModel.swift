//
//  TangemPayMainViewModel.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Combine
import PassKit
import SwiftUI
import TangemAssets
import TangemUI
import TangemUIUtils
import TangemFoundation
import TangemLocalization
import TangemPay
import TangemVisa

final class TangemPayMainViewModel: ObservableObject {
    private var cashbackEnabled: Bool {
        FeatureProvider.isAvailable(.tangemPayCashback)
    }

    lazy var refreshScrollViewStateObject = RefreshScrollViewStateObject { [weak self] in
        guard let self else { return }

        // Re-evaluates the account state so it can recover from a stale `.unavailable` / `.syncNeeded`
        // once the backend is reachable again — otherwise the banner and dimming would persist.
        async let stateRefresh: Void? = tangemPayAccount.account?.refreshState()
        async let promotionsUpdate: Void = promotionNotificationsManager.loadPromotions()

        if !isDeactivated {
            async let transactionsUpdate: Void = transactionHistoryService.reloadHistory()
            async let customerInfoUpdate: Void = tangemPayAccount.loadCustomerInfo()
            async let offersUpdate: Void = tangemPayAccount.loadOffers()
            async let resumePolling: Void = tangemPayAccount.resumeActiveIssueOrderPolling()
            async let eligibilityUpdate: Void = loadVirtualAccountEligibility()
            async let cashbackUpdate: Void = loadCashbackSummaryIfAvailable()
            _ = await (
                stateRefresh,
                promotionsUpdate,
                transactionsUpdate,
                customerInfoUpdate,
                offersUpdate,
                resumePolling,
                eligibilityUpdate,
                cashbackUpdate
            )
        } else {
            async let balanceUpdate: Void = tangemPayAccount.loadBalance()
            _ = await (stateRefresh, promotionsUpdate, balanceUpdate)
        }
    }

    @Published private(set) var balance: LoadableBalanceView.State
    @Published private(set) var tangemPayTransactionHistoryState: TransactionsListView.State = .loading
    @Published private(set) var pendingExpressTransactions: [PendingExpressTransactionView.Info] = []
    @Published private var isWithdrawUnavailable: Bool = false
    @Published private var isAddFundsUnavailable: Bool = false
    @Published private var isWithdrawLoading: Bool = false
    @Published private var isAddFundsLoading: Bool = false

    var isWithdrawButtonDisabled: Bool {
        isWithdrawUnavailable || isWithdrawLoading
    }

    var isAddFundsButtonDisabled: Bool {
        isAddFundsUnavailable || isAddFundsLoading
    }

    @Published private(set) var inlineNotifications: [NotificationViewInput] = []
    @Published private(set) var shouldDisplayAddToApplePayGuide: Bool = false

    @Published private(set) var freezingState: TangemPayFreezingState = .normal
    @Published private(set) var cardEntries: [TangemPayCardEntry] = []
    @Published private(set) var isAddCardLoading: Bool = false

    @Published private(set) var awaitingDepositInfo: TangemPayAwaitingDepositInfo?
    @Published private(set) var cashback: TangemPayCashback?
    @Published private var isCashbackBlocked = false
    @Published private var didCashbackLoadFail = false
    @Published private var isCashbackLoading = false

    @Published private(set) var isBalanceNegative: Bool = false

    @Published private(set) var systemDowngradeBanner: SystemDowngradeBanner?

    @Published private(set) var contactSupportMessageBannerButton: MessageBannerButton?

    @Published private(set) var currentPlanState: CurrentPlanState = .unknown

    @Published private(set) var isVisaBenefitsAvailable = false

    lazy var cardDeactivatedNotificationInput: NotificationViewInput? = tangemPayAccount.isDeactivated
        ? NotificationsFactory().buildNotificationInput(
            for: TangemPayCardDeactivatedNotificationEvent(),
            buttonAction: { [weak self] _, action in
                self?.handleDeactivatedBannerButtonTap(action)
            }
        )
        : nil

    let promotionNotificationsViewModel: PromotionNotificationsViewModel
    @Published var alert: AlertBinder?

    var isStale: Bool {
        !inlineNotifications.isEmpty
    }

    var shouldDimTransactions: Bool {
        isStale && tangemPayTransactionHistoryState.isLoaded
    }

    var isDeactivated: Bool {
        tangemPayAccount.isDeactivated
    }

    var toolbarSubtitle: String {
        FeatureProvider.isAvailable(.tangemPayMultichain)
            ? Localization.tangempayMultinetwork
            : Localization.tangempayUsdcOnPolygonNetwork
    }

    var actionButtonsDisabled: Bool {
        let allCardsBlocked = cardEntries.allConforms { cardEntry in
            cardEntry.card?.productInstance.status == .blocked
        }

        return freezingState.shouldDisableActionButtons || isStale || allCardsBlocked
    }

    var hasIssuingEntry: Bool {
        cardEntries.contains { $0.isIssuing }
    }

    var isAwaitingDeposit: Bool {
        awaitingDepositInfo != nil
    }

    var cashbackBannerState: TangemPayCashbackState? {
        cashbackDisplayMode == .full ? cashbackState : nil
    }

    var cashbackMenuState: TangemPayCashbackState? {
        cashbackDisplayMode == .alternative ? cashbackState : nil
    }

    var cashbackBannerImpression: CashbackImpression? {
        cashbackBannerState.map(CashbackImpression.init)
    }

    var cashbackMenuItemImpression: CashbackImpression? {
        cashbackMenuState.map(CashbackImpression.init)
    }

    private var cashbackState: TangemPayCashbackState? {
        guard !isDeactivated else {
            return nil
        }

        if didCashbackLoadFail, cashback == nil {
            return .failed(isReloading: isCashbackLoading)
        }

        guard case .available(let summary) = cashback else {
            return nil
        }

        return .content(summary, isReloading: isCashbackLoading)
    }

    private var cashbackDisplayMode: TangemPayCashback.DisplayMode {
        guard case .available(let summary) = cashback else {
            return .full
        }

        return summary.displayMode
    }

    var addCardDisabled: Bool {
        isStale || hasIssuingEntry || isAddCardLoading
    }

    var notificationBannerItems: [NotificationBannerItem] {
        MultiWalletNotificationBannerMapper().mapItems(
            inlineNotifications,
            cardDeactivatedNotificationInput.map { [$0] } ?? []
        )
    }

    var cashbackBlockedBanner: MessageBannerButton? {
        guard !isDeactivated, isCashbackBlocked else {
            return nil
        }

        return MessageBannerButton(
            title: Localization.commonGotIt,
            action: { [weak self] in
                self?.dismissCashbackBlockedBanner()
            }
        )
    }

    var awaitingDepositAddFundsButton: MessageBannerButton {
        MessageBannerButton(
            title: Localization.tangempayCardDetailsAddFunds,
            action: { [weak self] in
                self?.addFunds()
            }
        )
    }

    @Injected(\.mailComposePresenter) private var mailPresenter: MailComposePresenter
    @Injected(\.tangemPayAssembly) private var tangemPayAssembly: TangemPayAssembly

    private let userWalletInfo: UserWalletInfo
    private let tangemPayAccount: TangemPayAccount
    private let fundingFlowBuilder: TangemPayFundingFlowBuilder
    private weak var coordinator: TangemPayMainRoutable?

    private let transactionHistoryService: TangemPayTransactionHistoryService
    private let pendingExpressTransactionsManager: PendingExpressTransactionsManager
    private let expressStatusPollingHelper: ExpressStatusPollingHelper
    private let promotionNotificationsManager: PromotionNotificationsManager

    private let isEligibleForVirtualAccountSubject = CurrentValueSubject<Bool, Never>(false)

    private var nextViewOpeningTask: Task<Void, Error>?
    private var bag = Set<AnyCancellable>()

    init(
        userWalletInfo: UserWalletInfo,
        tangemPayAccount: TangemPayAccount,
        fundingFlowBuilder: TangemPayFundingFlowBuilder,
        coordinator: TangemPayMainRoutable
    ) {
        self.userWalletInfo = userWalletInfo
        self.tangemPayAccount = tangemPayAccount
        self.fundingFlowBuilder = fundingFlowBuilder
        self.coordinator = coordinator

        balance = tangemPayAccount.mainHeaderBalanceProvider.balance

        transactionHistoryService = TangemPayTransactionHistoryService(
            apiService: tangemPayAccount.customerService,
            tangemPayAccount: tangemPayAccount,
            cacheStorage: AppSettings.shared,
            customerWalletId: userWalletInfo.id.stringValue,
            isTangemPayUnavailablePublisher: tangemPayAccount.account?.statePublisher
                .map(\.indicatesStaleData)
                .eraseToAnyPublisher() ?? Empty<Bool, Never>().eraseToAnyPublisher()
        )

        let expressStatusTracking = ExpressStatusTrackingFactory(
            userWalletInfo: userWalletInfo,
            tokenItem: TangemPayUtilities.usdcTokenItem,
            transactionHistoryEnricherFactory: { nil } // [REDACTED_TODO_COMMENT]
        )
        .makeExpressStatusTracking()

        pendingExpressTransactionsManager = expressStatusTracking.manager
        expressStatusPollingHelper = expressStatusTracking.pollingHelper

        let promotionNotificationsManager = CommonPromotionNotificationsManager(
            userWalletId: userWalletInfo.id,
            placement: .paymentAccountMain
        )
        self.promotionNotificationsManager = promotionNotificationsManager
        promotionNotificationsViewModel = PromotionNotificationsViewModel(
            promotionNotificationsManager: promotionNotificationsManager
        )

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

    private var isBankTransferAvailable: Bool {
        guard tangemPayAccount.isKYCApproved else {
            return false
        }

        // Eligibility only gates issuing a brand-new VA. An already-issued one stays reachable.
        return tangemPayAccount.hasVirtualAccount || isEligibleForVirtualAccountSubject.value
    }

    @MainActor
    private func loadVirtualAccountEligibility() async {
        do {
            let channels = try await tangemPayAccount.customerService.loadEligibility().channels
            isEligibleForVirtualAccountSubject.send(channels.contains(.visaVirtualAccount))
        } catch {
            VisaLogger.error("Failed to load virtual account eligibility", error: error)
        }
    }

    @MainActor
    func openVAOnramp() async {
        if !tangemPayAccount.hasVirtualAccount {
            let eligibilityTimeout: TimeInterval = 5

            _ = try? await isEligibleForVirtualAccountSubject
                .filter { $0 }
                .timeout(.seconds(eligibilityTimeout), scheduler: DispatchQueue.main)
                .async()
        }

        guard isBankTransferAvailable else {
            return
        }

        coordinator?.openVAOnramp()
    }

    func addFunds() {
        Analytics.log(.visaScreenButtonVisaAddFunds, analyticsSystems: .all, contextParams: .userWallet(userWalletInfo.id))

        nextViewOpeningTask?.cancel()
        nextViewOpeningTask = runWithDelayedLoading(
            onLongRunning: { @MainActor [weak self] in
                self?.isAddFundsLoading = true
            },
            onCancel: { [weak self] in
                self?.isAddFundsLoading = false
            },
            operation: { @MainActor [weak self, fundingFlowBuilder, tangemPayAccount] in
                defer { self?.isAddFundsLoading = false }

                guard let depositAddress = tangemPayAccount.depositAddress else {
                    self?.coordinator?.openTangemPayNoDepositAddressSheet()
                    return
                }

                let swapParameters = await fundingFlowBuilder.addFunds()

                guard !Task.isCancelled, let self else { return }

                guard let swapParameters else {
                    coordinator?.openTangemPayNoDepositAddressSheet()
                    return
                }

                coordinator?.openTangemPayAddFundsSheet(
                    input: .init(
                        userWalletInfo: userWalletInfo,
                        address: depositAddress,
                        swapParameters: swapParameters,
                        isBankTransferAvailable: isBankTransferAvailable,
                        networks: tangemPayAccount.networks
                    )
                )
            }
        )
    }

    // MARK: - Multi-card

    func openCardManagement(entry: TangemPayCardEntry) {
        Analytics.log(.visaScreenCardSettingsClicked, contextParams: .userWallet(userWalletInfo.id))
        Analytics.log(.visaCardIconClicked, contextParams: .userWallet(userWalletInfo.id))
        coordinator?.openCardManagement(entry: entry)
    }

    func showCardIssueFailureAlert() {
        alert = AlertBinder(
            title: Localization.commonSomethingWentWrong,
            message: Localization.commonTryAgainLater
        )
    }

    func tapAddCard() {
        Analytics.log(.visaAddExtraCardClicked, contextParams: .userWallet(userWalletInfo.id))

        addCard()
    }

    func addCard(cardType: TangemPayOrderCardType? = nil) {
        if let offer = tangemPayAccount.additionalCardIssueOffer, let fee = offer.fee {
            openAdditionalCardIssue(offer: offer, fee: fee, cardType: cardType)
            return
        }

        nextViewOpeningTask?.cancel()
        nextViewOpeningTask = runWithDelayedLoading(
            onLongRunning: { @MainActor [weak self] in
                self?.isAddCardLoading = true
            },
            onCancel: { [weak self] in
                self?.isAddCardLoading = false
            },
            operation: { @MainActor [weak self] in
                guard let self else { return }

                await tangemPayAccount.loadOffers()

                if let offer = tangemPayAccount.additionalCardIssueOffer, let fee = offer.fee {
                    openAdditionalCardIssue(offer: offer, fee: fee, cardType: cardType)
                } else if await isTariffPlanUpgradeAvailable() {
                    coordinator?.openCardsLimitReachedSheet()
                } else {
                    coordinator?.openMaximumCardsIssuedSheet()
                }

                isAddCardLoading = false
            }
        )
    }

    private func isTariffPlanUpgradeAvailable() async -> Bool {
        do {
            let transitions = try await tangemPayAccount.getTariffPlanTransitions()
            return transitions.contains { $0.type == .upgrade }
        } catch {
            VisaLogger.error("Failed to load tariff plan transitions", error: error)
            return false
        }
    }

    private func openAdditionalCardIssue(offer: TangemPayCustomerOffer, fee: TangemPayCustomerOffer.Fee, cardType: TangemPayOrderCardType?) {
        guard FeatureProvider.isAvailable(.tangemPayPlastic) else {
            openIssueAdditionalCardCostPopup(offer: offer, fee: fee)
            return
        }

        coordinator?.openOrderCardType(fee: fee, cardType: cardType)
    }

    func orderCardTypeDidSelectVirtual() {
        guard let offer = tangemPayAccount.additionalCardIssueOffer, let fee = offer.fee else { return }

        openIssueAdditionalCardCostPopup(offer: offer, fee: fee)
    }

    private func openIssueAdditionalCardCostPopup(offer: TangemPayCustomerOffer, fee: TangemPayCustomerOffer.Fee) {
        coordinator?.openIssueAdditionalCardCostPopup(
            offer: offer,
            fee: fee,
            issueCard: { [tangemPayAccount] in
                _ = try await tangemPayAccount.issueAdditionalCard()
            }
        )
    }

    func smallCardState(for card: TangemPayCard) -> TangemPaySmallCardView.State {
        if card.isClosing { return .closing }
        if card.isReissuing { return .replacing }
        return .issued(cardNumberEnd: card.cardNumberEnd)
    }

    // MARK: - Shared

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

    func logCashbackBannerImpression() {
        switch cashbackBannerImpression {
        case .content:
            Analytics.log(.visaCashbackBannerShowed, contextParams: .userWallet(userWalletInfo.id))
        case .error:
            Analytics.log(.visaCashbackBannerErrorStateShowed, contextParams: .userWallet(userWalletInfo.id))
        case nil:
            break
        }
    }

    func logCashbackMenuItemImpression() {
        switch cashbackMenuItemImpression {
        case .content:
            Analytics.log(.visaCashbackButtonInSettingsShowed, contextParams: .userWallet(userWalletInfo.id))
        case .error:
            Analytics.log(.visaCashbackButtonErrorStateShowed, contextParams: .userWallet(userWalletInfo.id))
        case nil:
            break
        }
    }

    func onCashbackBannerTap() {
        Analytics.log(.visaCashbackBannerClicked, contextParams: .userWallet(userWalletInfo.id))
        handleCashbackTap()
    }

    func onCashbackMenuItemTap() {
        Analytics.log(.visaCashbackButtonInSettingsClicked, contextParams: .userWallet(userWalletInfo.id))
        handleCashbackTap()
    }

    @MainActor
    func openCashback() async {
        guard cashbackEnabled, !isDeactivated else {
            return
        }

        let cashbackDeeplinkTimeout: TimeInterval = 5

        let loadedCashback = try? await $cashback
            .compactMap { $0 }
            .timeout(.seconds(cashbackDeeplinkTimeout), scheduler: DispatchQueue.main)
            .async()

        guard loadedCashback != nil else {
            return
        }

        openCashbackDetails()
    }

    func onCashbackBlockedBannerAppear() {
        Analytics.log(.visaCashbackDeactivationBannerShowed, contextParams: .userWallet(userWalletInfo.id))
    }

    private func dismissCashbackBlockedBanner() {
        Analytics.log(.visaCashbackDeactivationBannerGotItClicked, contextParams: .userWallet(userWalletInfo.id))
        AppSettings.shared.tangemPayCashbackBlockedBannerDismissedForCustomerWalletId[userWalletInfo.id.stringValue] = true
    }

    func withdraw() {
        Analytics.log(.visaScreenWithdrawClicked, contextParams: .userWallet(userWalletInfo.id))

        nextViewOpeningTask?.cancel()
        nextViewOpeningTask = runWithDelayedLoading(
            onLongRunning: { @MainActor [weak self] in
                self?.isWithdrawLoading = true
            },
            onCancel: { [weak self] in
                self?.isWithdrawLoading = false
            },
            operation: { @MainActor [weak self, fundingFlowBuilder] in
                defer { self?.isWithdrawLoading = false }

                let resolution = await fundingFlowBuilder.withdraw()

                guard !Task.isCancelled, let self else { return }

                switch resolution {
                case .noDepositAddress:
                    coordinator?.openTangemPayNoDepositAddressSheet()

                case .noWithdrawableToken:
                    alert = AlertBinder(
                        title: Localization.commonSomethingWentWrong,
                        message: Localization.commonTryAgainLater
                    )

                case .parameters(let swapParameters):
                    do {
                        try await openWithdraw(swapParameters: swapParameters)
                    } catch is CancellationError {
                        // Do nothing
                    } catch {
                        alert = error.alertBinder
                    }
                }
            }
        )
    }

    func onAppear() {
        Analytics.log(.visaScreenVisaMainScreenOpened, contextParams: .userWallet(userWalletInfo.id))

        runTask { [tangemPayAccount] in
            await tangemPayAccount.loadCustomerInfo()
            await tangemPayAccount.loadOffers()
            await tangemPayAccount.resumeActiveIssueOrderPolling()
        }

        runTask { [self] in
            await loadCashbackSummaryIfAvailable()
        }

        runTask { [self] in
            await loadVirtualAccountEligibility()
        }

        runTask { [promotionNotificationsManager] in
            await promotionNotificationsManager.loadPromotions()
        }

        tangemPayAccount.startDepositAddressPolling()
    }

    func onDisappear() {
        nextViewOpeningTask?.cancel()
        tangemPayAccount.stopDepositAddressPolling()
    }

    func openCurrentPlan() {
        Analytics.log(.visaTiersCurrentPlanClicked, contextParams: .userWallet(userWalletInfo.id))
        coordinator?.openCurrentPlan()
    }

    func onTopupBannerAppear() {
        Analytics.log(.visaTiersTopupBannerForPlusShowed, contextParams: .userWallet(userWalletInfo.id))
    }

    func onSystemDowngradeBannerAppear() {
        Analytics.log(.visaTiersPlusCardsClosureWarningBannerShowed, contextParams: .userWallet(userWalletInfo.id))
    }

    func termsAndLimits() {
        Analytics.log(.visaScreenTermsAndLimitsClicked, contextParams: .userWallet(userWalletInfo.id))
        coordinator?.openTermsAndLimits()
    }

    func visaBenefits() {
        coordinator?.openVisaBenefits()
    }

    func contactSupport() {
        Analytics.log(.visaScreenGoToSupportOnBetaBannerClicked, contextParams: .userWallet(userWalletInfo.id))
        let dataCollector = TangemPaySupportDataCollector(
            source: .permanentBanner,
            userWalletId: userWalletInfo.id.stringValue,
            customerId: tangemPayAccount.customerId
        )
        let logsComposer = LogsComposer(infoProvider: dataCollector, includeSystemLogs: false)
        let mailViewModel = MailViewModel(
            logsComposer: logsComposer,
            recipient: EmailConfig.visaDefault(subject: .generalHelp).recipient,
            emailType: .visaFeedback(subject: .generalHelp)
        )

        Task { @MainActor in
            mailPresenter.present(viewModel: mailViewModel)
        }
    }

    private func contactSupportForFailedCardIssue() {
        let dataCollector = TangemPaySupportDataCollector(
            source: .failedToIssueCardSheet,
            userWalletId: userWalletInfo.id.stringValue,
            customerId: tangemPayAccount.customerId
        )
        let logsComposer = LogsComposer(infoProvider: dataCollector, includeSystemLogs: false)
        let mailViewModel = MailViewModel(
            logsComposer: logsComposer,
            recipient: EmailConfig.visaDefault(subject: .failedToIssueCard).recipient,
            emailType: .visaFeedback(subject: .failedToIssueCard)
        )

        Task { @MainActor in
            mailPresenter.present(viewModel: mailViewModel)
        }
    }

    func promptRemoveAccount() {
        alert = AlertBinder(alert: Alert(
            title: Text(Localization.tangempayRemoveAccountAlertTitle),
            message: Text(Localization.tangempayRemoveAccountAlertDescription),
            primaryButton: .destructive(Text(Localization.tangempayRemoveAccount)) { [weak self] in
                self?.performRemoveAccount()
            },
            secondaryButton: .cancel()
        ))
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

// MARK: - CashbackImpression

extension TangemPayMainViewModel {
    enum CashbackImpression: Equatable {
        case content
        case error

        init(_ state: TangemPayCashbackState) {
            switch state {
            case .content: self = .content
            case .failed: self = .error
            }
        }
    }
}

// MARK: - CurrentPlanState

extension TangemPayMainViewModel {
    enum CurrentPlanState: Equatable {
        case plan(name: String)
        case changing
        case unknown
    }
}

private extension TangemPayMainViewModel {
    static func makeCurrentPlanState(
        customerTariffPlan: VisaCustomerInfoResponse.CustomerTariffPlan?,
        isAwaitingDeposit: Bool
    ) -> CurrentPlanState {
        if isAwaitingDeposit || customerTariffPlan?.status == .transitioning {
            return .changing
        }

        guard let name = customerTariffPlan?.tariffPlan.name.nilIfEmpty else {
            return .unknown
        }

        return .plan(name: name)
    }
}

// MARK: - SystemDowngradeBanner

extension TangemPayMainViewModel {
    struct SystemDowngradeBanner: Equatable {
        let title: String
        let subtitle: String
    }
}

private extension TangemPayMainViewModel {
    static let systemDowngradeDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d yyyy"
        return formatter
    }()

    static func makeSystemDowngradeBanner(from plan: VisaCustomerInfoResponse.CustomerTariffPlan) -> SystemDowngradeBanner? {
        guard plan.status == .systemDowngradePending, let nextBillingAt = plan.nextBillingAt else {
            return nil
        }

        let date = systemDowngradeDateFormatter.string(from: nextBillingAt)

        return SystemDowngradeBanner(
            title: Localization.tangempayCardDetailsSystemDowngradeTitle,
            subtitle: Localization.tangempayCardDetailsSystemDowngradeSubtitle(plan.tariffPlan.name, date)
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

        tangemPayAccount.balancesProvider.fixedFiatTotalTokenBalanceProvider.balanceTypePublisher
            .map { balance in balance.value.map { $0 <= 0 } ?? false }
            .receiveOnMain()
            .assign(to: &$isWithdrawUnavailable)

        tangemPayAccount.depositAddressPublisher
            .map { $0 == nil }
            .receiveOnMain()
            .assign(to: &$isAddFundsUnavailable)

        tangemPayAccount.balancesProvider.fixedFiatTotalTokenBalanceProvider.balanceTypePublisher
            .map { balance in balance.value.map { $0 < 0 } ?? false }
            .receiveOnMain()
            .assign(to: &$isBalanceNegative)

        bindCustomerTariffPlan()

        bindInlineNotifications()

        bindFailedToIssueCardBanner()

        bindMultiCard()
    }

    func bindCustomerTariffPlan() {
        Publishers.CombineLatest(
            tangemPayAccount.customerTariffPlanPublisher,
            $awaitingDepositInfo.map { $0 != nil }.removeDuplicates()
        )
        .map { Self.makeCurrentPlanState(customerTariffPlan: $0, isAwaitingDeposit: $1) }
        .removeDuplicates()
        .receiveOnMain()
        .assign(to: &$currentPlanState)

        tangemPayAccount.customerTariffPlanPublisher
            .map { plan in
                guard let plan else {
                    return false
                }
                return plan.tariffPlan.type != TangemPayAccount.basicTariffPlanType
            }
            .removeDuplicates()
            .receiveOnMain()
            .assign(to: &$isVisaBenefitsAvailable)

        tangemPayAccount.customerTariffPlanPublisher
            .map { plan in
                plan.flatMap { Self.makeSystemDowngradeBanner(from: $0) }
            }
            .removeDuplicates()
            .receiveOnMain()
            .assign(to: &$systemDowngradeBanner)
    }

    func bindMultiCard() {
        tangemPayAccount.cardEntriesPublisher
            .receiveOnMain()
            .assign(to: &$cardEntries)

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

        tangemPayAccount.cardIssueCompletedSignal
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, _ in
                viewModel.reloadHistory()
            }
            .store(in: &bag)

        tangemPayAccount.awaitingDepositInfoPublisher
            .receiveOnMain()
            .assign(to: &$awaitingDepositInfo)

        if cashbackEnabled {
            tangemPayAccount.cashbackPublisher
                .receiveOnMain()
                .assign(to: &$cashback)

            let customerWalletId = userWalletInfo.id.stringValue

            Publishers.CombineLatest(
                tangemPayAccount.cashbackPublisher,
                AppSettings.shared.$tangemPayCashbackBlockedBannerDismissedForCustomerWalletId
            )
            .map { cashback, dismissedByCustomerWalletId in
                cashback == .blocked && !dismissedByCustomerWalletId[customerWalletId, default: false]
            }
            .removeDuplicates()
            .receiveOnMain()
            .assign(to: &$isCashbackBlocked)
        }
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

    func bindFailedToIssueCardBanner() {
        guard let accountModel = tangemPayAccount.account else { return }

        accountModel.statePublisher
            .map { $0.isFailedToIssueCard }
            .removeDuplicates()
            .receiveOnMain()
            .withWeakCaptureOf(self)
            .sink { viewModel, isFailedToIssueCard in
                if isFailedToIssueCard {
                    viewModel.contactSupportMessageBannerButton = .init(
                        title: Localization.commonContactSupport,
                        action: { [weak viewModel] in viewModel?.contactSupportForFailedCardIssue() }
                    )
                } else {
                    viewModel.contactSupportMessageBannerButton = nil
                }
            }
            .store(in: &bag)
    }

    @MainActor
    func loadCashbackSummaryIfAvailable() async {
        guard cashbackEnabled else { return }
        guard !isDeactivated else { return }

        isCashbackLoading = true
        defer { isCashbackLoading = false }

        do {
            try await tangemPayAccount.loadCashbackSummary()
            didCashbackLoadFail = false
        } catch {
            VisaLogger.error("Failed to load TangemPay cashback summary", error: error)
            didCashbackLoadFail = true
        }
    }

    func handleCashbackTap() {
        switch cashbackState {
        case .content(_, let isReloading):
            guard !isReloading else { return }

            openCashbackDetails()

        case .failed(let isReloading):
            guard !isReloading else { return }

            runTask { [weak self] in
                await self?.loadCashbackSummaryIfAvailable()
            }

        case nil:
            break
        }
    }

    func openCashbackDetails() {
        guard case .content(let summary, _) = cashbackState else {
            return
        }

        coordinator?.openCashbackDetail(summary: summary)
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

    func handleDeactivatedBannerButtonTap(_ action: NotificationButtonActionType) {
        switch action {
        case .removeTangemPayAccount:
            promptRemoveAccount()
        default:
            break
        }
    }

    func performRemoveAccount() {
        tangemPayAccount.removeAccount { [weak self] success in
            Task { @MainActor in
                if success {
                    self?.coordinator?.closePaymentAccount()
                } else {
                    self?.alert = AlertBinder(title: Localization.commonSomethingWentWrong, message: Localization.commonTryAgainLater)
                }
            }
        }
    }

    var mainButtonIcon: MainButton.Icon? {
        CommonTangemIconProvider(config: userWalletInfo.config).getMainButtonIcon()
    }
}

// MARK: - Navigation

private extension TangemPayMainViewModel {
    @MainActor
    func openWithdraw(swapParameters: PredefinedSwapParameters) async throws {
        let restriction = try await tangemPayAccount.withdrawAvailabilityProvider.restriction()

        try Task.checkCancellation()

        switch restriction {
        case .none, .zeroWalletBalance:
            coordinator?.openTangemPayWithdraw(input: swapParameters)
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
