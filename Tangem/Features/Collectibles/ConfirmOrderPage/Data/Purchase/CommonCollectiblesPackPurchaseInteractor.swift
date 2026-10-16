//
//  CommonCollectiblesPackPurchaseInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemCollectibles
import TangemFoundation

@MainActor
final class CommonCollectiblesPackPurchaseInteractor {
    // MARK: - Properties

    private let generator: any CollectiblesPurchaseGenerator
    private let sentReporter: any CollectiblesPurchaseSentReporter
    private let statusProvider: any CollectiblesPurchaseStatusProvider
    private let opener: any CollectiblesPackOpener
    private let delayProvider: any PollDelayProvider

    private var signer: any CollectiblesPurchaseSigner

    // [REDACTED_TODO_COMMENT]
    private var pendingOrder: Order?
    private var activePurchase: ActivePurchase?
    private var stepHandler: ((CollectiblesPackPurchaseStep) -> Void)?
    private var currentStep: CollectiblesPackPurchaseStep?

    // MARK: - Init

    init(
        generator: any CollectiblesPurchaseGenerator,
        signer: any CollectiblesPurchaseSigner,
        sentReporter: any CollectiblesPurchaseSentReporter,
        statusProvider: any CollectiblesPurchaseStatusProvider,
        opener: any CollectiblesPackOpener,
        delayProvider: any PollDelayProvider = TaskSleepPollDelayProvider()
    ) {
        self.generator = generator
        self.signer = signer
        self.sentReporter = sentReporter
        self.statusProvider = statusProvider
        self.opener = opener
        self.delayProvider = delayProvider
    }

    // MARK: - Methods

    func update(signer: any CollectiblesPurchaseSigner) {
        self.signer = signer
    }
}

// MARK: - CollectiblesPackPurchaseInteractor protocol conformance

extension CommonCollectiblesPackPurchaseInteractor: CollectiblesPackPurchaseInteractor {
    func hasUnfinishedPurchase(machineID: String) -> Bool {
        activePurchase?.machineID == machineID || pendingOrder?.machineID == machineID
    }

    func purchase(
        machineID: String,
        price: Decimal,
        platformFee: Decimal,
        turboMode: CollectiblesTurboMode,
        onStep: @escaping (CollectiblesPackPurchaseStep) -> Void
    ) async throws -> CollectiblesWonCard {
        if let activePurchase {
            guard activePurchase.machineID == machineID else {
                throw CollectiblesPackPurchaseError.anotherPurchaseInProgress
            }

            stepHandler = onStep

            if let currentStep {
                onStep(currentStep)
            }

            return try await activePurchase.task.value
        }

        stepHandler = onStep

        let task = Task {
            defer { finishActivePurchase() }

            return try await runPurchase(
                machineID: machineID,
                price: price,
                platformFee: platformFee,
                turboMode: turboMode
            )
        }
        activePurchase = ActivePurchase(machineID: machineID, task: task)

        return try await task.value
    }
}

// MARK: - Private logic

private extension CommonCollectiblesPackPurchaseInteractor {
    struct ActivePurchase {
        let machineID: String
        let task: Task<CollectiblesWonCard, any Error>
    }

    struct Order {
        let machineID: String
        let txID: String
        let signedPurchase: CollectiblesSignedPurchase
        var stage: Stage
    }

    enum Stage {
        case signed
        case sent
        case reported
        case paid
        case opened
    }

    enum Outcome {
        case pending
        case paid
        case opened
        case failed
    }

    func runPurchase(
        machineID: String,
        price: Decimal,
        platformFee: Decimal,
        turboMode: CollectiblesTurboMode
    ) async throws -> CollectiblesWonCard {
        report(.generating)

        var order = try await pendingOrStartedOrder(
            machineID: machineID,
            price: price,
            platformFee: platformFee,
            turboMode: turboMode
        )

        if order.stage == .signed || order.stage == .sent || order.stage == .reported {
            report(.confirming)
        }

        if order.stage == .signed {
            try await send(order)
            order.stage = .sent
            pendingOrder = order
        }

        if order.stage == .sent {
            _ = try await sentReporter.report(txID: order.txID, txHash: order.signedPurchase.signature)
            order.stage = .reported
            pendingOrder = order
        }

        if order.stage == .reported {
            try await awaitPayment(of: order)
            order.stage = .paid
            pendingOrder = order
        }

        report(.opening)

        if order.stage == .paid {
            try await open(order)
            order.stage = .opened
            pendingOrder = order
        }

        let wonCard = try await awaitWonCard(of: order)
        // [REDACTED_TODO_COMMENT]
        pendingOrder = nil

        return wonCard
    }

    func report(_ step: CollectiblesPackPurchaseStep) {
        currentStep = step
        stepHandler?(step)
    }

    func finishActivePurchase() {
        activePurchase = nil
        stepHandler = nil
        currentStep = nil
    }

