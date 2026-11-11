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
    private let pendingPurchaseProvider: any CollectiblesPendingPurchaseProvider
    private let tracker: CollectiblesPurchaseTracker

    private var signer: any CollectiblesPurchaseSigner

    private var pendingOrder: Order?
    private var activePurchase: ActivePurchase?
    private var deliveredTxIDs: Set<String> = []
    private var stepHandler: ((CollectiblesPackPurchaseStep) -> Void)?
    private var currentStep: CollectiblesPackPurchaseStep?

    // MARK: - Init

    init(
        generator: any CollectiblesPurchaseGenerator,
        signer: any CollectiblesPurchaseSigner,
        sentReporter: any CollectiblesPurchaseSentReporter,
        statusProvider: any CollectiblesPurchaseStatusProvider,
        opener: any CollectiblesPackOpener,
        pendingPurchaseProvider: any CollectiblesPendingPurchaseProvider,
        delayProvider: any PollDelayProvider = TaskSleepPollDelayProvider(),
        dateProvider: any DateProvider = SystemDateProvider()
    ) {
        self.generator = generator
        self.signer = signer
        self.sentReporter = sentReporter
        self.pendingPurchaseProvider = pendingPurchaseProvider
        tracker = CollectiblesPurchaseTracker(
            statusProvider: statusProvider,
            opener: opener,
            delayProvider: delayProvider,
            dateProvider: dateProvider
        )
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

    func isPurchaseLocked(machineID: String) -> Bool {
        !hasUnfinishedPurchase(machineID: machineID) && signer.isRelinkRequired
    }

    func isDelivered(txID: String) -> Bool {
        deliveredTxIDs.contains(txID)
    }

    func purchase(
        machineID: String,
        price: Decimal,
        platformFee: Decimal,
        isTurboModeOn: Bool,
        onStep: @escaping (CollectiblesPackPurchaseStep) -> Void
    ) async throws -> CollectiblesPackPurchaseResult {
        try await runActivePurchase(machineID: machineID, onStep: onStep) { [self] in
            try await runPurchase(
                machineID: machineID,
                price: price,
                platformFee: platformFee,
                isTurboModeOn: isTurboModeOn
            )
        }
    }

    func resumePurchase(
        _ purchase: CollectiblesPendingPurchase,
        onStep: @escaping (CollectiblesPackPurchaseStep) -> Void
    ) async throws -> CollectiblesPackPurchaseResult {
        try await runActivePurchase(machineID: purchase.machineID, txID: purchase.txID, onStep: onStep) { [self] in
            let order = try await resumableOrder(of: purchase)

            return try await complete(order)
        }
    }

    func resumeKeptPurchase(
        machineID: String,
        onStep: @escaping (CollectiblesPackPurchaseStep) -> Void
    ) async throws -> CollectiblesPackPurchaseResult {
        try await runActivePurchase(machineID: machineID, onStep: onStep) { [self] in
            guard let pendingOrder, pendingOrder.machineID == machineID, pendingOrder.stage != .signed else {
                throw CollectiblesPackPurchaseError.noUnfinishedPurchase
            }

            return try await complete(pendingOrder)
        }
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
        let signedPurchase: CollectiblesSignedPurchase?
        let isTurboModeOn: Bool
        let createdAt: Date?
        var stage: Stage
    }

    enum Stage {
        case signed
        case sendUnconfirmed
        case sent
        case reported
        case paymentWaitOver
        case paid
        case opened
    }

    func runActivePurchase(
        machineID: String,
        txID: String? = nil,
        onStep: @escaping (CollectiblesPackPurchaseStep) -> Void,
        operation: @escaping @MainActor () async throws -> CollectiblesPackPurchaseResult
    ) async throws -> CollectiblesPackPurchaseResult {
        if let activePurchase {
            guard activePurchase.machineID == machineID, txID == nil || txID == pendingOrder?.txID else {
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

            return try await operation()
        }
        activePurchase = ActivePurchase(machineID: machineID, task: task)

        return try await task.value
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

        let order = try await pendingOrStartedOrder(
            machineID: machineID,
            price: price,
            platformFee: platformFee,
            isTurboModeOn: isTurboModeOn
        )

        return try await complete(order)
    }

    func complete(_ order: Order) async throws -> CollectiblesPackPurchaseResult {
        var order = order

        if order.stage != .opened {
            report(.confirming)
        }

        if order.stage == .sendUnconfirmed {
            order = try await reconciledUnconfirmedOrder(order)
        }

        if order.stage == .signed || order.stage == .sendUnconfirmed, let signedPurchase = order.signedPurchase {
            try await send(signedPurchase, of: order)
            order.stage = .sent
            pendingOrder = order
        }

        if order.stage == .sent, let signedPurchase = order.signedPurchase {
            try await reportSent(signedPurchase, of: order)
            order.stage = .reported
            pendingOrder = order
        }

        let wonCard: CollectiblesWonCard

        do {
            wonCard = try await deliverWonCard(of: order)
        } catch CollectiblesPackPurchaseError.paymentFailed(let status) {
            pendingOrder = nil
            throw CollectiblesPackPurchaseError.paymentFailed(status)
        } catch CollectiblesPackPurchaseError.openRefused {
            pendingOrder = nil
            throw CollectiblesPackPurchaseError.openRefused
        } catch let sold as CollectiblesPurchaseTracker.AutoSold {
            pendingOrder = nil
            deliveredTxIDs.insert(order.txID)
            return .autoSold(amount: sold.amount, wonCard: sold.wonCard)
        }

        // [REDACTED_TODO_COMMENT]
        pendingOrder = nil
        deliveredTxIDs.insert(order.txID)

        return .wonCard(wonCard)
    }

    func deliverWonCard(of order: Order) async throws -> CollectiblesWonCard {
        var order = order
        var openedCard: CollectiblesWonCard?

        if order.stage == .reported || order.stage == .paid {
            let packCreatedAt = order.stage == .reported ? order.createdAt : nil
            let payment: CollectiblesPurchaseTracker.Payment

            do {
                payment = try await tracker.awaitPayment(
                    txID: order.txID,
                    createdAt: packCreatedAt,
                    isTurboModeOn: order.isTurboModeOn
                )
            } catch CollectiblesPackPurchaseError.paymentTimedOut {
                order.stage = .paymentWaitOver
                pendingOrder = order
                throw CollectiblesPackPurchaseError.paymentTimedOut
            }

            switch payment {
            case .paid:
                order.stage = .paid
            case .opened(let wonCard):
                order.stage = .opened
                openedCard = wonCard
            }

            pendingOrder = order
        }

        report(.opening)

        if order.stage == .paid || order.stage == .paymentWaitOver {
            openedCard = try await open(order)
            order.stage = .opened
            pendingOrder = order
        }

        if let openedCard {
            return openedCard
        }

        return try await tracker.awaitWonCard(txID: order.txID, isTurboModeOn: order.isTurboModeOn)
    }

    func open(_ order: Order) async throws -> CollectiblesWonCard? {
        do {
            return try await tracker.open(txID: order.txID, isTurboModeOn: order.isTurboModeOn)
        } catch CollectiblesPackOpeningError.refused {
            throw CollectiblesPackPurchaseError.openRefused
        } catch CollectiblesPackOpeningError.spinNotFound {
            throw CollectiblesPackPurchaseError.paymentFailed(.refunded)
        }
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
        if let pendingOrder {
            guard pendingOrder.machineID != machineID else {
                return pendingOrder
            }

            if pendingOrder.stage != .signed {
                guard try await tracker.checkPurchaseIsClosed(txID: pendingOrder.txID) else {
                    throw CollectiblesPackPurchaseError.anotherPurchaseInProgress
                }

                self.pendingOrder = nil
            }
        }

        try await ensureNoUnfinishedPurchase()

        let isRelinkRequired = try await signer.resolveRelinkRequirement()

        guard !isRelinkRequired else {
            throw CollectiblesPackPurchaseError.relinkRequired
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
                turboMode: isTurboModeOn ? .on(buybackAddress: addresses.payoutRecipient) : .off
            )
        } catch CollectiblesPurchaseGenerationError.lowInventory {
            throw CollectiblesPackPurchaseError.lowInventory
        }
        let confirmedPrice = try CollectiblesConfirmedPrice(price: price, platformFee: platformFee)
        let signedPurchase: CollectiblesSignedPurchase

        do {
            signedPurchase = try await signer.signPurchase(generated.purchase, confirmedPrice: confirmedPrice)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            guard try await isRelinkRequiredNow(txID: generated.txID) else {
                throw error
            }

            throw CollectiblesPackPurchaseError.relinkRequired
        }

        let order = Order(
            machineID: machineID,
            txID: generated.txID,
            signedPurchase: signedPurchase,
            isTurboModeOn: isTurboModeOn,
            createdAt: nil,
            stage: .signed
        )
        pendingOrder = order

        return order
    }

    func reportSent(_ signedPurchase: CollectiblesSignedPurchase, of order: Order) async throws {
        do {
            _ = try await sentReporter.report(txID: order.txID, txHash: signedPurchase.signature)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            CollectiblesLogger.error("Collectibles purchase \(order.txID) sent report failed, the backend finds the payment by its memo", error: error)
        }
    }

    func send(_ signedPurchase: CollectiblesSignedPurchase, of order: Order) async throws {
        do throws(CollectiblesSendError) {
            try await signer.sendPurchase(signedPurchase)
        } catch {
            switch error {
            case .transactionExpired:
                if order.stage == .signed {
                    pendingOrder = nil
                }

                throw error
            case .outcomeUnknown:
                var order = order
                order.stage = .sendUnconfirmed
                pendingOrder = order
                throw error
            case .rejected(let rejection):
                guard rejection as? CollectiblesProgramRejection == .unauthorized else {
                    throw error
                }

                pendingOrder = nil
                try await refreshRelinkState(txID: order.txID)
                throw CollectiblesPackPurchaseError.relinkRequired
            }
        }
    }

    func reconciledUnconfirmedOrder(_ order: Order) async throws -> Order {
        switch try await tracker.currentStatus(txID: order.txID) {
        case nil, .created, .waitingTxHash:
            return order
        case .expired:
            pendingOrder = nil
            throw CollectiblesSendError.transactionExpired
        default:
            var order = order
            order.stage = .reported
            pendingOrder = order
            return order
        }
    }

    func resumableOrder(of purchase: CollectiblesPendingPurchase) async throws -> Order {
        if let pendingOrder, pendingOrder.txID == purchase.txID, pendingOrder.stage != .signed, pendingOrder.stage != .sendUnconfirmed {
            return pendingOrder
        }

        if let pendingOrder, pendingOrder.txID != purchase.txID, pendingOrder.stage == .sent || pendingOrder.stage == .sendUnconfirmed {
            guard try await tracker.checkPurchaseIsClosed(txID: pendingOrder.txID) else {
                throw CollectiblesPackPurchaseError.anotherPurchaseInProgress
            }
        }

        guard !deliveredTxIDs.contains(purchase.txID), let stage = Self.stage(resumingFrom: purchase.status) else {
            throw CollectiblesPackPurchaseError.noUnfinishedPurchase
        }

        let order = Order(
            machineID: purchase.machineID,
            txID: purchase.txID,
            signedPurchase: nil,
            isTurboModeOn: purchase.isTurboModeOn,
            createdAt: purchase.createdAt,
            stage: stage
        )
        pendingOrder = order

        return order
    }

    func ensureNoUnfinishedPurchase() async throws {
        let purchases = try await pendingPurchaseProvider.load()
        try Task.checkCancellation()

        let isAnyPurchaseUnfinished = purchases.contains { purchase in
            !deliveredTxIDs.contains(purchase.txID) && Self.stage(resumingFrom: purchase.status) != nil
        }

        guard !isAnyPurchaseUnfinished else {
            throw CollectiblesPackPurchaseError.anotherPurchaseInProgress
        }
    }

    static func stage(resumingFrom status: CollectiblesPurchaseStatus) -> Stage? {
        switch status {
        case .purchaseTxHash, .waitingForPayment, .unknown:
            .reported
        case .packPurchased:
            .paid
        case .packOpened:
            .opened
        case .created, .waitingTxHash, .expired, .refunded, .packOpeningError, .nftReceived, .autoBuybacked, .manuallyBuybacked, .paused:
            nil
        }
    }

    func refreshRelinkState(txID: String) async throws {
        _ = try await isRelinkRequiredNow(txID: txID)
    }

    func isRelinkRequiredNow(txID: String) async throws -> Bool {
        do {
            return try await signer.resolveRelinkRequirement()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            CollectiblesLogger.error("Collectibles purchase \(txID) relink recheck failed", error: error)
            return false
        }
    }
}
