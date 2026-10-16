//
//  RemoteCollectiblesPackPurchaseInteractor.swift
//  Tangem
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import TangemCollectibles
import TangemFoundation

@MainActor
final class RemoteCollectiblesPackPurchaseInteractor {
    // MARK: - Properties

    private let generator: any CollectiblesPurchaseGenerator
    private let sentReporter: any CollectiblesPurchaseSentReporter
    private let tracker: CollectiblesPurchaseTracker

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
        tracker = CollectiblesPurchaseTracker(statusProvider: statusProvider, opener: opener, delayProvider: delayProvider)
    }

    // MARK: - Methods

    func update(signer: any CollectiblesPurchaseSigner) {
        self.signer = signer
    }
}

// MARK: - CollectiblesPackPurchaseInteractor protocol conformance

extension RemoteCollectiblesPackPurchaseInteractor: CollectiblesPackPurchaseInteractor {
    func hasUnfinishedPurchase(machineID: String) -> Bool {
        activePurchase?.machineID == machineID || pendingOrder?.machineID == machineID
    }

    func purchase(
        machineID: String,
        price: Decimal,
        platformFee: Decimal,
        isTurboModeOn: Bool,
        onStep: @escaping (CollectiblesPackPurchaseStep) -> Void
    ) async throws -> CollectiblesPackPurchaseResult {
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
                isTurboModeOn: isTurboModeOn
            )
        }
        activePurchase = ActivePurchase(machineID: machineID, task: task)

        return try await task.value
    }
}

// MARK: - Private logic

private extension RemoteCollectiblesPackPurchaseInteractor {
    struct ActivePurchase {
        let machineID: String
        let task: Task<CollectiblesPackPurchaseResult, any Error>
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

    func runPurchase(
        machineID: String,
        price: Decimal,
        platformFee: Decimal,
        isTurboModeOn: Bool
    ) async throws -> CollectiblesPackPurchaseResult {
        if pendingOrder?.machineID != machineID {
            report(.generating)
        }

        var order = try await pendingOrStartedOrder(
            machineID: machineID,
            price: price,
            platformFee: platformFee,
            isTurboModeOn: isTurboModeOn
        )

        if order.stage != .opened {
            report(.confirming)
        }

        if order.stage == .signed {
            try await send(order)
            order.stage = .sent
            pendingOrder = order
        }

        if order.stage == .sent {
            try await reportSent(order)
            order.stage = .reported
            pendingOrder = order
        }

        let wonCard: CollectiblesWonCard

        do {
            wonCard = try await deliverWonCard(of: order)
        } catch CollectiblesPackPurchaseError.paymentFailed(let status) {
            pendingOrder = nil
            throw CollectiblesPackPurchaseError.paymentFailed(status)
        } catch let sold as CollectiblesPurchaseTracker.AutoSold {
            pendingOrder = nil
            return .autoSold(amount: sold.amount)
        }

        // [REDACTED_TODO_COMMENT]
        pendingOrder = nil

        return .wonCard(wonCard)
    }

    func deliverWonCard(of order: Order) async throws -> CollectiblesWonCard {
        var order = order
        var openedCard: CollectiblesWonCard?

        if order.stage == .reported || order.stage == .paid {
            switch try await tracker.awaitPayment(txID: order.txID) {
            case .paid:
                order.stage = .paid
            case .opened(let wonCard):
                order.stage = .opened
                openedCard = wonCard
            }

            pendingOrder = order
        }

        report(.opening)

        if order.stage == .paid {
            openedCard = try await tracker.open(txID: order.txID)
            order.stage = .opened
            pendingOrder = order
        }

        if let openedCard {
            return openedCard
        }

        return try await tracker.awaitWonCard(txID: order.txID)
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
        isTurboModeOn: Bool
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

        let generated: CollectiblesGeneratedPurchase

        do {
            generated = try await generator.generate(
                machineID: machineID,
                fromAddress: addresses.player,
                toAddress: addresses.prizeRecipient,
                turboMode: isTurboModeOn ? .on(buybackAddress: addresses.prizeRecipient) : .off
            )
        } catch CollectiblesPurchaseGenerationError.lowInventory {
            throw CollectiblesPackPurchaseError.lowInventory
        }
        let confirmedPrice = try CollectiblesConfirmedPrice(price: price, platformFee: platformFee)
        let signedPurchase = try await signer.signPurchase(generated.purchase, confirmedPrice: confirmedPrice)

        let order = Order(machineID: machineID, txID: generated.txID, signedPurchase: signedPurchase, stage: .signed)
        pendingOrder = order

        return order
    }

    func reportSent(_ order: Order) async throws {
        do {
            _ = try await sentReporter.report(txID: order.txID, txHash: order.signedPurchase.signature)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            CollectiblesLogger.error("Collectibles purchase \(order.txID) sent report failed", error: error)
            throw CollectiblesPackPurchaseError.packUnopened
        }
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
}
