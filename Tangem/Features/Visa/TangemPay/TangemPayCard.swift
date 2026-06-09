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

    var inflightLifecycleOperationPublisher: AnyPublisher<LifecycleOperation?, Never> {
        inflightLifecycleOperationSubject.eraseToAnyPublisher()
    }

    var isReissuingPublisher: AnyPublisher<Bool, Never> {
        inflightLifecycleOperationSubject
            .map { $0 == .reissue }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var isReissuing: Bool {
        inflightLifecycleOperationSubject.value == .reissue
    }

    var isClosingPublisher: AnyPublisher<Bool, Never> {
        inflightLifecycleOperationSubject
            .map { $0 == .close }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var isClosing: Bool {
        inflightLifecycleOperationSubject.value == .close
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
    private let inflightLifecycleOperationSubject = CurrentValueSubject<LifecycleOperation?, Never>(nil)

    private var pendingFreezingResetCancellable: AnyCancellable?

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
        orderStatusPollingService = TangemPayOrderStatusPollingService(customerService: customerService, multipleCardsEnabled: true)
        snapshotSubject = .init(Snapshot(productInstance: productInstance, card: card))
    }

    func updateSnapshot(productInstance: VisaCustomerInfoResponse.ProductInstance, card: VisaCustomerInfoResponse.Card) {
        snapshotSubject.send(Snapshot(productInstance: productInstance, card: card))
    }

    // MARK: - Operations

    @MainActor
    func freeze() async throws {
        guard inflightLifecycleOperationSubject.value == nil else {
            throw TangemPayCardError.operationBusy
        }
        inflightLifecycleOperationSubject.send(.freeze)

        let response: TangemPayFreezeUnfreezeResponse
        do {
            response = try await customerService.freeze(cardId: cardId)
        } catch {
            inflightLifecycleOperationSubject.send(nil)
            throw error
        }

        switch response.status {
        case .completed, .canceled:
            scheduleFreezingStateResetOnNextSnapshot()
            refreshSignal.send(())
        case .new, .processing:
            startFreezeUnfreezeOrderPolling(orderId: response.orderId)
        case .failed, .undefined:
            inflightLifecycleOperationSubject.send(nil)
            throw TangemPayCardError.operationFailed
        }
    }

    @MainActor
    func unfreeze() async throws {
        guard inflightLifecycleOperationSubject.value == nil else {
            throw TangemPayCardError.operationBusy
        }
        inflightLifecycleOperationSubject.send(.unfreeze)

        let response: TangemPayFreezeUnfreezeResponse
        do {
            response = try await customerService.unfreeze(cardId: cardId)
        } catch {
            inflightLifecycleOperationSubject.send(nil)
            throw error
        }

        switch response.status {
        case .completed, .canceled:
            scheduleFreezingStateResetOnNextSnapshot()
            refreshSignal.send(())
        case .new, .processing:
            startFreezeUnfreezeOrderPolling(orderId: response.orderId)
        case .failed, .undefined:
            inflightLifecycleOperationSubject.send(nil)
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

    @discardableResult
    func updateDisplayName(_ name: String) async throws -> VisaCustomerInfoResponse.ProductInstance {
        let pi = try await customerService.updateCardDisplayName(cardId: cardId, name)
        refreshSignal.send(())
        return pi
    }

    @discardableResult
    func setLimit(_ amount: Int) async throws -> VisaCustomerInfoResponse.ProductInstance {
        let pi = try await customerService.setCardLimit(cardId: cardId, amount: amount)
        refreshSignal.send(())
        return pi
    }

    @MainActor
    func close() async throws {
        guard inflightLifecycleOperationSubject.value == nil else {
            throw TangemPayCardError.operationBusy
        }
        inflightLifecycleOperationSubject.send(.close)

        let response: TangemPayCloseCardResponse
        do {
            response = try await customerService.closeCard(cardId: cardId)
        } catch {
            inflightLifecycleOperationSubject.send(nil)
            throw error
        }

        switch response.status {
        case .completed, .canceled:
            inflightLifecycleOperationSubject.send(nil)
            refreshSignal.send(())
        case .new, .processing:
            startCloseCardOrderPolling(orderId: response.orderId)
        case .failed, .undefined:
            inflightLifecycleOperationSubject.send(nil)
            throw TangemPayCardError.operationFailed
        }
    }

    @MainActor
    func reissue() async throws {
        guard inflightLifecycleOperationSubject.value == nil else {
            throw TangemPayCardError.operationBusy
        }
        inflightLifecycleOperationSubject.send(.reissue)

        let response: TangemPayReissueCardResponse
        do {
            response = try await customerService.reissueCard(cardId: cardId)
        } catch {
            inflightLifecycleOperationSubject.send(nil)
            throw error
        }

        startReissueOrderTracking(orderId: response.orderId)
    }

    private func startReissueOrderTracking(orderId: String) {
        orderStatusPollingService.startOrderStatusPolling(
            orderId: orderId,
            interval: Constants.reissueOrderPollInterval,
            onCompleted: { [weak self] in
                self?.inflightLifecycleOperationSubject.send(nil)
                self?.refreshSignal.send(())
            },
            onCanceled: { [weak self] in
                self?.inflightLifecycleOperationSubject.send(nil)
                self?.refreshSignal.send(())
            },
            onFailed: { [weak self] error in
                VisaLogger.error("Failed to poll reissue order status", error: error)
                self?.inflightLifecycleOperationSubject.send(nil)
                self?.refreshSignal.send(())
            }
        )
    }

    private func startCloseCardOrderPolling(orderId: String) {
        orderStatusPollingService.startOrderStatusPolling(
            orderId: orderId,
            interval: Constants.closeCardOrderPollInterval,
            onCompleted: { [weak self] in
                self?.inflightLifecycleOperationSubject.send(nil)
                self?.refreshSignal.send(())
            },
            onCanceled: { [weak self] in
                self?.inflightLifecycleOperationSubject.send(nil)
                self?.refreshSignal.send(())
            },
            onFailed: { [weak self] error in
                VisaLogger.error("Failed to poll close card order status", error: error)
                self?.inflightLifecycleOperationSubject.send(nil)
                self?.refreshSignal.send(())
            }
        )
    }

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

    private func scheduleFreezingStateResetOnNextSnapshot() {
        pendingFreezingResetCancellable = snapshotSubject
            .dropFirst()
            .first()
            .receiveOnMain()
            .sink { [weak self] _ in
                self?.inflightLifecycleOperationSubject.send(nil)
            }
    }
}

extension TangemPayCard {
    enum LifecycleOperation {
        case freeze
        case unfreeze
        case reissue
        case close
    }

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
        static let closeCardOrderPollInterval: TimeInterval = 5
    }
}
