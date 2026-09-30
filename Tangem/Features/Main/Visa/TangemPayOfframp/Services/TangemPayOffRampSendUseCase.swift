//
//  TangemPayOffRampSendUseCase.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemFoundation
import TangemPay
import TangemVisa

@MainActor
final class TangemPayOffRampSendUseCase {
    private let orderService: any TangemPayOfframpOrderService
    private let orderSigner: any TangemPayOfframpOrderSigning
    private let recentRecipientsStore: TangemPayRecentRecipientsStore

    private var reloadedBankAccountId: String?
    private var sendTask: Task<SendResult, Error>?
    private var signatureRetryContext: SignatureRetryContext?

    init(
        orderService: some TangemPayOfframpOrderService,
        orderSigner: some TangemPayOfframpOrderSigning,
        recentRecipientsStore: TangemPayRecentRecipientsStore
    ) {
        self.orderService = orderService
        self.orderSigner = orderSigner
        self.recentRecipientsStore = recentRecipientsStore
    }

    func send(request: TangemPayPlaceOrderRequest) async throws -> SendResult {
        if let sendTask {
            return try await sendTask.value
        }

        let idempotencyKey = UUID().uuidString

        let task = Task {
            let order = try await placeOrder(request: request, idempotencyKey: idempotencyKey)
            let signature = try await prepareSignature(orderId: order.id, request: request)

            let context = SignatureRetryContext(
                orderId: order.id,
                signature: signature,
                idempotencyKey: idempotencyKey,
                createdAt: order.createdAt ?? Date()
            )
            signatureRetryContext = context

            return try await submitSignature(context: context, canRetry: true)
        }

        sendTask = task

        defer {
            sendTask = nil
        }

        return try await task.value
    }

    func retrySignature() async throws -> SendResult {
        guard let context = signatureRetryContext else {
            throw SendError.generic
        }

        signatureRetryContext = nil

        return try await submitSignature(context: context, canRetry: false)
    }
}

// MARK: - Place Order

private extension TangemPayOffRampSendUseCase {
    func placeOrder(
        request: TangemPayPlaceOrderRequest,
        idempotencyKey: String
    ) async throws -> TangemPayOrderResponse {
        let order: TangemPayOrderResponse

        do {
            order = try await orderService.placeOrder(request: request, idempotencyKey: idempotencyKey)
        } catch {
            VisaLogger.error("Failed to place Tangem Pay off-ramp order", error: error)
            reset()
            throw Self.placeOrderError(error)
        }

        reloadRecipientsIfNeeded(order, request: request)
        return order
    }

    static func placeOrderError(_ error: any Error) -> SendError {
        guard let apiError = error as? TangemPayAPIServiceError else {
            return .generic
        }

        return apiError.apiErrorCode == TangemPayAPIError.Code.bankOfframpUnsupportedConfiguration
            ? .unavailableRegion
            : .generic
    }
}

// MARK: - Awaiting signature

private extension TangemPayOffRampSendUseCase {
    func awaitSignatureStep(
        orderId: String,
        request: TangemPayPlaceOrderRequest
    ) async throws -> TangemPayOrderResponse.Data.WithdrawData {
        let polling = PollingSequence(
            interval: Constants.pollInterval,
            request: { [orderService] in
                try await orderService.getOrder(id: orderId)
            }
        )

        let deadline = Date().addingTimeInterval(Constants.pollTimeout)

        for await result in polling {
            switch result {
            case .success(let order):
                reloadRecipientsIfNeeded(order, request: request)

                if order.isAwaitingSignature {
                    guard let withdrawData = order.data?.withdrawData else {
                        VisaLogger.warning("Tangem Pay off-ramp order \(order.id) is awaiting a signature without withdraw data")
                        throw SendError.generic
                    }

                    return withdrawData
                }

                switch order.status {
                case .new, .processing:
                    break
                case .completed, .canceled, .undefined:
                    VisaLogger.warning(
                        "Tangem Pay off-ramp order \(orderId) reached the terminal status \(order.status.rawValue)"
                    )
                    throw SendError.generic
                }

            case .failure(let error):
                VisaLogger.error("Failed to poll Tangem Pay off-ramp order \(orderId)", error: error)
                throw SendError.generic
            }

            guard Date() < deadline else {
                VisaLogger.warning("Tangem Pay off-ramp order \(orderId) did not reach the signature step in time")
                throw SendError.cancelled
            }
        }

        throw SendError.generic
    }
}

// MARK: - Signing

private extension TangemPayOffRampSendUseCase {
    func prepareSignature(orderId: String, request: TangemPayPlaceOrderRequest) async throws -> String {
        do {
            let withdrawData = try await awaitSignatureStep(orderId: orderId, request: request)
            let payload = TangemPayWithdrawPreSignature(withdrawData)

            guard let expectation = TangemPayOfframpPreSignatureVerifier.Expectation(request: request) else {
                VisaLogger.warning("Tangem Pay off-ramp order \(orderId) request lacks the amount, network or asset")
                throw SendError.generic
            }

            return try await orderSigner.signature(for: payload, expecting: expectation)
        } catch {
            await cancelOrder(id: orderId)
            reset()
            throw Self.signatureStepError(error)
        }
    }

    func submitSignature(context: SignatureRetryContext, canRetry: Bool) async throws -> SendResult {
        do {
            try await orderService.sendSignature(
                orderId: context.orderId,
                signature: context.signature,
                idempotencyKey: context.idempotencyKey
            )

            reset()

            return SendResult(orderId: context.orderId, createdAt: context.createdAt)
        } catch {
            VisaLogger.error("Failed to submit the Tangem Pay off-ramp signature", error: error)
            throw SendError.signatureSubmission(canRetry: canRetry)
        }
    }

    static func signatureStepError(_ error: any Error) -> SendError {
        if let sendError = error as? SendError {
            return sendError
        }

        return error.isCancellationError ? .cancelled : .generic
    }
}

// MARK: - Recent recipient

private extension TangemPayOffRampSendUseCase {
    func reloadRecipientsIfNeeded(
        _ order: TangemPayOrderResponse,
        request: TangemPayPlaceOrderRequest
    ) {
        guard let bankAccountId = order.data?.bankAccountId ?? request.data.bankAccountId,
              reloadedBankAccountId != bankAccountId
        else {
            return
        }

        reloadedBankAccountId = bankAccountId
        recentRecipientsStore.reload()
    }
}

// MARK: - Order cancellation

private extension TangemPayOffRampSendUseCase {
    func cancelOrder(id: String) async {
        do {
            _ = try await orderService.cancelOrder(id: id)
        } catch {
            VisaLogger.error("Failed to cancel Tangem Pay off-ramp order \(id)", error: error)
        }
    }

    func reset() {
        reloadedBankAccountId = nil
        signatureRetryContext = nil
    }
}

// MARK: - Result

extension TangemPayOffRampSendUseCase {
    struct SendResult {
        let orderId: String
        let createdAt: Date
    }
}

// MARK: - Signature retry context

private extension TangemPayOffRampSendUseCase {
    struct SignatureRetryContext {
        let orderId: String
        let signature: String
        let idempotencyKey: String
        let createdAt: Date
    }
}

// MARK: - Error

extension TangemPayOffRampSendUseCase {
    enum SendError: LocalizedError {
        case unavailableRegion
        case signatureSubmission(canRetry: Bool)
        case cancelled
        case generic
    }
}

// MARK: - Constants

private extension TangemPayOffRampSendUseCase {
    enum Constants {
        static let pollInterval: TimeInterval = 3
        static let pollTimeout: TimeInterval = 60
    }
}
