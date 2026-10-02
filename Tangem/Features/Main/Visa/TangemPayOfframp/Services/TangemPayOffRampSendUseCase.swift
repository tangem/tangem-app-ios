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
    private var retryContext: RetryContext?

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
        try await run(request: request, idempotencyKey: UUID().uuidString)
    }

    func retry() async throws -> SendResult {
        guard let context = retryContext else {
            throw SendError.generic
        }

        retryContext = nil

        switch context {
        case .placeOrder(let request, let idempotencyKey):
            return try await run(request: request, idempotencyKey: idempotencyKey)

        case .awaitSignature(let order):
            return try await perform { [self] in
                try await completeOrder(order)
            }
        }
    }

    func abandonRetry() async {
        let context = retryContext
        reset()

        guard case .awaitSignature(let order) = context else {
            return
        }

        await cancelOrder(id: order.id)
    }

    func retrySignature() async throws -> SendResult {
        guard let context = signatureRetryContext else {
            throw SendError.generic
        }

        signatureRetryContext = nil

        return try await submitSignature(context: context, canRetry: false)
    }
}

// MARK: - Run

private extension TangemPayOffRampSendUseCase {
    func run(request: TangemPayPlaceOrderRequest, idempotencyKey: String) async throws -> SendResult {
        try await perform { [self] in
            let order = try await placeOrder(request: request, idempotencyKey: idempotencyKey)

            return try await completeOrder(PlacedOrder(
                id: order.id,
                request: request,
                idempotencyKey: idempotencyKey,
                createdAt: order.createdAt ?? Date()
            ))
        }
    }

    func completeOrder(_ order: PlacedOrder) async throws -> SendResult {
        let signature = try await prepareSignature(order: order)

        let context = SignatureRetryContext(
            orderId: order.id,
            signature: signature,
            idempotencyKey: order.idempotencyKey,
            createdAt: order.createdAt
        )
        signatureRetryContext = context

        return try await submitSignature(context: context, canRetry: true)
    }

    func perform(_ operation: @escaping @MainActor () async throws -> SendResult) async throws -> SendResult {
        if let sendTask {
            return try await sendTask.value
        }

        let task = Task { try await operation() }

        sendTask = task

        defer {
            sendTask = nil
        }

        return try await task.value
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

            let sendError = Self.placeOrderError(error)

            if case .generic = sendError, Self.isRetryable(error) {
                retryContext = .placeOrder(request: request, idempotencyKey: idempotencyKey)
                throw SendError.retryable
            }

            reset()
            throw sendError
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

    static func isRetryable(_ error: any Error) -> Bool {
        guard let apiError = error as? TangemPayAPIServiceError else {
            return false
        }

        switch apiError {
        case .moyaError, .serverError, .apiError:
            return true
        case .unauthorized, .decodingError:
            return false
        }
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
                case .canceled:
                    VisaLogger.warning("Tangem Pay off-ramp order \(orderId) was canceled before the signature step")
                    throw PollingFailure.orderCanceled
                case .completed, .undefined:
                    VisaLogger.warning(
                        "Tangem Pay off-ramp order \(orderId) reached the terminal status \(order.status.rawValue)"
                    )
                    throw SendError.generic
                }

            case .failure(let error):
                VisaLogger.error("Failed to poll Tangem Pay off-ramp order \(orderId)", error: error)

                if Self.isRetryable(error) {
                    throw PollingFailure.technical
                }

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
    func prepareSignature(order: PlacedOrder) async throws -> String {
        do {
            let withdrawData = try await awaitSignatureStep(orderId: order.id, request: order.request)
            let payload = TangemPayWithdrawPreSignature(withdrawData)

            guard let expectation = TangemPayOfframpPreSignatureVerifier.Expectation(request: order.request) else {
                VisaLogger.warning("Tangem Pay off-ramp order \(order.id) request lacks the amount, network or asset")
                throw SendError.generic
            }

            return try await orderSigner.signature(for: payload, expecting: expectation)
        } catch PollingFailure.technical {
            retryContext = .awaitSignature(order)
            throw SendError.retryable
        } catch PollingFailure.orderCanceled {
            reset()
            retryContext = .placeOrder(request: order.request, idempotencyKey: UUID().uuidString)
            throw SendError.retryable
        } catch {
            await cancelOrder(id: order.id)
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
        retryContext = nil
    }
}

// MARK: - Result

extension TangemPayOffRampSendUseCase {
    struct SendResult {
        let orderId: String
        let createdAt: Date
    }
}

// MARK: - Retry contexts

private extension TangemPayOffRampSendUseCase {
    enum RetryContext {
        case placeOrder(request: TangemPayPlaceOrderRequest, idempotencyKey: String)
        case awaitSignature(PlacedOrder)
    }

    struct PlacedOrder {
        let id: String
        let request: TangemPayPlaceOrderRequest
        let idempotencyKey: String
        let createdAt: Date
    }

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
        case retryable
        case signatureSubmission(canRetry: Bool)
        case cancelled
        case generic
    }
}

// MARK: - Polling failure

private extension TangemPayOffRampSendUseCase {
    enum PollingFailure: Error {
        case technical
        case orderCanceled
    }
}

// MARK: - Constants

private extension TangemPayOffRampSendUseCase {
    enum Constants {
        static let pollInterval: TimeInterval = 3
        static let pollTimeout: TimeInterval = 60
    }
}
