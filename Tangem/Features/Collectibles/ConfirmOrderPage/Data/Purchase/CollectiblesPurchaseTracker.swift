//
//  CollectiblesPurchaseTracker.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemCollectibles
import TangemFoundation

@MainActor
struct CollectiblesPurchaseTracker {
    // MARK: - Properties

    private let statusProvider: any CollectiblesPurchaseStatusProvider
    private let opener: any CollectiblesPackOpener
    private let delayProvider: any PollDelayProvider

    // MARK: - Init

    init(
        statusProvider: any CollectiblesPurchaseStatusProvider,
        opener: any CollectiblesPackOpener,
        delayProvider: any PollDelayProvider
    ) {
        self.statusProvider = statusProvider
        self.opener = opener
        self.delayProvider = delayProvider
    }

    // MARK: - Methods

    func awaitPayment(txID: String) async throws -> Payment {
        let polling = PollingSequence(
            interval: Constants.retryInterval,
            request: { [statusProvider] in try await statusProvider.load(txID: txID) },
            delayProvider: delayProvider
        )

        var checksCount = 0

        for await result in polling {
            checksCount += 1

            switch result {
            case .success(let transaction):
                try Self.throwIfClosed(transaction)

                switch Self.outcome(of: transaction.status) {
                case .paid:
                    return .paid
                case .opened:
                    return .opened(transaction.wonCard)
                case .pending, .halted, .failed, .autoSold:
                    break
                }
            case .failure(let error):
                CollectiblesLogger.error("Collectibles purchase \(txID) status check failed", error: error)
            }

            if checksCount >= Constants.paymentChecksCount {
                throw CollectiblesPackPurchaseError.paymentTimedOut
            }
        }

        throw CancellationError()
    }

    func open(txID: String) async throws -> CollectiblesWonCard? {
        try await retrying(
            attempts: Constants.openAttemptsCount,
            exhausted: .openFailed,
            failureMessage: "Collectibles pack \(txID) failed to open"
        ) {
            let transaction = try await opener.open(txID: txID)
            try Self.throwIfClosed(transaction)

            return Self.outcome(of: transaction.status) == .opened ? .done(transaction.wonCard) : .retry
        }
    }

    func awaitWonCard(txID: String) async throws -> CollectiblesWonCard {
        try await retrying(
            attempts: Constants.prizeDeliveryChecksCount,
            exhausted: .prizeNotDelivered,
            failureMessage: "Collectibles pack \(txID) prize delivery check failed"
        ) {
            let transaction = try await statusProvider.load(txID: txID)
            try Self.throwIfClosed(transaction)

            return transaction.wonCard.map { .done($0) } ?? .retry
        }
    }
}

// MARK: - Payment

extension CollectiblesPurchaseTracker {
    enum Payment {
        case paid
        case opened(CollectiblesWonCard?)
    }

    struct AutoSold: Error {
        let amount: Decimal?
    }
}

// MARK: - Private logic

private extension CollectiblesPurchaseTracker {
    enum Attempt<Value> {
        case done(Value)
        case retry
    }

    enum Outcome {
        case pending
        case paid
        case opened
        case halted
        case failed
        case autoSold
    }

    static func outcome(of status: CollectiblesPurchaseStatus) -> Outcome {
        switch status {
        case .packOpened, .nftReceived:
            .opened
        case .packPurchased, .packOpeningError, .unknown:
            .paid
        case .paused:
            .halted
        case .autoBuybacked:
            .autoSold
        case .expired, .refunded, .manuallyBuybacked:
            .failed
        case .created, .waitingTxHash, .purchaseTxHash, .waitingForPayment:
            .pending
        }
    }

    static func throwIfClosed(_ transaction: CollectiblesPurchaseTransaction) throws {
        switch outcome(of: transaction.status) {
        case .halted:
            throw CollectiblesPackPurchaseError.packUnopened
        case .failed:
            throw CollectiblesPackPurchaseError.paymentFailed(transaction.status)
        case .autoSold:
            throw AutoSold(amount: transaction.buybackAmount)
        case .pending, .paid, .opened:
            break
        }
    }

    func retrying<Value>(
        attempts: Int,
        exhausted: CollectiblesPackPurchaseError,
        failureMessage: String,
        _ attempt: () async throws -> Attempt<Value>
    ) async throws -> Value {
        for index in 0 ..< attempts {
            if index > 0 {
                try await delayProvider.wait(for: Constants.retryInterval)
            }

            do {
                if case .done(let value) = try await attempt() {
                    return value
                }
            } catch let error as CollectiblesPackPurchaseError {
                throw error
            } catch let sold as AutoSold {
                throw sold
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                CollectiblesLogger.error("\(failureMessage), attempt \(index + 1)", error: error)
            }
        }

        throw exhausted
    }
}

// MARK: - Constants

private extension CollectiblesPurchaseTracker {
    enum Constants {
        static let retryInterval: TimeInterval = 2
        static let paymentChecksCount = 50
        static let openAttemptsCount = 5
        static let prizeDeliveryChecksCount = 15
    }
}
