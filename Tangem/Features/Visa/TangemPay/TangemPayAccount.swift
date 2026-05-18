//
//  TangemPayAccount.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import UIKit
import TangemFoundation
import TangemPay
import TangemVisa

final class TangemPayAccount {
    var paymentTokenItem: TokenItem {
        TangemPayUtilities.usdcTokenItem
    }

    var cardsPublisher: AnyPublisher<[TangemPayCard], Never> {
        cardsSubject.eraseToAnyPublisher()
    }

    var pendingProductInstancesPublisher: AnyPublisher<[VisaCustomerInfoResponse.ProductInstance], Never> {
        customerInfoSubject
            .map { $0.productInstances.filter { $0.cardId == nil } }
            .eraseToAnyPublisher()
    }

    var pendingProductInstances: [VisaCustomerInfoResponse.ProductInstance] {
        customerInfoSubject.value.productInstances.filter { $0.cardId == nil }
    }

    var activeIssueOrdersPublisher: AnyPublisher<[TangemPayOrderResponse], Never> {
        activeIssueOrdersSubject.eraseToAnyPublisher()
    }

    var activeIssueOrders: [TangemPayOrderResponse] {
        activeIssueOrdersSubject.value
    }

    var cardEntries: [TangemPayCardEntry] {
        cardEntriesSubject.value
    }

    var cardEntriesPublisher: AnyPublisher<[TangemPayCardEntry], Never> {
        cardEntriesSubject.eraseToAnyPublisher()
    }

