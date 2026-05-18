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
    static let maxCardsAllowed = 3

    var paymentTokenItem: TokenItem {
        TangemPayUtilities.usdcTokenItem
    }

    var cardsPublisher: AnyPublisher<[TangemPayCard], Never> {
        cardsSubject.eraseToAnyPublisher()
    }

    var cardEntries: [TangemPayCardEntry] {
        TangemPayCardEntry.build(
            cards: cardsSubject.value,
            pendingProductInstances: customerInfoSubject.value.productInstances.filter { $0.cardId == nil },
            activeIssueOrders: activeIssueOrdersSubject.value
        )
    }

    var cardEntriesPublisher: AnyPublisher<[TangemPayCardEntry], Never> {
        Publishers.CombineLatest4(cardsSubject, customerInfoSubject, activeIssueOrdersSubject, anyCardReissuingPublisher)
            .map { cards, info, orders, _ in
                TangemPayCardEntry.build(
                    cards: cards,
                    pendingProductInstances: info.productInstances.filter { $0.cardId == nil },
                    activeIssueOrders: orders
                )
            }
            .eraseToAnyPublisher()
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
    private let activeIssueOrderEventsSubject = PassthroughSubject<ActiveIssueOrderEvent, Never>()
    private let syncNeededSignalSubject = PassthroughSubject<Void, Never>()
    private let unavailableSignalSubject = PassthroughSubject<Void, Never>()
    private let cardIssueFailureSubject = PassthroughSubject<Void, Never>()

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
        orderStatusPollingService = TangemPayOrderStatusPollingService(customerService: customerService)
        self.mainHeaderBalanceProvider = mainHeaderBalanceProvider
        self.orderResolver = orderResolver
        self.feeRepository = feeRepository
        self.account = account

        bindActiveIssueOrderEvents()
        cardsSubject.send(rebuildingCards(from: customerInfo, existing: []))
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
            let updatedCards = rebuildingCards(from: customerInfo, existing: cardsSubject.value)
            activeIssueOrderEventsSubject.send(.pruneAgainst(customerInfo: customerInfo))
            cardsSubject.send(updatedCards)
            customerInfoSubject.send(customerInfo)
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

        let bffOrderIds = Set(bffActiveOrders.map(\.id))
        let staleIds = localOrdersBeforeFetch.map(\.id).filter { !bffOrderIds.contains($0) }
        if !staleIds.isEmpty {
            staleIds.forEach { activeIssueOrderEventsSubject.send(.remove(id: $0)) }
            orderStatusPollingService.cancel()
        }

        guard let order = bffActiveOrders.mostRecentByUpdatedAt else { return }
        activeIssueOrderEventsSubject.send(.upsert(order))
        startAdditionalCardIssueTracking(orderId: order.id)
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
            String(info.productInstances.filter { $0.status == .active }.count)
        )

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
        activeIssueOrderEventsSubject.send(.upsert(order))
        runTask { [weak self] in
            await self?.loadCustomerInfo()
        }
        startAdditionalCardIssueTracking(orderId: order.id)
        return order
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
                        guard let pid = order.data?.productInstanceId else { return true }
                        return !issuedProductInstanceIds.contains(pid)
                    }
                }
            }
            .sink { [weak self] in self?.activeIssueOrdersSubject.send($0) }
            .store(in: &bag)
    }

    func absorbCompletedIssueOrder(orderId: String) async {
        await loadCustomerInfo()
        activeIssueOrderEventsSubject.send(.remove(id: orderId))
        await loadOffers()
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
                guard let self else { return }
                activeIssueOrderEventsSubject.send(.remove(id: orderId))
                cardIssueFailureSubject.send(())
            },
            onFailed: { [weak self] error in
                VisaLogger.error("Failed to poll additional-card-issue order status", error: error)
                guard let self else { return }
                activeIssueOrderEventsSubject.send(.remove(id: orderId))
                cardIssueFailureSubject.send(())
            },
            onProgress: { [weak self] order in
                self?.activeIssueOrderEventsSubject.send(.update(order))
            }
        )
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
}
