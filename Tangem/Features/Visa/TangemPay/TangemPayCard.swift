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

    var productInstance: VisaCustomerInfoResponse.PendingOrActiveProductInstance { snapshotSubject.value.productInstance }
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

    let customerService: any CustomerInfoManagementService
    private let orderStatusPollingService: TangemPayOrderStatusPollingService
    private let operationGate: TangemPayOperationGate

    let refreshSignal: PassthroughSubject<Void, Never> = .init()

    init?(
        productInstance: VisaCustomerInfoResponse.PendingOrActiveProductInstance,
        card: VisaCustomerInfoResponse.Card,
        customerService: any CustomerInfoManagementService,
        operationGate: TangemPayOperationGate
    ) {
        guard let cardId = card.id else { return nil }
        self.cardId = cardId
        paymentAccountId = productInstance.paymentAccountId
        self.customerService = customerService
        orderStatusPollingService = TangemPayOrderStatusPollingService(customerService: customerService)
        self.operationGate = operationGate
        snapshotSubject = .init(Snapshot(productInstance: productInstance, card: card))
    }

    func updateSnapshot(productInstance: VisaCustomerInfoResponse.PendingOrActiveProductInstance, card: VisaCustomerInfoResponse.Card) {
        snapshotSubject.send(Snapshot(productInstance: productInstance, card: card))
    }

    // MARK: - Operations

    func freeze() async throws {
        guard operationGate.acquire(.freeze(cardId: cardId)) else {
            throw TangemPayCardError.operationBusy
        }

        let response: TangemPayFreezeUnfreezeResponse
        do {
            response = try await customerService.freeze(cardId: cardId)
        } catch {
            operationGate.release(.freeze(cardId: cardId))
            throw error
        }

        switch response.status {
        case .completed, .canceled:
            operationGate.release(.freeze(cardId: cardId))
            refreshSignal.send(())
        case .new, .processing:
            startFreezeUnfreezeOrderPolling(orderId: response.orderId, operation: .freeze(cardId: cardId))
        }
    }

    func unfreeze() async throws {
        guard operationGate.acquire(.unfreeze(cardId: cardId)) else {
            throw TangemPayCardError.operationBusy
        }

        let response: TangemPayFreezeUnfreezeResponse
        do {
            response = try await customerService.unfreeze(cardId: cardId)
        } catch {
            operationGate.release(.unfreeze(cardId: cardId))
            throw error
        }

        switch response.status {
        case .completed, .canceled:
            operationGate.release(.unfreeze(cardId: cardId))
            refreshSignal.send(())
        case .new, .processing:
            startFreezeUnfreezeOrderPolling(orderId: response.orderId, operation: .unfreeze(cardId: cardId))
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
        guard operationGate.acquire(.rename(cardId: cardId)) else {
            throw TangemPayCardError.operationBusy
        }
        defer { operationGate.release(.rename(cardId: cardId)) }

        let pi = try await customerService.updateCardDisplayName(cardId: cardId, name)
        refreshSignal.send(())
        return pi
    }

    @discardableResult
    func setLimit(_ amount: Int) async throws -> VisaCustomerInfoResponse.ProductInstance {
        guard operationGate.acquire(.setLimit(cardId: cardId)) else {
            throw TangemPayCardError.operationBusy
        }
        defer { operationGate.release(.setLimit(cardId: cardId)) }

        let pi = try await customerService.setCardLimit(cardId: cardId, amount: amount)
        refreshSignal.send(())
        return pi
    }

    func reissue() async throws {
        guard operationGate.acquire(.reissue(cardId: cardId)) else {
            throw TangemPayCardError.operationBusy
        }

        let response: TangemPayReissueCardResponse
        do {
            response = try await customerService.reissueCard(cardId: cardId)
        } catch {
            operationGate.release(.reissue(cardId: cardId))
            throw error
        }

        startReissueOrderTracking(orderId: response.orderId)
    }

    private func startReissueOrderTracking(orderId: String) {
        isReissuingSubject.send(true)

        orderStatusPollingService.startOrderStatusPolling(
            orderId: orderId,
            interval: Constants.reissueOrderPollInterval,
            onCompleted: { [operationGate, cardId, weak self] in
                operationGate.release(.reissue(cardId: cardId))
                self?.isReissuingSubject.send(false)
                self?.refreshSignal.send(())
            },
            onCanceled: { [operationGate, cardId, weak self] in
                operationGate.release(.reissue(cardId: cardId))
                self?.isReissuingSubject.send(false)
            },
            onFailed: { [operationGate, cardId, weak self] error in
                VisaLogger.error("Failed to poll reissue order status", error: error)
                operationGate.release(.reissue(cardId: cardId))
                self?.isReissuingSubject.send(false)
            }
        )
    }

    private func startFreezeUnfreezeOrderPolling(orderId: String, operation: TangemPayOperationGate.Operation) {
        orderStatusPollingService.startOrderStatusPolling(
            orderId: orderId,
            interval: Constants.freezeUnfreezeOrderPollInterval,
            onCompleted: { [operationGate, weak self] in
                operationGate.release(operation)
                self?.refreshSignal.send(())
            },
            onCanceled: { [operationGate] in
                operationGate.release(operation)
            },
            onFailed: { [operationGate] error in
                VisaLogger.error("Failed to poll freeze/unfreeze order status", error: error)
                operationGate.release(operation)
            }
        )
    }
}

extension TangemPayCard {
    struct Snapshot {
        let productInstance: VisaCustomerInfoResponse.PendingOrActiveProductInstance
        let card: VisaCustomerInfoResponse.Card
    }
}

enum TangemPayCardError: Error {
    case operationBusy
}

private extension TangemPayCard {
    enum Constants {
        static let freezeUnfreezeOrderPollInterval: TimeInterval = 5
        static let reissueOrderPollInterval: TimeInterval = 5
    }
}
