//
//  TangemPayWithdrawExchangeSender.swift
//  TangemApp
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import TangemExpress
import TangemFoundation
import TangemPay
import TangemVisa

final class TangemPayWithdrawExchangeSender {
    @Injected(\.tangemPayPendingWithdrawExchangesStore)
    private var store: TangemPayPendingWithdrawExchangesStore

    @Injected(\.userWalletRepository)
    private var userWalletRepository: UserWalletRepository

    private let userWalletId: UserWalletId
    private let customerService: any CustomerInfoManagementService

    private let pollingTasks = OSAllocatedUnfairLock<[String: Task<Void, Never>]>(initialState: [:])
    private var exchangesSubscription: AnyCancellable?

    init(userWalletId: UserWalletId, customerService: any CustomerInfoManagementService) {
        self.userWalletId = userWalletId
        self.customerService = customerService

        bind()
    }

    deinit {
        pollingTasks.withLock { $0.values.forEach { $0.cancel() } }
    }
}

// MARK: - Private

private extension TangemPayWithdrawExchangeSender {
    enum Outcome {
        case transactionHash(String)
        case unresolved
        case canceled
        case expired
    }

    func bind() {
        exchangesSubscription = store.exchangesPublisher(userWalletId: userWalletId)
            .sink { [weak self] _ in
                self?.startPollingStoredExchanges()
            }
    }

    func startPollingStoredExchanges() {
        store.exchanges(userWalletId: userWalletId).forEach(startPolling)
    }

    func startPolling(_ exchange: TangemPayPendingWithdrawExchange) {
        pollingTasks.withLock { pollingTasks in
            guard pollingTasks[exchange.orderId] == nil else {
                return
            }

            pollingTasks[exchange.orderId] = Task { [weak self, customerService] in
                let outcome = await Self.awaitTransactionHash(
                    orderId: exchange.orderId,
                    deadline: exchange.createdAt.addingTimeInterval(Constants.pollingTimeout),
                    customerService: customerService
                )

                await self?.complete(exchange, outcome: outcome)
            }
        }
    }

    func complete(_ exchange: TangemPayPendingWithdrawExchange, outcome: Outcome) async {
        defer { pollingTasks.withLock { $0[exchange.orderId] = nil } }

        switch outcome {
        case .unresolved:
            return

        case .canceled, .expired:
            store.remove(orderId: exchange.orderId, userWalletId: userWalletId)

        case .transactionHash(let transactionHash):
            let sentResult = ExpressTransactionSentResult(
                hash: transactionHash,
                source: exchange.tokenItem.expressCurrency,
                address: exchange.fromAddress,
                data: exchange.transactionData
            )

            try? await makeExpressAPIProvider().exchangeSent(result: sentResult)

            VisaLogger.info("Withdraw order \(exchange.orderId): exchange-sent delivered to Express")
            store.remove(orderId: exchange.orderId, userWalletId: userWalletId)
        }
    }

    static func awaitTransactionHash(orderId: String, deadline: Date, customerService: any CustomerInfoManagementService) async -> Outcome {
        VisaLogger.info("Withdraw order \(orderId): polling for the transaction hash until \(deadline)")

        try? await Task.sleep(for: .seconds(Constants.initialPollingDelay))

        let pollingSequence = PollingSequence(
            interval: Constants.pollingInterval,
            request: {
                try await customerService.getOrder(orderId: orderId)
            }
        )

        var attempt = 0

        for await response in pollingSequence {
            attempt += 1
            let order = response.value

            if case .failure(let error) = response {
                VisaLogger.error("Withdraw order \(orderId): attempt \(attempt) failed", error: error)
            }

            if let transactionHash = order?.data?.transactionHash?.nilIfEmpty {
                VisaLogger.info("Withdraw order \(orderId): attempt \(attempt) received the transaction hash \(transactionHash)")
                return .transactionHash(transactionHash)
            }

            if order?.status == .canceled {
                VisaLogger.info("Withdraw order \(orderId): attempt \(attempt) found the order canceled")
                return .canceled
            }

            guard Date() < deadline else {
                VisaLogger.info("Withdraw order \(orderId): no transaction hash after \(attempt) attempts, the deadline has passed")
                return .expired
            }

            if let order {
                VisaLogger.info("Withdraw order \(orderId): attempt \(attempt) has no transaction hash yet, order status \(order.status)")
            }
        }

        VisaLogger.info("Withdraw order \(orderId): polling was cancelled after \(attempt) attempts")
        return .unresolved
    }

    func makeExpressAPIProvider() -> ExpressAPIProvider {
        let refcode = userWalletRepository.models
            .first(where: { $0.userWalletId == userWalletId })?
            .refcodeProvider?
            .getRefcode()

        return ExpressAPIProviderFactory().makeExpressAPIProvider(userWalletId: userWalletId, refcode: refcode)
    }
}

// MARK: - Constants

private extension TangemPayWithdrawExchangeSender {
    enum Constants {
        static let initialPollingDelay: TimeInterval = 3
        static let pollingInterval: TimeInterval = 3
        static let pollingTimeout: TimeInterval = 15 * 60
    }
}
