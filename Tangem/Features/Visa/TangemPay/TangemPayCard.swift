//
//  TangemPayCard.swift
//  TangemApp
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemFoundation
import TangemPay
import TangemVisa

final class TangemPayCard: Identifiable {
    var id: String { cardId }
    let cardId: String
    let paymentAccountId: String

    var productInstance: VisaCustomerInfoResponse.ProductInstance { snapshotSubject.value.productInstance }
    var card: VisaCustomerInfoResponse.Card { snapshotSubject.value.card }

    var displayName: String { productInstance.displayName }
    var cardNumberEnd: String { card.cardNumberEnd }

    var snapshotPublisher: AnyPublisher<Snapshot, Never> {
        snapshotSubject.eraseToAnyPublisher()
    }

    var displayNamePublisher: AnyPublisher<String, Never> {
        snapshotSubject
            .map(\.productInstance.displayName)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var cardLimitPublisher: AnyPublisher<Int, Never> {
        snapshotSubject
            .map { $0.productInstance.actualCardLimit?.amount ?? 0 }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var statusPublisher: AnyPublisher<VisaCustomerInfoResponse.ProductStatus, Never> {
        snapshotSubject
            .map(\.productInstance.status)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var isIssuing: Bool {
        productInstance.status == .new || productInstance.status == .activating
    }

    var isReissuingPublisher: AnyPublisher<Bool, Never> {
        isReissuingSubject.eraseToAnyPublisher()
    }

    var isReissuing: Bool {
        isReissuingSubject.value
    }

    var isFreezingUnfreezingPublisher: AnyPublisher<Bool, Never> {
        isFreezingUnfreezingSubject.eraseToAnyPublisher()
    }

    var isFreezingUnfreezing: Bool {
        isFreezingUnfreezingSubject.value
    }

    var cardLimit: Int {
        productInstance.actualCardLimit?.amount ?? 0
    }

    var adminCardLimit: Int {
        productInstance.adminCardLimit.amount
    }

    var isPinSet: Bool {
        card.isPinSet
    }

    private let snapshotSubject: CurrentValueSubject<Snapshot, Never>
    private let isReissuingSubject = CurrentValueSubject<Bool, Never>(false)
    private let isFreezingUnfreezingSubject = CurrentValueSubject<Bool, Never>(false)

    // Operation state that requires atomic check-and-set. MainActor-isolated so all reads/writes
    // serialize automatically — no NSLock needed, and the compiler enforces it.
    @MainActor private var pendingFreezingResetCancellable: AnyCancellable?
    @MainActor private var renameInFlight = false
    @MainActor private var setLimitInFlight = false

    let customerService: any CustomerInfoManagementService
    private let orderStatusPollingService: TangemPayOrderStatusPollingService

    let refreshSignal: PassthroughSubject<Void, Never> = .init()

    init(
        productInstance: VisaCustomerInfoResponse.ProductInstance,
        card: VisaCustomerInfoResponse.Card,
        customerService: any CustomerInfoManagementService
    ) {
        cardId = card.id
        paymentAccountId = productInstance.paymentAccountId
        self.customerService = customerService
        orderStatusPollingService = TangemPayOrderStatusPollingService(customerService: customerService)
        snapshotSubject = .init(Snapshot(productInstance: productInstance, card: card))
    }

    func updateSnapshot(productInstance: VisaCustomerInfoResponse.ProductInstance, card: VisaCustomerInfoResponse.Card) {
        snapshotSubject.send(Snapshot(productInstance: productInstance, card: card))
    }

    // MARK: - Operations

    //
    // All mutating operations are `@MainActor`-isolated. This serializes their check-and-set
    // guards (against `isFreezingUnfreezingSubject` / `isReissuingSubject` / per-op `inFlight`
    // flags) without explicit locking, and gives the compiler enough information to reject any
    // racy access at build time.

    @MainActor
    func freeze() async throws {
        guard !isFreezingUnfreezingSubject.value, !isReissuingSubject.value else {
            throw TangemPayCardError.operationBusy
        }
        isFreezingUnfreezingSubject.send(true)

        let response: TangemPayFreezeUnfreezeResponse
        do {
            response = try await customerService.freeze(cardId: cardId)
        } catch {
            isFreezingUnfreezingSubject.send(false)
            throw error
        }

        switch response.status {
        case .completed, .canceled:
            scheduleFreezingStateResetOnNextSnapshot()
            refreshSignal.send(())
        case .new, .processing:
            startFreezeUnfreezeOrderPolling(orderId: response.orderId)
        case .failed, .undefined:
            isFreezingUnfreezingSubject.send(false)
            throw TangemPayCardError.operationFailed
        }
    }

    @MainActor
    func unfreeze() async throws {
        guard !isFreezingUnfreezingSubject.value, !isReissuingSubject.value else {
            throw TangemPayCardError.operationBusy
        }
        isFreezingUnfreezingSubject.send(true)

        let response: TangemPayFreezeUnfreezeResponse
        do {
            response = try await customerService.unfreeze(cardId: cardId)
        } catch {
            isFreezingUnfreezingSubject.send(false)
            throw error
        }

        switch response.status {
        case .completed, .canceled:
            scheduleFreezingStateResetOnNextSnapshot()
            refreshSignal.send(())
        case .new, .processing:
            startFreezeUnfreezeOrderPolling(orderId: response.orderId)
        case .failed, .undefined:
            isFreezingUnfreezingSubject.send(false)
            throw TangemPayCardError.operationFailed
        }
    }

    func getPin() async throws -> String {
        let publicKey = try await RainCryptoUtilities
            .getRainRSAPublicKey(
                for: FeatureStorage.instance.visaAPIType
            )

        let (secretKey, sessionId) = try RainCryptoUtilities
            .generateSecretKeyAndSessionId(
                publicKey: publicKey
            )

        let response = try await customerService.getPin(cardId: cardId, sessionId: sessionId)
        let decryptedBlock = try RainCryptoUtilities.decryptSecret(
            base64Secret: response.secret,
            base64Iv: response.iv,
            secretKey: secretKey
        )

        return try RainCryptoUtilities.decryptPinBlock(
            encryptedBlock: decryptedBlock
        )
    }

    @MainActor
    @discardableResult
    func updateDisplayName(_ name: String) async throws -> VisaCustomerInfoResponse.ProductInstance {
        guard !renameInFlight else {
            throw TangemPayCardError.operationBusy
        }
        renameInFlight = true
        defer { renameInFlight = false }

        let pi = try await customerService.updateCardDisplayName(cardId: cardId, name)
        refreshSignal.send(())
        return pi
    }

    @MainActor
    @discardableResult
    func setLimit(_ amount: Int) async throws -> VisaCustomerInfoResponse.ProductInstance {
        guard !setLimitInFlight else {
            throw TangemPayCardError.operationBusy
        }
        setLimitInFlight = true
        defer { setLimitInFlight = false }

        let pi = try await customerService.setCardLimit(cardId: cardId, amount: amount)
        refreshSignal.send(())
        return pi
    }

    @MainActor
    func reissue() async throws {
        guard !isFreezingUnfreezingSubject.value, !isReissuingSubject.value else {
            throw TangemPayCardError.operationBusy
        }
        isReissuingSubject.send(true)

        let response: TangemPayReissueCardResponse
        do {
            response = try await customerService.reissueCard(cardId: cardId)
        } catch {
            isReissuingSubject.send(false)
            throw error
        }

        startReissueOrderTracking(orderId: response.orderId)
    }

    @MainActor
    private func startReissueOrderTracking(orderId: String) {
        orderStatusPollingService.startOrderStatusPolling(
            orderId: orderId,
            interval: Constants.reissueOrderPollInterval,
            onCompleted: { [weak self] in
                self?.isReissuingSubject.send(false)
                self?.refreshSignal.send(())
            },
            onCanceled: { [weak self] in
                self?.isReissuingSubject.send(false)
                self?.refreshSignal.send(())
            },
            onFailed: { [weak self] error in
                VisaLogger.error("Failed to poll reissue order status", error: error)
                self?.isReissuingSubject.send(false)
                self?.refreshSignal.send(())
            }
        )
    }

    @MainActor
    private func startFreezeUnfreezeOrderPolling(orderId: String) {
        orderStatusPollingService.startOrderStatusPolling(
            orderId: orderId,
            interval: Constants.freezeUnfreezeOrderPollInterval,
            onCompleted: { [weak self] in
                self?.scheduleFreezingStateResetOnNextSnapshot()
                self?.refreshSignal.send(())
            },
            onCanceled: { [weak self] in
                self?.scheduleFreezingStateResetOnNextSnapshot()
                self?.refreshSignal.send(())
            },
            onFailed: { [weak self] error in
                VisaLogger.error("Failed to poll freeze/unfreeze order status", error: error)
                self?.scheduleFreezingStateResetOnNextSnapshot()
                self?.refreshSignal.send(())
            }
        )
    }

    @MainActor
    private func scheduleFreezingStateResetOnNextSnapshot() {
        // The sink closure only touches the thread-safe `isFreezingUnfreezingSubject` — no
        // `self` capture is needed for the reset, so no isolation hop is required when the
        // snapshot fires. Replacing `pendingFreezingResetCancellable` here implicitly cancels
        // any previously scheduled reset (Combine releases the old `AnyCancellable`).
        pendingFreezingResetCancellable = snapshotSubject
            .dropFirst()
            .first()
            .sink { [isFreezingUnfreezingSubject] _ in
                isFreezingUnfreezingSubject.send(false)
            }
    }
}

extension TangemPayCard {
    struct Snapshot {
        let productInstance: VisaCustomerInfoResponse.ProductInstance
        let card: VisaCustomerInfoResponse.Card
    }
}

enum TangemPayCardError: Error {
    case operationBusy
    case operationFailed
}

private extension TangemPayCard {
    enum Constants {
        static let freezeUnfreezeOrderPollInterval: TimeInterval = 5
        static let reissueOrderPollInterval: TimeInterval = 5
    }
}
