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
    private let dateProvider: any DateProvider

    nonisolated static let paymentTimeout: TimeInterval = 100

    // MARK: - Init

    init(
        statusProvider: any CollectiblesPurchaseStatusProvider,
        opener: any CollectiblesPackOpener,
        delayProvider: any PollDelayProvider,
        dateProvider: any DateProvider
    ) {
        self.statusProvider = statusProvider
        self.opener = opener
        self.delayProvider = delayProvider
        self.dateProvider = dateProvider
    }

    // MARK: - Methods

    func awaitPayment(txID: String, createdAt: Date?, isTurboModeOn: Bool) async throws -> Payment {
        let checksLimit = paymentChecksLimit(createdAt: createdAt)
        let polling = PollingSequence(
            interval: Constants.retryInterval,
            request: { [statusProvider] in
                try await statusProvider.load(txID: txID, includesAutoBuyback: isTurboModeOn)
            },
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

            if checksCount >= checksLimit {
                throw CollectiblesPackPurchaseError.paymentTimedOut
            }
        }

        throw CancellationError()
    }

    func open(txID: String, isTurboModeOn: Bool) async throws -> CollectiblesWonCard? {
        try await retrying(
            attempts: Constants.openAttemptsCount,
            exhausted: .openFailed,
            failureMessage: "Collectibles pack \(txID) failed to open"
        ) {
            let transaction = try await opener.open(txID: txID, includesAutoBuyback: isTurboModeOn)
            try Self.throwIfClosed(transaction)

            return Self.outcome(of: transaction.status) == .opened ? .done(transaction.wonCard) : .retry
        }
    }

    func awaitWonCard(txID: String, isTurboModeOn: Bool) async throws -> CollectiblesWonCard {
        try await retrying(
            attempts: Constants.prizeDeliveryChecksCount,
            exhausted: .prizeNotDelivered,
            failureMessage: "Collectibles pack \(txID) prize delivery check failed"
        ) {
            let transaction = try await statusProvider.load(txID: txID, includesAutoBuyback: isTurboModeOn)
            try Self.throwIfClosed(transaction)

            return transaction.wonCard.map { .done($0) } ?? .retry
        }
    }

    func checkPurchaseIsClosed(txID: String) async throws -> Bool {
        guard let status = try await currentStatus(txID: txID) else {
            return false
        }

        switch Self.outcome(of: status) {
        case .failed, .autoSold:
            return true
        case .pending, .paid, .opened, .halted:
            return false
        }
    }

    func currentStatus(txID: String) async throws -> CollectiblesPurchaseStatus? {
        do {
            return try await statusProvider.load(txID: txID, includesAutoBuyback: false).status
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            CollectiblesLogger.error("Collectibles purchase \(txID) status check failed", error: error)
            return nil
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
        let wonCard: CollectiblesWonCard?
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
        case .packPurchased, .unknown:
            .paid
        case .paused:
            .halted
        case .autoBuybacked:
            .autoSold
        case .expired, .refunded, .packOpeningError, .manuallyBuybacked:
            .failed
        case .created, .waitingTxHash, .purchaseTxHash, .waitingForPayment:
            .pending
        }
    }

    func paymentChecksLimit(createdAt: Date?) -> Int {
        guard let createdAt else {
            return Constants.paymentChecksCount
        }

        let timeLeft = Self.paymentTimeout - dateProvider.now.timeIntervalSince(createdAt)
        let checksLeft = Int((timeLeft / Constants.retryInterval).rounded(.up))

        return min(Constants.paymentChecksCount, max(1, checksLeft))
    }

    static func throwIfClosed(_ transaction: CollectiblesPurchaseTransaction) throws {
        switch outcome(of: transaction.status) {
        case .halted:
            throw CollectiblesPackPurchaseError.packUnopened
        case .failed:
            throw CollectiblesPackPurchaseError.paymentFailed(transaction.status)
        case .autoSold:
            throw AutoSold(amount: transaction.buybackAmount, wonCard: transaction.wonCard)
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
            } catch let error as CollectiblesPackOpeningError {
                throw error
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
        static let paymentChecksCount = Int(CollectiblesPurchaseTracker.paymentTimeout / retryInterval)
        static let openAttemptsCount = 5
        static let prizeDeliveryChecksCount = 15
    }
}
