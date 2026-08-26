//
//  TangemPayAccount.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemPay
import TangemVisa

final class TangemPayAccount {
    var paymentTokenItem: TokenItem {
        TangemPayUtilities.usdcTokenItem
    }

    // MARK: - Multi-card surface

    var cardsPublisher: AnyPublisher<[TangemPayCard], Never> {
        cardsSubject.eraseToAnyPublisher()
    }

    private let plasticCards = TangemPayPlasticCardStubStore()

    var cardEntries: [TangemPayCardEntry] {
        TangemPayCardEntry.build(
            cards: cardsSubject.value,
            pendingProductInstances: customerInfoSubject.value.cardProductInstances.filter { $0.cardId == nil },
            activeIssueOrders: activeIssueOrdersSubject.value,
            plasticCards: plasticCards.cards
        )
    }

    var cardEntriesPublisher: AnyPublisher<[TangemPayCardEntry], Never> {
        Publishers.CombineLatest(
            Publishers.CombineLatest4(cardsSubject, customerInfoSubject, activeIssueOrdersSubject, anyCardReissuingPublisher),
            plasticCards.cardsPublisher
        )
        .map { bffState, plasticCards in
            let (cards, info, orders, _) = bffState
            return TangemPayCardEntry.build(
                cards: cards,
                pendingProductInstances: info.cardProductInstances.filter { $0.cardId == nil },
                activeIssueOrders: orders,
                plasticCards: plasticCards
            )
        }
        .eraseToAnyPublisher()
    }

    var offersPublisher: AnyPublisher<[TangemPayCustomerOffer], Never> {
        offersSubject.eraseToAnyPublisher()
    }

    var additionalCardIssueOffer: TangemPayCustomerOffer? {
        offersSubject.value.first { $0.type.isAdditionalCardIssue }
    }

    var cashbackPublisher: AnyPublisher<TangemPayCashback?, Never> {
        cashbackSubject.eraseToAnyPublisher()
    }