    func pendingOrStartedOrder(
        machineID: String,
        price: Decimal,
        platformFee: Decimal,
        turboMode: CollectiblesTurboMode
    ) async throws -> Order {
        // [REDACTED_TODO_COMMENT]
        if let pendingOrder {
            guard pendingOrder.machineID != machineID else {
                return pendingOrder
            }

            guard pendingOrder.stage == .signed else {
                throw CollectiblesPackPurchaseError.anotherPurchaseInProgress
            }
        }

        guard let addresses = signer.purchaseAddresses else {
            throw CollectiblesPackPurchaseError.accountNotReady
        }

        let generated = try await generator.generate(
            machineID: machineID,
            fromAddress: addresses.payer,
            toAddress: addresses.prizeRecipient,
            turboMode: turboMode
        )
        let confirmedPrice = CollectiblesConfirmedPrice(
            amount: try Self.baseUnits(of: price),
            feeAmount: try Self.baseUnits(of: platformFee)
        )
        let signedPurchase = try await signer.signPurchase(generated.purchase, confirmedPrice: confirmedPrice)

        let order = Order(machineID: machineID, txID: generated.txID, signedPurchase: signedPurchase, stage: .signed)
        pendingOrder = order

        return order
    }

    func send(_ order: Order) async throws {
        do throws(CollectiblesPurchaseError) {
            try await signer.sendPurchase(order.signedPurchase)
        } catch {
            switch error {
            case .transactionExpired, .sendOutcomeUnknown:
                CollectiblesLogger.info("Collectibles purchase \(order.txID) send outcome is unknown, the backend status decides")
            case .rejected:
                throw error
            }
        }
    }

    func awaitPayment(of order: Order) async throws {
        let polling = PollingSequence(
            interval: Constants.retryInterval,
            request: { [statusProvider] in try await statusProvider.load(txID: order.txID) },
            delayProvider: delayProvider
        )

        var checksCount = 0

        for await result in polling {
            checksCount += 1

            switch result {
            case .success(let transaction):
                let status = transaction.status

                switch Self.outcome(of: status) {
                // [REDACTED_TODO_COMMENT]
                case .paid, .opened:
                    return
                case .failed:
                    pendingOrder = nil
                    throw CollectiblesPackPurchaseError.paymentFailed(status)
                case .pending:
                    break
                }
            case .failure(let error):
                CollectiblesLogger.error("Collectibles purchase \(order.txID) status check failed", error: error)
            }

            if checksCount >= Constants.paymentChecksCount {
                throw CollectiblesPackPurchaseError.paymentTimedOut
            }
        }

        throw CancellationError()
    }

    func open(_ order: Order) async throws {
        for attempt in 0 ..< Constants.openAttemptsCount {
            if attempt > 0 {
                try await delayProvider.wait(for: Constants.retryInterval)
            }

            do {
                let status = try await opener.open(txID: order.txID)

                switch Self.outcome(of: status) {
                case .opened:
                    return
                case .failed:
                    pendingOrder = nil
                    throw CollectiblesPackPurchaseError.paymentFailed(status)
                case .pending, .paid:
                    break
                }
            } catch let error as CollectiblesPackPurchaseError {
                throw error
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                CollectiblesLogger.error("Collectibles pack \(order.txID) failed to open, attempt \(attempt + 1)", error: error)
            }
        }

        throw CollectiblesPackPurchaseError.openFailed
    }

    func awaitWonCard(of order: Order) async throws -> CollectiblesWonCard {
        for attempt in 0 ..< Constants.prizeDeliveryChecksCount {
            if attempt > 0 {
                try await delayProvider.wait(for: Constants.retryInterval)
            }

            do {
                let transaction = try await statusProvider.load(txID: order.txID)

                if let wonCard = transaction.wonCard {
                    return wonCard
                }

                if Self.outcome(of: transaction.status) == .failed {
                    pendingOrder = nil
                    throw CollectiblesPackPurchaseError.paymentFailed(transaction.status)
                }
            } catch let error as CollectiblesPackPurchaseError {
                throw error
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                CollectiblesLogger.error("Collectibles pack \(order.txID) prize delivery check failed", error: error)
            }
        }

        throw CollectiblesPackPurchaseError.prizeNotDelivered
    }

    static func outcome(of status: CollectiblesPurchaseStatus) -> Outcome {
        switch status {
        case .packOpened, .nftReceived, .autoBuybacked, .manuallyBuybacked:
            .opened
        case .packPurchased, .packOpeningError:
            .paid
        case .expired, .refunded:
            .failed
        case .created, .waitingTxHash, .purchaseTxHash, .waitingForPayment, .paused, .unknown:
            .pending
        }
    }

    static func baseUnits(of amount: Decimal) throws -> UInt64 {
        let units = amount
            .moveRight(decimals: CollectiblesChainEnvironment.usdcTokenItem.decimalCount)
            .rounded(roundingMode: .plain)

        guard units >= 0, units <= Decimal(UInt64.max) else {
            throw CollectiblesPackPurchaseError.invalidPrice
        }

        return units.uint64Value
    }
}

// MARK: - Constants

private extension CommonCollectiblesPackPurchaseInteractor {
    enum Constants {
        static let retryInterval: TimeInterval = 2
        static let paymentChecksCount = 50
        static let openAttemptsCount = 5
        static let prizeDeliveryChecksCount = 15
    }
}
