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

    private var multipleCardsEnabled: Bool {
        FeatureProvider.isAvailable(.tangemPayMultipleCards)
    }

    var paymentTokenItem: TokenItem {
        TangemPayUtilities.usdcTokenItem
    }

    // MARK: - Multi-card surface

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

    var cardIssueFailureSignal: AnyPublisher<Void, Never> {
        cardIssueFailureSubject.eraseToAnyPublisher()
    }

    var cards: [TangemPayCard] {
        cardsSubject.value
    }

    var activeCards: [TangemPayCard] {
        cardsSubject.value.filter { $0.productInstance.status == .active || $0.productInstance.status == .blocked }
    }

    // MARK: - Legacy single-card surface

    var statusPublisher: AnyPublisher<VisaCustomerInfoResponse.ProductStatus, Never> {
        legacyCustomerInfoSubject
            .map(\.productInstance.status)
            .eraseToAnyPublisher()
    }

    var card: VisaCustomerInfoResponse.Card? {
        legacyCustomerInfoSubject.value.customerInfo.cardIfActiveOrBlocked
    }

    var cardPublisher: AnyPublisher<VisaCustomerInfoResponse.Card?, Never> {
        legacyCustomerInfoSubject
            .map(\.customerInfo.cardIfActiveOrBlocked)
            .eraseToAnyPublisher()
    }

    var cardDisplayNamePublisher: AnyPublisher<String, Never> {
        legacyCustomerInfoSubject
            .map(\.productInstance.displayName)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var cardLimit: Int? {
        legacyCustomerInfoSubject.value.productInstance.actualCardLimit?.amount
    }

    var adminCardLimit: Int {
        legacyCustomerInfoSubject.value.productInstance.adminCardLimit.amount
    }

    var cardLimitPublisher: AnyPublisher<Int?, Never> {
        legacyCustomerInfoSubject
            .map { $0.productInstance.actualCardLimit?.amount }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var isReissuingCardPublisher: AnyPublisher<Bool, Never> {
        isReissuingCardSubject.eraseToAnyPublisher()
    }

    var isReissuingCard: Bool {
        isReissuingCardSubject.value
    }

    var cardId: String {
        legacyCustomerInfoSubject.value.productInstance.cardId ?? ""
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
        multipleCardsEnabled
            ? customerInfoSubject.value.id
            : legacyCustomerInfoSubject.value.customerInfo.id
    }

    var depositAddress: String? {
        multipleCardsEnabled
            ? customerInfoSubject.value.depositAddress
            : legacyCustomerInfoSubject.value.customerInfo.depositAddress
    }

    var isDeactivated: Bool {
        multipleCardsEnabled ? isDeactivatedNew : isDeactivatedLegacy
    }

    private var isDeactivatedNew: Bool {
        let info = customerInfoSubject.value
        if info.state == .former { return true }
        return !info.productInstances.isEmpty &&
            info.productInstances.allSatisfy { $0.status == .deactivated || $0.status == .canceled }
    }

    private var isDeactivatedLegacy: Bool {
        let value = legacyCustomerInfoSubject.value
        return value.customerInfo.state == .former || value.productInstance.status == .deactivated
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

    private let balancesService: any TangemPayBalancesService
    private let orderStatusPollingService: TangemPayOrderStatusPollingService
    private let orderResolver: TangemPayOrderResolver

    private let customerInfoSubject: CurrentValueSubject<VisaCustomerInfoResponse, Never>
    private let legacyCustomerInfoSubject: CurrentValueSubject<(customerInfo: VisaCustomerInfoResponse, productInstance: VisaCustomerInfoResponse.ProductInstance), Never>
    private let cardsSubject = CurrentValueSubject<[TangemPayCard], Never>([])
    private let offersSubject = CurrentValueSubject<[TangemPayCustomerOffer], Never>([])
    private let activeIssueOrdersSubject = CurrentValueSubject<[TangemPayOrderResponse], Never>([])
    private let activeIssueOrderEventsSubject = PassthroughSubject<ActiveIssueOrderEvent, Never>()
    private let syncNeededSignalSubject = PassthroughSubject<Void, Never>()
    private let unavailableSignalSubject = PassthroughSubject<Void, Never>()
    private let isReissuingCardSubject = CurrentValueSubject<Bool, Never>(false)
    private let cardIssueFailureSubject = PassthroughSubject<Void, Never>()

    private var bag = Set<AnyCancellable>()

    init(
        userWalletId: UserWalletId,
        customerInfo: VisaCustomerInfoResponse,
        productInstance: VisaCustomerInfoResponse.ProductInstance,
        customerService: any CustomerInfoManagementService,
        balancesService: any TangemPayBalancesService,
        withdrawTransactionService: any TangemPayWithdrawTransactionService,
        transactionDispatcher: any TransactionDispatcher,
        withdrawAvailabilityProvider: TangemPayWithdrawAvailabilityProvider,
        orderStatusPollingService: TangemPayOrderStatusPollingService,
        mainHeaderBalanceProvider: MainHeaderBalanceProvider,
        orderResolver: TangemPayOrderResolver,
        feeRepository: TangemPayFeeRepository,
        account: (any TangemPayAccountModel)?
    ) {
        self.userWalletId = userWalletId
        customerInfoSubject = CurrentValueSubject(customerInfo)
        legacyCustomerInfoSubject = CurrentValueSubject((customerInfo, productInstance))
        self.customerService = customerService
        self.balancesService = balancesService
        self.withdrawTransactionService = withdrawTransactionService
        self.transactionDispatcher = transactionDispatcher
        self.withdrawAvailabilityProvider = withdrawAvailabilityProvider
        self.orderStatusPollingService = orderStatusPollingService
        self.mainHeaderBalanceProvider = mainHeaderBalanceProvider
        self.orderResolver = orderResolver
        self.feeRepository = feeRepository
        self.account = account

        if multipleCardsEnabled {
            bindActiveIssueOrderEvents()
            cardsSubject.send(rebuildingCards(from: customerInfo, existing: []))
            restoreInFlightCardIssueOrder()
            observeAppLifecycle()
            observeCardRefreshSignals()
        }
    }

    func loadBalance() async {
        await balancesService.loadBalance()
    }

    func loadCustomerInfo() async {
        if multipleCardsEnabled {
            await loadCustomerInfoNew()
        } else {
            await loadCustomerInfoLegacy()
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

// MARK: - Legacy single-card flow

extension TangemPayAccount {
    func getPin() async throws -> String {
        let publicKey = try await RainCryptoUtilities
            .getRainRSAPublicKey(for: FeatureStorage.instance.visaAPIType)

        let (secretKey, sessionId) = try RainCryptoUtilities
            .generateSecretKeyAndSessionId(publicKey: publicKey)

        let response = try await customerService.getPin(sessionId: sessionId)
        let decryptedBlock = try RainCryptoUtilities.decryptSecret(
            base64Secret: response.secret,
            base64Iv: response.iv,
            secretKey: secretKey
        )

        return try RainCryptoUtilities.decryptPinBlock(encryptedBlock: decryptedBlock)
    }

    func freeze() async throws {
        let response = try await customerService.freeze(cardId: cardId)
        switch response.status {
        case .completed, .canceled:
            await loadCustomerInfo()
        case .new, .processing:
            startFreezeUnfreezeOrderStatusPolling(orderId: response.orderId)
        case .failed, .undefined:
            throw TangemPayCardError.operationFailed
        }
    }

    func unfreeze() async throws {
        let response = try await customerService.unfreeze(cardId: cardId)
        switch response.status {
        case .completed, .canceled:
            await loadCustomerInfo()
        case .new, .processing:
            startFreezeUnfreezeOrderStatusPolling(orderId: response.orderId)
        case .failed, .undefined:
            throw TangemPayCardError.operationFailed
        }
    }

    func startReissueOrderTracking(orderId: String) {
        isReissuingCardSubject.send(true)
        startReissueOrderStatusPolling(orderId: orderId)
    }
}

private extension TangemPayAccount {
    func loadCustomerInfoLegacy() async {
        do throws(TangemPayAPIServiceError) {
            let customerInfo = try await customerService.loadCustomerInfo()
            guard let productInstance = customerInfo.productInstance else {
                unavailableSignalSubject.send(())
                VisaLogger.info("Product instance was unexpectedly nil")
                return
            }

            legacyCustomerInfoSubject.send((customerInfo, productInstance))

            if productInstance.status == .active
                || productInstance.status == .deactivated {
                await loadBalance()
            }
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

    func startReissueOrderStatusPolling(orderId: String) {
        orderStatusPollingService.startOrderStatusPolling(
            orderId: orderId,
            interval: Constants.reissueOrderPollInterval,
            onCompleted: { [weak self] in
                runTask {
                    await self?.handleReissueCompleted()
                }
            },
            onCanceled: { [weak self] in
                self?.isReissuingCardSubject.send(false)
            },
            onFailed: { [weak self] error in
                VisaLogger.error("Failed to poll reissue order status", error: error)
                self?.isReissuingCardSubject.send(false)
            }
        )
    }

    func handleReissueCompleted() async {
        await loadCustomerInfo()
        isReissuingCardSubject.send(false)
    }

    func startFreezeUnfreezeOrderStatusPolling(orderId: String) {
        orderStatusPollingService.startOrderStatusPolling(
            orderId: orderId,
            interval: Constants.freezeUnfreezeOrderPollInterval,
            onCompleted: { [weak self] in
                runTask {
                    await self?.loadCustomerInfo()
                }
            },
            onCanceled: {
                // [REDACTED_TODO_COMMENT]
            },
            onFailed: { error in
                VisaLogger.error("Failed to poll order status", error: error)
            }
        )
    }

    func setupBalance() async {
        await balancesService.loadBalance()
    }
}

private extension VisaCustomerInfoResponse {
    var cardIfActiveOrBlocked: VisaCustomerInfoResponse.Card? {
        [.active, .blocked].contains(productInstance?.status)
            ? card
            : nil
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
}

private extension TangemPayAccount {
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
            case .moyaError, .apiError, .decodingError:
                unavailableSignalSubject.send(())
            }
            VisaLogger.error("Failed to load customer info", error: error)
        }
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

    enum Constants {
        static let freezeUnfreezeOrderPollInterval: TimeInterval = 5
        static let reissueOrderPollInterval: TimeInterval = 5
        static let cardIssuePollInterval: TimeInterval = 60
    }
}