    var statePublisher: AnyPublisher<VisaCustomerInfoResponse.CustomerState, Never> {
        customerInfoSubject
            .map(\.state)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var anyCardReissuingPublisher: AnyPublisher<Bool, Never> {
        cardsSubject
            .map { cards -> AnyPublisher<Bool, Never> in
                guard !cards.isEmpty else { return .just(output: false) }
                return Publishers.MergeMany(cards.map(\.isReissuingPublisher))
                    .map { _ in cards.contains { $0.isReissuing } }
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }

    var awaitingDepositInfoPublisher: AnyPublisher<TangemPayAwaitingDepositInfo?, Never> {
        awaitingDepositInfoSubject.eraseToAnyPublisher()
    }

    var cardIssueFailureSignal: AnyPublisher<Void, Never> {
        cardIssueFailureSubject.eraseToAnyPublisher()
    }

    var cardIssueCompletedSignal: AnyPublisher<Void, Never> {
        cardIssueCompletedSubject.eraseToAnyPublisher()
    }

    var firstCardIssueFailedSignalPublisher: AnyPublisher<Void, Never> {
        firstCardIssueFailedSubject.eraseToAnyPublisher()
    }

    var cards: [TangemPayCard] {
        cardsSubject.value
    }

    var activeCards: [TangemPayCard] {
        cardsSubject.value.filter { $0.productInstance.status == .active || $0.productInstance.status == .blocked }
    }

    // MARK: - Shared signals

    var syncNeededSignalPublisher: AnyPublisher<Void, Never> {
        syncNeededSignalSubject.eraseToAnyPublisher()
    }

    var unavailableSignalPublisher: AnyPublisher<Void, Never> {
        unavailableSignalSubject.eraseToAnyPublisher()
    }

    // MARK: - Shared, dispatched

    var customerId: String {
        customerInfoSubject.value.id
    }

    var depositAddress: String? {
        customerInfoSubject.value.depositAddress?.nilIfEmpty
    }

    var depositAddressPublisher: some Publisher<String?, Never> {
        customerInfoSubject
            .map(\.depositAddress?.nilIfEmpty)
            .removeDuplicates()
    }

    var networks: [TangemPayBalance.Network] {
        balancesService.networks
    }

    var customerTariffPlan: VisaCustomerInfoResponse.CustomerTariffPlan? {
        customerInfoSubject.value.customerTariffPlan
    }

    var customerTariffPlanPublisher: AnyPublisher<VisaCustomerInfoResponse.CustomerTariffPlan?, Never> {
        customerInfoSubject
            .map(\.customerTariffPlan)
            .eraseToAnyPublisher()
    }

    var profile: VisaCustomerInfoResponse.Profile? {
        customerInfoSubject.value.profile
    }

    private var currentCustomerInfo: VisaCustomerInfoResponse {
        customerInfoSubject.value
    }

    private var customerWalletId: String {
        userWalletId.stringValue
    }

    // MARK: - Virtual Account

    var isKYCApproved: Bool {
        currentCustomerInfo.kyc?.status == .approved
    }

    var virtualAccountEntry: VirtualAccountEntry {
        if let productInstance = currentCustomerInfo.virtualAccountProductInstance {
            return productInstance.status == .active
                ? .active(productInstanceId: productInstance.id)
                : .preparing
        }
        return placedVirtualAccountOrderId == nil ? .none : .preparing
    }

    var hasVirtualAccount: Bool {
        if case .none = virtualAccountEntry {
            return false
        }
        return true
    }

    var isDeactivated: Bool {
        let info = customerInfoSubject.value
        if info.state == .former { return true }
        let cardInstances = info.cardProductInstances
        return !cardInstances.isEmpty &&
            cardInstances.allSatisfy { $0.status == .deactivated || $0.status == .canceled }
    }

    // MARK: - Withdraw

    let transactionDispatcher: TransactionDispatcher
    let withdrawAvailabilityProvider: TangemPayWithdrawAvailabilityProvider
    let withdrawTransactionService: any TangemPayWithdrawTransactionService

    // MARK: - Balances

    let mainHeaderBalanceProvider: MainHeaderBalanceProvider
    var balancesProvider: TangemPayBalancesProvider { balancesService }

    let customerService: any CustomerInfoManagementService
    let feeRepository: TangemPayFeeRepository

    let userWalletId: UserWalletId
    private(set) weak var account: (any TangemPayAccountModel)?
    private(set) weak var accountRemover: (any TangemPayAccountRemoving)?

    private let balancesService: any TangemPayBalancesService
    private let orderStatusPollingService: TangemPayOrderStatusPollingService
    private let orderResolver: TangemPayOrderResolver
    private let cashbackCacheStorage: TangemPayCashbackCacheStorage

    private let customerInfoSubject: CurrentValueSubject<VisaCustomerInfoResponse, Never>
    private let cardsSubject = CurrentValueSubject<[TangemPayCard], Never>([])
    private let offersSubject = CurrentValueSubject<[TangemPayCustomerOffer], Never>([])
    private let activeIssueOrdersSubject = CurrentValueSubject<[TangemPayOrderResponse], Never>([])
    private let activeIssueOrderEventsSubject = PassthroughSubject<ActiveIssueOrderEvent, Never>()
    private let awaitingDepositInfoSubject = CurrentValueSubject<TangemPayAwaitingDepositInfo?, Never>(nil)
    private let cashbackSubject = CurrentValueSubject<TangemPayCashback?, Never>(nil)

    private let loadOffersProcessor = SingleTaskProcessor<Void, Never>()
    private let loadCashbackSummaryProcessor = SingleTaskProcessor<Void, TangemPayAPIServiceError>()
    private let resumeIssuePollingProcessor = SingleTaskProcessor<Void, Never>()
    private let syncNeededSignalSubject = PassthroughSubject<Void, Never>()
    private let unavailableSignalSubject = PassthroughSubject<Void, Never>()
    private let cardIssueFailureSubject = PassthroughSubject<Void, Never>()
    private let cardIssueCompletedSubject = PassthroughSubject<Void, Never>()
    private let firstCardIssueFailedSubject = PassthroughSubject<Void, Never>()

    private var placedVirtualAccountOrderId: String?

    private var pendingTransitionCancellation: TransitionCancellationType?

    /// The VA order is polled on its own instance so it can't be cancelled by (or cancel) the shared
    /// `orderStatusPollingService`, which is single-slot and reused for freeze/reissue/card-issue.
    private lazy var virtualAccountOrderPollingService = TangemPayOrderStatusPollingService(
        customerService: customerService
    )

    /// Polls `customer/me` until a deposit address is available.
    private lazy var depositAddressPollingService = TangemPayDepositAddressPollingService(
        customerService: customerService
    )

    private var bag = Set<AnyCancellable>()

    init(
        userWalletId: UserWalletId,
        customerInfo: VisaCustomerInfoResponse,
        customerService: any CustomerInfoManagementService,
        balancesService: any TangemPayBalancesService,
        withdrawTransactionService: any TangemPayWithdrawTransactionService,
        transactionDispatcher: any TransactionDispatcher,
        withdrawAvailabilityProvider: TangemPayWithdrawAvailabilityProvider,
        orderStatusPollingService: TangemPayOrderStatusPollingService,
        mainHeaderBalanceProvider: MainHeaderBalanceProvider,
        orderResolver: TangemPayOrderResolver,
        feeRepository: TangemPayFeeRepository,
        cashbackCacheStorage: TangemPayCashbackCacheStorage,
        account: (any TangemPayAccountModel)?,
        accountRemover: (any TangemPayAccountRemoving)?
    ) {
        self.userWalletId = userWalletId
        customerInfoSubject = CurrentValueSubject(customerInfo)
        self.customerService = customerService
        self.balancesService = balancesService
        self.withdrawTransactionService = withdrawTransactionService
        self.transactionDispatcher = transactionDispatcher
        self.withdrawAvailabilityProvider = withdrawAvailabilityProvider
        self.orderStatusPollingService = orderStatusPollingService
        self.mainHeaderBalanceProvider = mainHeaderBalanceProvider
        self.orderResolver = orderResolver
        self.feeRepository = feeRepository
        self.cashbackCacheStorage = cashbackCacheStorage
        self.account = account
        self.accountRemover = accountRemover

        bindActiveIssueOrderEvents()
        bindAwaitingDepositInfo()
        cardsSubject.send(rebuildingCards(from: customerInfo, existing: []))
        observeCardRefreshSignals()
        restoreCachedCashback()
    }

    func loadBalance() async {
        await balancesService.loadBalance()
    }

    func loadCustomerInfo() async {
        await loadCustomerInfoNew()
    }

    func startDepositAddressPolling() {
        if depositAddress == nil {
            depositAddressPollingService.startPolling { [weak self] customerInfo in
                self?.customerInfoSubject.send(customerInfo)
            }
        } else {
            stopDepositAddressPolling()
        }
    }

    func stopDepositAddressPolling() {
        depositAddressPollingService.cancel()
    }

    func removeAccount(onFinish: @escaping (Bool) -> Void) {
        guard let accountRemover else {
            onFinish(false)
            return
        }
        accountRemover.removeAccount(onFinish: onFinish)
    }

    func getTransaction(transactionId: String) async throws(TangemPayAPIServiceError) -> TangemPayTransactionHistoryResponse.Transaction {
        try await customerService.getTransaction(transactionId: transactionId)
    }

    func getCashbackTransactionDetails(
        transactionId: String
    ) async throws(TangemPayAPIServiceError) -> TangemPayCashbackTransactionDetailsResponse {
        try await customerService.getCashbackTransactionDetails(transactionId: transactionId)
    }

    func card(cardId: String) -> TangemPayCard? {
        cards.first { $0.cardId == cardId }
    }
}

enum TangemPayAccountError: Error {
    case missingPaymentAccountAddress
    case missingDepositAddress
    case missingCardIssueOffer
    case missingOnrampFees
}

extension TangemPayAccount {
    enum VirtualAccountEntry {
        case none
        case preparing
        case active(productInstanceId: String)
    }
}

// MARK: - Plastic card flow

// [REDACTED_TODO_COMMENT]
extension TangemPayAccount {
    /// The only way a plastic card comes into existence, so gating it here keeps every plastic surface —
    /// the card row, card management and activation — behind the toggle. The card borrows `ACTIVATION` art
    /// from an issued one: it is the same screen background whichever card it comes from.
    func addOrderedPlasticCard(email: String?) {
        guard FeatureProvider.isAvailable(.tangemPayPlastic) else { return }

        plasticCards.add(email: email, activationImageURL: cards.first?.activationImageURL)
    }

    func markPlasticCardActivating(id: String) {
        plasticCards.markActivating(id: id)
    }
}

// MARK: - Virtual Account flow

extension TangemPayAccount {
    /// Places the VA issue order (Rain automation + deposit address on the collateral contract).
    /// The button loader covers only this request; the banking credentials are prepared server-side
    /// afterwards, so a background poll refreshes `customer/me` when the order completes.
    func createVirtualAccount() async throws {
        let info = currentCustomerInfo
        guard let depositAddress else {
            throw TangemPayAccountError.missingDepositAddress
        }

        let request = TangemPayPlaceOrderRequest(depositAddress: depositAddress)
        let idempotencyKey = TangemPayIdempotencyKey.make(
            info.id,
            TangemPayOrderType.accountIssueVirtualRain.rawValue,
            TangemPayPlaceOrderRequest.virtualAccountSpecificationName,
            depositAddress
        )

        let order = try await customerService.placeOrder(request: request, idempotencyKey: idempotencyKey)
        placedVirtualAccountOrderId = order.id
        startVirtualAccountOrderPolling(orderId: order.id)
    }

    func loadBankCredentials(productInstanceId: String) async throws -> TangemPayBankCredentialsResponse {
        try await customerService.getBankCredentials(productInstanceId: productInstanceId)
    }

    private func startVirtualAccountOrderPolling(orderId: String) {
        virtualAccountOrderPollingService.startOrderStatusPolling(
            orderId: orderId,
            interval: Constants.virtualAccountOrderPollInterval,
            onCompleted: { [weak self] in
                runTask { await self?.loadCustomerInfo() }
            },
            onCanceled: { [weak self] in
                // Drop the local flag so `virtualAccountEntry` falls back to `.none` and the info sheet
                // (retry path) becomes reachable again instead of pinning the user on "preparing".
                self?.placedVirtualAccountOrderId = nil
            },
            onFailed: { [weak self] error in
                VisaLogger.error("Failed to poll virtual account order status", error: error)
                self?.placedVirtualAccountOrderId = nil
            }
        )
    }
}

// MARK: - Fees

extension TangemPayAccount {
    func loadOnrampFees() async throws -> [TangemPayFeeResponse] {
        try await customerService.getFees(groups: [.onramp])
    }
}

private extension TangemPayAccount {
    func setupBalance() async {
        await balancesService.loadBalance()
    }
}

// MARK: - TangemPayWithdrawTransactionServiceOutput

extension TangemPayAccount: TangemPayWithdrawTransactionServiceOutput {
    func withdrawTransactionDidSent() {
        Task {
            // Update balance after withdraw with some delay
            try await Task.sleep(for: .seconds(5))
            await setupBalance()
        }
    }
}

// MARK: - Multi-card flow

extension TangemPayAccount {
    func loadOffers() async {
        await loadOffersProcessor.execute { @MainActor [weak self] in
            guard let self else { return }

            do {
                let offers = try await customerService.getCustomerOffers()
                offersSubject.send(offers)
            } catch {
                VisaLogger.error("Failed to load TangemPay offers", error: error)
            }
        }
    }

    func loadCashbackSummary() async throws(TangemPayAPIServiceError) {
        try await loadCashbackSummaryProcessor.execute { @MainActor [weak self] () async throws(TangemPayAPIServiceError) in
            guard let self else { return }

            let response = try await customerService.getCashbackSummary()
            let cashback = TangemPayCashback(response)

            switch cashback {
            case .available, .blocked:
                cashbackCacheStorage.saveCachedCashbackSummary(response, customerWalletId: customerWalletId)

            case .unavailable:
                cashbackCacheStorage.clearCachedCashbackSummary(customerWalletId: customerWalletId)
            }

            cashbackSubject.send(cashback)
        }
    }

    func resumeActiveIssueOrderPolling() async {
        await resumeIssuePollingProcessor.execute { @MainActor [weak self] in
            guard let self else { return }

            let localOrdersBeforeFetch = activeIssueOrdersSubject.value
            let trackableTypes = TangemPayOrderType.cardIssueFamily + TangemPayOrderType.tariffPlanTransitionFamily

            let bffActiveOrders: [TangemPayOrderResponse]
            do {
                bffActiveOrders = try await customerService.findOrders(
                    types: trackableTypes,
                    statuses: [.new, .processing]
                )
            } catch {
                VisaLogger.error("Failed to restore in-flight issue-order polling", error: error)
                return
            }

            let bffOrderIds = Set(bffActiveOrders.map(\.id))
            let staleIds = localOrdersBeforeFetch.map(\.id).filter { !bffOrderIds.contains($0) }
            if !staleIds.isEmpty {
                staleIds.forEach { self.activeIssueOrderEventsSubject.send(.remove(id: $0)) }
                orderStatusPollingService.cancel()
            }

            guard let order = bffActiveOrders.mostRecentByUpdatedAt else { return }
            activeIssueOrderEventsSubject.send(.upsert(order))
            startAdditionalCardIssueTracking(orderId: order.id)
        }
    }

    func issueAdditionalCard() async throws -> TangemPayOrderResponse {
        let info = customerInfoSubject.value
        guard let customerWalletAddress = info.paymentAccount?.customerWalletAddress else {
            throw TangemPayAccountError.missingPaymentAccountAddress
        }

        guard let offerData = offersSubject.value.first(where: { $0.type.isAdditionalCardIssue })?.data else {
            throw TangemPayAccountError.missingCardIssueOffer
        }

        let idempotencyKey = TangemPayIdempotencyKey.make(
            info.id,
            offerData.orderType,
            offerData.specificationName,
            customerWalletAddress,
            String(info.cardProductInstances.filter { $0.status == .active }.count)
        )

        let existing = try await orderResolver.findActiveCardIssueOrder()
        let order: TangemPayOrderResponse
        if let existing {
            order = existing
        } else {
            let request = TangemPayPlaceOrderRequest(
                type: offerData.orderType,
                customerWalletAddress: customerWalletAddress,
                specificationName: offerData.specificationName
            )
            order = try await orderResolver.placeOrder(request: request, idempotencyKey: idempotencyKey)
        }
        activeIssueOrderEventsSubject.send(.upsert(order))
        runTask { [weak self] in
            await self?.loadCustomerInfo()
        }
        startAdditionalCardIssueTracking(orderId: order.id)
        return order
    }

    func cancelAwaitingDepositOrder() async throws {
        guard let orderId = activeIssueOrdersSubject.value.first(where: { $0.isAwaitingDeposit })?.id else {
            return
        }

        let transitions = try await customerService.getTariffPlanTransitions()
        let isBasicFallbackAvailable = transitions.contains { $0.tariffPlan.type == Self.basicTariffPlanType }

        pendingTransitionCancellation = isBasicFallbackAvailable
            ? .cancelAndFallbackToBasic(orderId: orderId)
            : .plainCancel(orderId: orderId)

        do {
            try await customerService.cancelOrder(orderId: orderId)
        } catch {
            pendingTransitionCancellation = nil
            await loadCustomerInfo()
            throw error
        }
    }

    func checkFailedToIssueState() async {
        guard activeCards.isEmpty else { return }

        let orders: [TangemPayOrderResponse]
        do {
            orders = try await customerService.findOrders(
                types: TangemPayOrderType.cardIssueFamily,
                statuses: []
            )
        } catch {
            VisaLogger.error("Failed to check card-issue order history", error: error)
            return
        }

        guard orders.isNotEmpty, orders.allConforms({ $0.status == .canceled }) else { return }

        firstCardIssueFailedSubject.send(())
    }
}

// MARK: - TangemPayAwaitingDepositCanceller

extension TangemPayAccount: TangemPayAwaitingDepositCanceller {}

// MARK: - TangemPayCashbackDataProviding

extension TangemPayAccount: TangemPayCashbackDataProviding {
    func getCashbackHistory(months: Int) async throws(TangemPayAPIServiceError) -> TangemPayCashbackHistoryResponse {
        try await customerService.getCashbackHistory(months: months)
    }

    func getCashbackPromotions() async throws(TangemPayAPIServiceError) -> TangemPayCashbackPromotionsResponse {
        try await customerService.getCashbackPromotions()
    }

    func getCashbackAccrualsDocs() async throws(TangemPayAPIServiceError) -> TangemPayCashbackAccrualsDocsResponse {
        try await customerService.getCashbackAccrualsDocs()
    }
}

// MARK: - TangemPayTariffPlanSelector

extension TangemPayAccount: TangemPayTariffPlanSelector {
    func getTariffPlanTransitions() async throws -> TangemPayTariffPlanTransitionsResponse {
        try await customerService.getTariffPlanTransitions()
    }

    func selectTariffPlan(
        targetTariffPlanId: String,
        transitionType: TangemPayTariffPlanTransition.TransitionType
    ) async throws {
        switch transitionType {
        case .downgrade:
            try await customerService.requestTariffPlanPendingTransition(pendingTariffPlanId: targetTariffPlanId)

        case .upgrade, .activation:
            let info = customerInfoSubject.value
            guard let customerWalletAddress = info.paymentAccount?.customerWalletAddress else {
                throw TangemPayAccountError.missingPaymentAccountAddress
            }

            let request = TangemPayPlaceOrderRequest(
                targetTariffPlanId: targetTariffPlanId,
                transitionType: transitionType.rawValue,
                customerWalletAddress: customerWalletAddress
            )
            let idempotencyKey = TangemPayIdempotencyKey.make(
                info.id,
                TangemPayOrderType.tariffPlanTransition.rawValue,
                targetTariffPlanId,
                transitionType.rawValue
            )

            _ = try await customerService.placeOrder(request: request, idempotencyKey: idempotencyKey)
        }

        await loadCustomerInfo()
    }

    func cancelTariffPlanPendingTransition() async throws {
        try await customerService.cancelTariffPlanPendingTransition()
        await loadCustomerInfo()
    }
}

private extension TangemPayAccount {
    func makeAwaitingDepositInfo(targetPlanId: String) async -> TangemPayAwaitingDepositInfo? {
        guard let transitions = try? await customerService.getTariffPlanTransitions(),
              let plan = transitions.first(where: { $0.tariffPlan.id == targetPlanId })?.tariffPlan else {
            return nil
        }

        let fallbackPlan = transitions.first(where: { $0.tariffPlan.type == Self.basicTariffPlanType })?.tariffPlan
            ?? customerTariffPlan?.tariffPlan

        guard let fallbackPlan else {
            return nil
        }

        let fee = plan.fees
            .first { $0.type == .recurring }
            .map { BalanceFormatter().formatFiatBalance($0.amount, currencyCode: $0.currency) }

        return TangemPayAwaitingDepositInfo(
            fee: fee,
            planName: plan.name,
            fallbackPlanName: fallbackPlan.name
        )
    }

    func loadCustomerInfoNew() async {
        do throws(TangemPayAPIServiceError) {
            let customerInfo = try await customerService.loadCustomerInfo()
            let updatedCards = rebuildingCards(from: customerInfo, existing: cardsSubject.value)
            activeIssueOrderEventsSubject.send(.pruneAgainst(customerInfo: customerInfo))
            cardsSubject.send(updatedCards)
            customerInfoSubject.send(customerInfo)
            await loadBalance()
        } catch {
            switch error {
            case .unauthorized:
                syncNeededSignalSubject.send(())
            case .moyaError, .apiError, .decodingError, .serverError:
                unavailableSignalSubject.send(())
            }
            VisaLogger.error("Failed to load customer info", error: error)
        }
    }

    func restoreCachedCashback() {
        guard let cached = cashbackCacheStorage.cachedCashbackSummary(
            customerWalletId: customerWalletId
        ) else {
            return
        }

        let cashback = TangemPayCashback(cached)

        guard case .available = cashback else {
            return
        }

        cashbackSubject.send(cashback)
    }

    func observeCardRefreshSignals() {
        cardsSubject
            .map { cards in
                Publishers.MergeMany(cards.map(\.refreshSignal))
            }
            .switchToLatest()
            .sink { [weak self] in
                runTask { await self?.loadCustomerInfo() }
            }
            .store(in: &bag)
    }

    enum ActiveIssueOrderEvent {
        case upsert(TangemPayOrderResponse)
        case remove(id: String)
        case update(TangemPayOrderResponse)
        case pruneAgainst(customerInfo: VisaCustomerInfoResponse)
    }

    func bindActiveIssueOrderEvents() {
        activeIssueOrderEventsSubject
            .scan([TangemPayOrderResponse]()) { current, event in
                switch event {
                case .upsert(let order):
                    var orders = current
                    if let index = orders.firstIndex(where: { $0.id == order.id }) {
                        orders[index] = order
                    } else {
                        orders.append(order)
                    }
                    return orders
                case .remove(let id):
                    return current.filter { $0.id != id }
                case .update(let order):
                    var orders = current
                    guard let index = orders.firstIndex(where: { $0.id == order.id }) else { return current }
                    orders[index] = order
                    return orders
                case .pruneAgainst(let customerInfo):
                    let issuedProductInstanceIds = Set(
                        customerInfo.productInstances.compactMap { $0.cardId != nil ? $0.id : nil }
                    )
                    return current.filter { order in
                        if let targetPlanId = order.targetTariffPlanId, targetPlanId == customerInfo.customerTariffPlan?.tariffPlan.id {
                            return false
                        }
                        guard let pid = order.data?.productInstanceId else { return true }
                        return !issuedProductInstanceIds.contains(pid)
                    }
                }
            }
            .sink { [weak self] in self?.activeIssueOrdersSubject.send($0) }
            .store(in: &bag)
    }

    func bindAwaitingDepositInfo() {
        activeIssueOrdersSubject
            .map { $0.first(where: \.isAwaitingDeposit)?.targetTariffPlanId }
            .removeDuplicates()
            .withWeakCaptureOf(self)
            .map { account, targetPlanId -> AnyPublisher<TangemPayAwaitingDepositInfo?, Never> in
                if let targetPlanId {
                    Future.async { await account.makeAwaitingDepositInfo(targetPlanId: targetPlanId) }
                        .eraseToAnyPublisher()
                } else {
                    .just(output: nil)
                }
            }
            .switchToLatest()
            .sink { [weak self] in self?.awaitingDepositInfoSubject.send($0) }
            .store(in: &bag)
    }

    func absorbCompletedIssueOrder(orderId: String) async {
        await loadCustomerInfo()
        activeIssueOrderEventsSubject.send(.remove(id: orderId))
        await loadOffers()
        cardIssueCompletedSubject.send(())
    }

    func startAdditionalCardIssueTracking(orderId: String) {
        orderStatusPollingService.startOrderStatusPolling(
            orderId: orderId,
            interval: Constants.cardIssuePollInterval,
            onCompleted: { [weak self] in
                runTask {
                    await self?.absorbCompletedIssueOrder(orderId: orderId)
                }
            },
            onCanceled: { [weak self] in
                self?.handleOrderCancellation(orderId: orderId)
            },
            onFailed: { [weak self] error in
                VisaLogger.error("Failed to poll card-issue order status", error: error)
                self?.handleIssueOrderFailure(orderId: orderId)
            },
            onProgress: { [weak self] order in
                self?.activeIssueOrderEventsSubject.send(.update(order))
            }
        )
    }

    private func handleOrderCancellation(orderId: String) {
        if let cancellation = pendingTransitionCancellation, cancellation.orderId == orderId {
            pendingTransitionCancellation = nil
            activeIssueOrderEventsSubject.send(.remove(id: orderId))

            switch cancellation {
            case .cancelAndFallbackToBasic:
                runTask { [weak self] in await self?.placeBasicOrder() }

            case .plainCancel:
                runTask { [weak self] in await self?.account?.refreshState() }
            }
        } else {
            handleIssueOrderFailure(orderId: orderId)
        }
    }

    private func placeBasicOrder() async {
        do {
            guard let basic = try await getTariffPlanTransitions().first(where: { $0.tariffPlan.type == Self.basicTariffPlanType }) else {
                await account?.refreshState()
                return
            }
            try await selectTariffPlan(targetTariffPlanId: basic.tariffPlan.id, transitionType: basic.type)
            await resumeActiveIssueOrderPolling()
        } catch {
            VisaLogger.error("Failed to place Basic order after canceling Plus", error: error)
            await account?.refreshState()
        }
    }

    private func handleIssueOrderFailure(orderId: String) {
        activeIssueOrderEventsSubject.send(.remove(id: orderId))

        guard activeCards.isEmpty else {
            cardIssueFailureSubject.send(())
            return
        }

        runTask { [weak self] in
            await self?.checkFailedToIssueState()
        }
    }

    func rebuildingCards(from customerInfo: VisaCustomerInfoResponse, existing: [TangemPayCard]) -> [TangemPayCard] {
        let bffByCardId: [String: VisaCustomerInfoResponse.ProductInstance] = .init(
            customerInfo.productInstances.compactMap { productInstance in
                productInstance.cardId.map { ($0, productInstance) }
            },
            uniquingKeysWith: { lhs, rhs in lhs.updatedAt > rhs.updatedAt ? lhs : rhs }
        )

        var newCards: [TangemPayCard] = []
        var seenCardIds: Set<String> = []

        for existingCard in existing {
            guard let productInstance = bffByCardId[existingCard.cardId],
                  let cardSnapshot = customerInfo.card(forCardId: existingCard.cardId) else {
                continue
            }
            existingCard.updateSnapshot(productInstance: productInstance, card: cardSnapshot)
            newCards.append(existingCard)
            seenCardIds.insert(existingCard.cardId)
        }

        for productInstance in customerInfo.productInstances {
            guard let cardId = productInstance.cardId,
                  !seenCardIds.contains(cardId),
                  let cardSnapshot = customerInfo.card(forCardId: cardId) else {
                continue
            }
            let newCard = TangemPayCard(
                productInstance: productInstance,
                card: cardSnapshot,
                customerService: customerService
            )
            newCards.append(newCard)
            seenCardIds.insert(cardId)
        }

        return newCards
    }

    enum Constants {
        static let cardIssuePollInterval: TimeInterval = 5
        static let virtualAccountOrderPollInterval: TimeInterval = 5
    }
}
