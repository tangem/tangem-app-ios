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
    var cardsPublisher: AnyPublisher<[TangemPayCard], Never> {
        cardsSubject.eraseToAnyPublisher()
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
    let feeRepository: TangemPayFeeRepository

    let userWalletId: UserWalletId
    private(set) weak var account: (any TangemPayAccountModel)?

    private let balancesService: any TangemPayBalancesService
    private let orderStatusPollingService: TangemPayOrderStatusPollingService
    private let orderResolver: TangemPayOrderResolver

    private let customerInfoSubject: CurrentValueSubject<VisaCustomerInfoResponse, Never>
    private let cardsSubject = CurrentValueSubject<[TangemPayCard], Never>([])
    private let offersSubject = CurrentValueSubject<[TangemPayCustomerOffer], Never>([])
    private let activeIssueOrdersSubject = CurrentValueSubject<[TangemPayOrderResponse], Never>([])
    private let cardEntriesSubject = CurrentValueSubject<[TangemPayCardEntry], Never>([])

    private let syncNeededSignalSubject = PassthroughSubject<Void, Never>()
    private let unavailableSignalSubject = PassthroughSubject<Void, Never>()
    private let cardIssueFailureSubject = PassthroughSubject<Void, Never>()

    /// Issue-in-flight state requires atomic check-and-set across `issueAdditionalCard`,
    /// `resumeAdditionalCardIssuePolling`, and the polling-terminal callbacks. MainActor
    /// isolation serializes these without an explicit lock.
    @MainActor private var isIssueInFlight = false

    private var bag = Set<AnyCancellable>()

    init(
        userWalletId: UserWalletId,
        customerInfo: VisaCustomerInfoResponse,
        customerService: any CustomerInfoManagementService,
        balancesService: any TangemPayBalancesService,
        expressCEXTransactionDispatcher: any TransactionDispatcher,
        withdrawAvailabilityProvider: TangemPayWithdrawAvailabilityProvider,
        mainHeaderBalanceProvider: MainHeaderBalanceProvider,
        orderResolver: TangemPayOrderResolver,
        feeRepository: TangemPayFeeRepository,
        account: (any TangemPayAccountModel)?
    ) {
        self.userWalletId = userWalletId
        customerInfoSubject = CurrentValueSubject(customerInfo)
        self.customerService = customerService
        self.balancesService = balancesService
        self.expressCEXTransactionDispatcher = expressCEXTransactionDispatcher
        self.withdrawAvailabilityProvider = withdrawAvailabilityProvider
        // Account owns its own polling service. Sharing with `TangemPayManager` (or with
        // sibling `TangemPayAccount` instances created on pull-to-refresh) caused the old
        // account's `deinit { cancel() }` to silently kill the new account's in-flight poll
        // once the UI's strong reference to the old account finally drained.
        orderStatusPollingService = TangemPayOrderStatusPollingService(customerService: customerService)
        self.mainHeaderBalanceProvider = mainHeaderBalanceProvider
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

    @MainActor
    func loadCustomerInfo() async {
        do throws(TangemPayAPIServiceError) {
            let customerInfo = try await customerService.loadCustomerInfo()
            let prunedOrders = prunedActiveIssueOrders(
                orders: activeIssueOrdersSubject.value,
                against: customerInfo
            )
            let updatedCards = rebuildingCards(from: customerInfo, existing: cardsSubject.value)
            activeIssueOrdersSubject.send(prunedOrders)
            cardsSubject.send(updatedCards)
            customerInfoSubject.send(customerInfo)
            publishCardEntries()
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

    @MainActor
    func resumeAdditionalCardIssuePolling() async {
        // Snapshot BEFORE the BFF call: a concurrent `issueAdditionalCard` may append a new
        // order while `findOrders` is in flight, and that new order must NOT be pruned (it
        // post-dates BFF's view and could be missing from `findOrders` due to eventual
        // consistency).
        let localOrdersBeforeFetch = activeIssueOrdersSubject.value

        let bffActiveOrders: [TangemPayOrderResponse]
        do {
            bffActiveOrders = try await customerService.findOrders(
                types: TangemPayOrderType.cardIssueFamily,
                statuses: [.new, .processing]
            )
        } catch {
            VisaLogger.error("Failed to restore in-flight card-issue polling", error: error)
            return
        }

        pruneStaleLocalIssueOrders(in: localOrdersBeforeFetch, against: bffActiveOrders)

        guard let order = bffActiveOrders.mostRecentByUpdatedAt else { return }
        upsertActiveIssueOrder(order)
        startTrackingIfIdle(orderId: order.id)
    }

    @MainActor
    func issueAdditionalCard() async throws -> TangemPayOrderResponse {
        guard !isIssueInFlight else {
            throw TangemPayCardError.operationBusy
        }
        isIssueInFlight = true

        let info = customerInfoSubject.value
        guard let customerWalletAddress = info.paymentAccount?.customerWalletAddress else {
            isIssueInFlight = false
            throw TangemPayAccountError.missingPaymentAccountAddress
        }

        guard let offerData = offersSubject.value.first(where: { $0.type.isAdditionalCardIssue })?.data else {
            isIssueInFlight = false
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
            // Reuse a matching active order if BFF already has one (`findActiveOrder` failures
            // are swallowed — placing fresh is safe because the idempotency key dedupes server-side).
            let existing = try? await orderResolver.findActiveOrder(types: TangemPayOrderType.cardIssueFamily) { order in
                order.type == offerData.orderType
                    && order.data?.specificationName == offerData.specificationName
                    && order.data?.customerWalletAddress == customerWalletAddress
            }
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
            upsertActiveIssueOrder(order)
            runTask { [weak self] in
                await self?.loadCustomerInfo()
            }
            startAdditionalCardIssueTracking(orderId: order.id)
            return order
        } catch {
            isIssueInFlight = false
            throw error
        }
    }

    func card(cardId: String) -> TangemPayCard? {
        cards.first { $0.cardId == cardId }
    }

    deinit {
        orderStatusPollingService.cancel()
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

    var pendingProductInstances: [VisaCustomerInfoResponse.ProductInstance] {
        customerInfoSubject.value.productInstances.filter { $0.cardId == nil }
    }

    /// Inserts a new order or replaces an existing one (matched by `id`) with fresh data.
    /// Both code paths emit a single subject update.
    @MainActor
    func upsertActiveIssueOrder(_ order: TangemPayOrderResponse) {
        var orders = activeIssueOrdersSubject.value
        if let index = orders.firstIndex(where: { $0.id == order.id }) {
            orders[index] = order
        } else {
            orders.append(order)
        }
        activeIssueOrdersSubject.send(orders)
        publishCardEntries()
    }

    @MainActor
    func removeActiveIssueOrder(id: String) {
        var orders = activeIssueOrdersSubject.value
        orders.removeAll { $0.id == id }
        activeIssueOrdersSubject.send(orders)
        publishCardEntries()
    }

    /// Update-only counterpart to `upsertActiveIssueOrder` — used by `onProgress` so a tick
    /// arriving after reconciliation removed the order doesn't resurrect it.
    @MainActor
    func updateActiveIssueOrder(_ order: TangemPayOrderResponse) {
        var orders = activeIssueOrdersSubject.value
        guard let index = orders.firstIndex(where: { $0.id == order.id }) else { return }
        orders[index] = order
        activeIssueOrdersSubject.send(orders)
        publishCardEntries()
    }

    /// Removes locally tracked orders that BFF no longer considers active (FR-MOB-ORDER-001 /
    /// FR-MOB-ORDER-004). If anything was reconciled away, cancels the polling task and clears
    /// `isIssueInFlight` so the user can immediately start a new issue without waiting for the
    /// next polling tick. The polling service stays silent on external cancel — that's why
    /// `isIssueInFlight` is cleared here at the call site rather than via an `onCanceled`
    /// callback.
    @MainActor
    func pruneStaleLocalIssueOrders(
        in localOrders: [TangemPayOrderResponse],
        against bffActiveOrders: [TangemPayOrderResponse]
    ) {
        let bffOrderIds = Set(bffActiveOrders.map(\.id))
        let staleIds = localOrders.map(\.id).filter { !bffOrderIds.contains($0) }
        guard !staleIds.isEmpty else { return }

        staleIds.forEach { removeActiveIssueOrder(id: $0) }
        orderStatusPollingService.cancel()
        isIssueInFlight = false
    }

    /// Starts tracking the given order only if no other issue is currently in flight.
    @MainActor
    func startTrackingIfIdle(orderId: String) {
        guard !isIssueInFlight else { return }
        isIssueInFlight = true
        startAdditionalCardIssueTracking(orderId: orderId)
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

    @MainActor
    func absorbCompletedIssueOrder(orderId: String) async {
        await loadCustomerInfo()
        removeActiveIssueOrder(id: orderId)
        await loadOffers()
    }

    @MainActor
    func startAdditionalCardIssueTracking(orderId: String) {
        orderStatusPollingService.startOrderStatusPolling(
            orderId: orderId,
            interval: Constants.cardIssuePollInterval,
            onCompleted: { [weak self] in
                self?.isIssueInFlight = false
                runTask {
                    await self?.absorbCompletedIssueOrder(orderId: orderId)
                }
            },
            onCanceled: { [weak self] in
                guard let self else { return }
                isIssueInFlight = false
                // `onCanceled` only fires here when BFF returns status `.canceled` — external
                // cancellation via `service.cancel()` is silent. The `wasStillTracked` check
                // guards against a tight race where reconciliation removed the order locally
                // just before this BFF response arrived; in that case the user already saw the
                // reconciliation outcome and we suppress the redundant "Something went wrong".
                let wasStillTracked = activeIssueOrdersSubject.value.contains { $0.id == orderId }
                removeActiveIssueOrder(id: orderId)
                if wasStillTracked {
                    cardIssueFailureSubject.send(())
                }
            },
            onFailed: { [weak self] error in
                VisaLogger.error("Failed to poll additional-card-issue order status", error: error)
                guard let self else { return }
                isIssueInFlight = false
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
                customerService: customerService
            )
            newCards.append(newCard)
            seenCardIds.insert(cardId)
        }

        return newCards
    }
}