    var offersPublisher: AnyPublisher<[TangemPayCustomerOffer], Never> {
        offersSubject.eraseToAnyPublisher()
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
                    .prepend(cards.contains { $0.isReissuing })
                    .eraseToAnyPublisher()
            }
            .switchToLatest()
            .eraseToAnyPublisher()
    }

    var syncNeededSignalPublisher: AnyPublisher<Void, Never> {
        syncNeededSignalSubject.eraseToAnyPublisher()
    }

    var unavailableSignalPublisher: AnyPublisher<Void, Never> {
        unavailableSignalSubject.eraseToAnyPublisher()
    }

    var cardIssueFailureSignal: AnyPublisher<Void, Never> {
        cardIssueFailureSubject.eraseToAnyPublisher()
    }

    var customerId: String {
        customerInfoSubject.value.id
    }

    var depositAddress: String? {
        customerInfoSubject.value.depositAddress
    }

    var cards: [TangemPayCard] {
        cardsSubject.value
    }

    var isDeactivated: Bool {
        let info = customerInfoSubject.value
        if info.state == .former { return true }
        return !info.productInstances.isEmpty &&
            info.productInstances.allSatisfy { $0.status == .deactivated || $0.status == .canceled }
    }

    var activeCards: [TangemPayCard] {
        cardsSubject.value.filter { $0.productInstance.status == .active || $0.productInstance.status == .blocked }
    }

    // MARK: - Withdraw

    let expressCEXTransactionDispatcher: TransactionDispatcher
    let withdrawAvailabilityProvider: TangemPayWithdrawAvailabilityProvider

    // MARK: - Balances

    let mainHeaderBalanceProvider: MainHeaderBalanceProvider
    var balancesProvider: TangemPayBalancesProvider { balancesService }

    let customerService: any CustomerInfoManagementService
    let withdrawTransactionService: any TangemPayWithdrawTransactionService
    let feeRepository: TangemPayFeeRepository

    let userWalletId: UserWalletId
    private(set) weak var account: (any TangemPayAccountModel)?

    private let balancesService: any TangemPayBalancesService
    private let orderStatusPollingService: TangemPayOrderStatusPollingService
    private let operationGate: TangemPayOperationGate
    private let orderResolver: TangemPayOrderResolver

    private let customerInfoSubject: CurrentValueSubject<VisaCustomerInfoResponse, Never>
    private let cardsSubject = CurrentValueSubject<[TangemPayCard], Never>([])
    private let offersSubject = CurrentValueSubject<[TangemPayCustomerOffer], Never>([])
    private let activeIssueOrdersSubject = CurrentValueSubject<[TangemPayOrderResponse], Never>([])
    private let cardEntriesSubject = CurrentValueSubject<[TangemPayCardEntry], Never>([])

    private let syncNeededSignalSubject = PassthroughSubject<Void, Never>()
    private let unavailableSignalSubject = PassthroughSubject<Void, Never>()
    private let cardIssueFailureSubject = PassthroughSubject<Void, Never>()

    private let stateLock = NSLock()

    private var bag = Set<AnyCancellable>()

    init(
        userWalletId: UserWalletId,
        customerInfo: VisaCustomerInfoResponse,
        customerService: any CustomerInfoManagementService,
        balancesService: any TangemPayBalancesService,
        withdrawTransactionService: any TangemPayWithdrawTransactionService,
        expressCEXTransactionDispatcher: any TransactionDispatcher,
        withdrawAvailabilityProvider: TangemPayWithdrawAvailabilityProvider,
        orderStatusPollingService: TangemPayOrderStatusPollingService,
        mainHeaderBalanceProvider: MainHeaderBalanceProvider,
        operationGate: TangemPayOperationGate,
        orderResolver: TangemPayOrderResolver,
        feeRepository: TangemPayFeeRepository,
        account: (any TangemPayAccountModel)?
    ) {
        self.userWalletId = userWalletId
        customerInfoSubject = CurrentValueSubject(customerInfo)
        self.customerService = customerService
        self.balancesService = balancesService
        self.withdrawTransactionService = withdrawTransactionService
        self.expressCEXTransactionDispatcher = expressCEXTransactionDispatcher
        self.withdrawAvailabilityProvider = withdrawAvailabilityProvider
        self.orderStatusPollingService = orderStatusPollingService
        self.mainHeaderBalanceProvider = mainHeaderBalanceProvider
        self.operationGate = operationGate
        self.orderResolver = orderResolver
        self.feeRepository = feeRepository
        self.account = account

        cardsSubject.send(rebuildingCards(from: customerInfo, existing: []))
        publishCardEntries()
        restoreInFlightCardIssueOrder()
        observeAppLifecycle()
        observeCardRefreshSignals()
    }

    func loadBalance() async {
        await balancesService.loadBalance()
    }

    func loadCustomerInfo() async {
        do throws(TangemPayAPIServiceError) {
            let customerInfo = try await customerService.loadCustomerInfo()
            stateLock.lock()
            let prunedOrders = prunedActiveIssueOrders(
                orders: activeIssueOrdersSubject.value,
                against: customerInfo
            )
            let updatedCards = rebuildingCards(from: customerInfo, existing: cardsSubject.value)
            activeIssueOrdersSubject.send(prunedOrders)
            cardsSubject.send(updatedCards)
            customerInfoSubject.send(customerInfo)
            publishCardEntries()
            stateLock.unlock()
            await loadBalance()
        } catch {
            switch error {
            case .unauthorized:
                syncNeededSignalSubject.send(())
            case .moyaError, .apiError, .decodingError:
                unavailableSignalSubject.send(())
            }
            VisaLogger.error("Failed to load customer info", error: error)
        }
    }

    func loadOffers() async {
        do {
            let offers = try await customerService.getCustomerOffers()
            offersSubject.send(offers)
        } catch {
            VisaLogger.error("Failed to load TangemPay offers", error: error)
        }
    }

    func resumeAdditionalCardIssuePolling() async {
        // Snapshot BEFORE the BFF call. If `issueAdditionalCard` appends a brand-new order
        // while `findOrders` is in flight, that new order must NOT be considered for removal
        // — it post-dates BFF's view and could be missing from `findOrders` due to eventual
        // consistency. Iterating the snapshot (instead of the live subject) confines removals
        // to orders that existed at request time.
        let localOrdersBeforeFetch = activeIssueOrdersSubject.value

        do {
            let bffActiveOrders = try await customerService.findOrders(
                types: TangemPayOrderType.cardIssueFamily,
                statuses: [.new, .processing]
            )

            // Reconcile local state against BFF — `findOrders` is the source of truth for
            // active orders (FR-MOB-ORDER-001). Without this, an order whose terminal
            // transition was missed locally (e.g. polling didn't fire while backgrounded,
            // or `order.data.productInstanceId` was never populated so `prunedActiveIssueOrders`
            // couldn't match it against the issued PI) lingers in `activeIssueOrdersSubject`
            // and renders as a duplicate "issuing" entry next to the already-issued card.
            //
            // We also cancel the polling task for each removed order. Cancellation triggers
            // the task's `onCanceled` callback, which releases `operationGate.release(.issueCard)`
            // — without this the gate would stay locked until the next polling tick (up to
            // ~1 minute), during which the user couldn't issue another card. The
            // `onCanceled` callback is alert-suppressing when the order is no longer locally
            // tracked, so the user doesn't get a spurious "Something went wrong".
            let bffOrderIds = Set(bffActiveOrders.map(\.id))
            for staleOrder in localOrdersBeforeFetch where !bffOrderIds.contains(staleOrder.id) {
                removeActiveIssueOrder(id: staleOrder.id)
                orderStatusPollingService.cancel(orderId: staleOrder.id)
            }

            guard let order = bffActiveOrders
                .sorted(by: { ($0.updatedAt ?? .distantPast) > ($1.updatedAt ?? .distantPast) })
                .first else { return }
            appendActiveIssueOrder(order)
            updateActiveIssueOrder(order)
            guard operationGate.acquire(.issueCard) else { return }
            startAdditionalCardIssueTracking(orderId: order.id)
        } catch {
            VisaLogger.error("Failed to restore in-flight card-issue polling", error: error)
        }
    }

    func issueAdditionalCard() async throws -> TangemPayOrderResponse {
        guard operationGate.acquire(.issueCard) else {
            throw TangemPayCardError.operationBusy
        }

        let info = customerInfoSubject.value
        guard let customerWalletAddress = info.paymentAccount?.customerWalletAddress else {
            operationGate.release(.issueCard)
            throw TangemPayAccountError.missingPaymentAccountAddress
        }

        guard let offerData = offersSubject.value.first(where: { $0.type.isAdditionalCardIssue })?.data else {
            operationGate.release(.issueCard)
            throw TangemPayAccountError.missingCardIssueOffer
        }

        let idempotencyKey = TangemPayIdempotencyKey.make(
            info.id,
            offerData.orderType,
            offerData.specificationName,
            customerWalletAddress,
            String(info.productInstances.filter { $0.status == .active }.count)
        )

        do {
            let order = try await orderResolver.resolveOrCreateAdditionalCardIssueOrder(
                orderType: offerData.orderType,
                customerWalletAddress: customerWalletAddress,
                specificationName: offerData.specificationName,
                idempotencyKey: idempotencyKey
            )
            appendActiveIssueOrder(order)
            runTask { [weak self] in
                await self?.loadCustomerInfo()
            }
            startAdditionalCardIssueTracking(orderId: order.id)
            return order
        } catch {
            operationGate.release(.issueCard)
            throw error
        }
    }

    func card(cardId: String) -> TangemPayCard? {
        cards.first { $0.cardId == cardId }
    }

    deinit {
        orderStatusPollingService.cancelAll()
    }
}

enum TangemPayAccountError: Error {
    case missingPaymentAccountAddress
    case missingCardIssueOffer
}

// MARK: - Private

private extension TangemPayAccount {
    enum Constants {
        static let cardIssuePollInterval: TimeInterval = 60
    }

    func restoreInFlightCardIssueOrder() {
        runTask { [weak self] in
            await self?.resumeAdditionalCardIssuePolling()
        }
    }

    func observeAppLifecycle() {
        NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                runTask { [weak self] in
                    await self?.loadCustomerInfo()
                    await self?.loadOffers()
                    await self?.resumeAdditionalCardIssuePolling()
                }
            }
            .store(in: &bag)
    }

    /// Re-subscribes whenever the card set changes — any card's `refreshSignal` triggers a
    /// `loadCustomerInfo`. Replaces the per-card cancellable dict that used to be managed
    /// inside `rebuildingCards`.
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

    func appendActiveIssueOrder(_ order: TangemPayOrderResponse) {
        stateLock.lock()
        defer { stateLock.unlock() }
        var orders = activeIssueOrdersSubject.value
        guard !orders.contains(where: { $0.id == order.id }) else { return }
        orders.append(order)
        activeIssueOrdersSubject.send(orders)
        publishCardEntries()
    }

    func removeActiveIssueOrder(id: String) {
        stateLock.lock()
        defer { stateLock.unlock() }
        var orders = activeIssueOrdersSubject.value
        orders.removeAll { $0.id == id }
        activeIssueOrdersSubject.send(orders)
        publishCardEntries()
    }

    func updateActiveIssueOrder(_ order: TangemPayOrderResponse) {
        stateLock.lock()
        defer { stateLock.unlock() }
        var orders = activeIssueOrdersSubject.value
        guard let index = orders.firstIndex(where: { $0.id == order.id }) else { return }
        orders[index] = order
        activeIssueOrdersSubject.send(orders)
        publishCardEntries()
    }

    func prunedActiveIssueOrders(
        orders: [TangemPayOrderResponse],
        against customerInfo: VisaCustomerInfoResponse
    ) -> [TangemPayOrderResponse] {
        guard !orders.isEmpty else { return orders }
        let issuedProductInstanceIds = Set(
            customerInfo.productInstances.compactMap { $0.cardId != nil ? $0.id : nil }
        )
        return orders.filter { order in
            guard let pid = order.data?.productInstanceId else { return true }
            return !issuedProductInstanceIds.contains(pid)
        }
    }

    func publishCardEntries() {
        cardEntriesSubject.send(TangemPayCardEntry.build(
            cards: cardsSubject.value,
            pendingProductInstances: pendingProductInstances,
            activeIssueOrders: activeIssueOrdersSubject.value
        ))
    }

    func absorbCompletedIssueOrder(orderId: String) async {
        await loadCustomerInfo()
        removeActiveIssueOrder(id: orderId)
        await loadOffers()
    }

    func startAdditionalCardIssueTracking(orderId: String) {
        orderStatusPollingService.startOrderStatusPolling(
            orderId: orderId,
            interval: Constants.cardIssuePollInterval,
            onCompleted: { [operationGate, weak self] in
                operationGate.release(.issueCard)
                runTask {
                    await self?.absorbCompletedIssueOrder(orderId: orderId)
                }
            },
            onCanceled: { [operationGate, weak self] in
                operationGate.release(.issueCard)
                guard let self else { return }
                // Suppress the user-facing failure alert if the order was already
                // reconciled away by `resumeAdditionalCardIssuePolling` — the cancel
                // is app-initiated, not a real BFF failure.
                let wasStillTracked = activeIssueOrdersSubject.value.contains { $0.id == orderId }
                removeActiveIssueOrder(id: orderId)
                if wasStillTracked {
                    cardIssueFailureSubject.send(())
                }
            },
            onFailed: { [operationGate, weak self] error in
                operationGate.release(.issueCard)
                VisaLogger.error("Failed to poll additional-card-issue order status", error: error)
                guard let self else { return }
                let wasStillTracked = activeIssueOrdersSubject.value.contains { $0.id == orderId }
                removeActiveIssueOrder(id: orderId)
                if wasStillTracked {
                    cardIssueFailureSubject.send(())
                }
            },
            onProgress: { [weak self] order in
                self?.updateActiveIssueOrder(order)
            }
        )
    }

    /// Preserve the existing card order across `customerInfo` reloads — BFF reorders
    /// `productInstances` after a rename (sorts by `updatedAt`), which would otherwise
    /// cause cards to swap positions in the carousel.
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
                customerService: customerService,
                operationGate: operationGate
            )
            newCards.append(newCard)
            seenCardIds.insert(cardId)
        }

        return newCards
    }
}
