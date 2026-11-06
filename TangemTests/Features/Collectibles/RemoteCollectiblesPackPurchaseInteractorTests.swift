//
//  RemoteCollectiblesPackPurchaseInteractorTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
import TangemTestKit
@testable import TangemCollectibles
@testable import Tangem

@Suite("RemoteCollectiblesPackPurchaseInteractor", .timeLimit(.minutes(1)))
@MainActor
final class RemoteCollectiblesPackPurchaseInteractorTests: LeakTrackingTestSuite {
    typealias SUT = RemoteCollectiblesPackPurchaseInteractor

    // MARK: - Happy path

    @Test("Walks every step and returns the won card")
    func completesPurchase() async throws {
        let (sut, provider, signer) = makeSUT()
        var steps: [CollectiblesPackPurchaseStep] = []

        let wonCard = try await purchase(sut) { steps.append($0) }

        #expect(wonCard.gradingID == Constants.gradingID)
        #expect(steps == [.generating, .confirming, .opening])
        #expect(provider.generatedMachineIDs == [Constants.machineID])
        #expect(provider.generatedAddresses == [Constants.addresses])
        #expect(signer.sentSignatures == [Constants.signature])
        #expect(provider.reportedHashes == [Constants.signature])
        #expect(provider.openedTxIDs == [Constants.txID])
        #expect(!sut.hasUnfinishedPurchase(machineID: Constants.machineID))
    }

    @Test("Turbo mode sends the auto-sell proceeds to the prize recipient", arguments: [false, true])
    func passesTurboMode(isTurboModeOn: Bool) async throws {
        let (sut, provider, _) = makeSUT()
        let expected: CollectiblesTurboMode = isTurboModeOn ? .on(buybackAddress: Constants.addresses.prizeRecipient) : .off

        _ = try await purchase(sut, isTurboModeOn: isTurboModeOn)

        #expect(provider.generatedTurboModes == [expected])
    }

    @Test("Signs the shown price and fee in USDC base units", arguments: Self.priceArguments)
    func signsShownPrice(price: Decimal, platformFee: Decimal, expected: Units) async throws {
        let (sut, _, signer) = makeSUT()

        _ = try await purchase(sut, price: price, platformFee: platformFee)

        let confirmed = try #require(signer.confirmedPrices.first)
        #expect(confirmed.amount == expected.amount)
        #expect(confirmed.feeAmount == expected.feeAmount)
    }

    // MARK: - Before the payment

    @Test("Refuses to start while the account has no purchase addresses")
    func refusesWithoutAddresses() async {
        let (sut, provider, _) = makeSUT(addresses: nil)

        let failure = await failure(of: sut)

        #expect(failure == .accountNotReady)
        #expect(provider.generatedMachineIDs.isEmpty)
    }

    @Test("Refuses to sign a negative or oversized price or fee", arguments: Self.invalidPriceArguments)
    func refusesInvalidPrice(price: Decimal, platformFee: Decimal) async {
        let (sut, _, signer) = makeSUT()

        let failure = await failure(of: sut, price: price, platformFee: platformFee)

        #expect(failure == .invalidPrice)
        #expect(signer.confirmedPrices.isEmpty)
    }

    @Test(
        "A node or program rejection keeps the signed order, the retry sends the same transaction",
        arguments: Self.rejections
    )
    func rejectionResendsSameOrder(rejection: CollectiblesSendError) async throws {
        let (sut, provider, signer) = makeSUT(sendResults: [.failure(rejection), .success(())])

        let failure = await failure(of: sut)
        #expect(failure == .other)

        _ = try await purchase(sut)

        #expect(provider.generatedMachineIDs.count == 1)
        #expect(signer.confirmedPrices.count == 1)
        #expect(signer.sentSignatures == [Constants.signature, Constants.signature])
    }

    @Test("A session key the vault refuses stops as a relink, reports nothing and drops the order, so the next try signs a fresh one")
    func sessionKeyRefusalStopsAsRelink() async throws {
        let (sut, provider, signer) = makeSUT(
            sendResults: [.failure(.rejected(CollectiblesProgramRejection.unauthorized)), .success(())]
        )

        let failure = await failure(of: sut)
        #expect(failure == .relinkRequired)
        #expect(provider.reportedHashes.isEmpty)
        #expect(!sut.hasUnfinishedPurchase(machineID: Constants.machineID))

        _ = try await purchase(sut)

        #expect(provider.generatedMachineIDs.count == 2)
        #expect(signer.confirmedPrices.count == 2)
    }

    @Test(
        "A relink locks a new purchase, including one after the vault refused the session key, never an order that may have paid",
        arguments: [
            (isRelinkRequired: false, order: OrderStage.noOrder, isLocked: false),
            (isRelinkRequired: true, order: OrderStage.noOrder, isLocked: true),
            (isRelinkRequired: true, order: OrderStage.signedOnly, isLocked: false),
            (isRelinkRequired: true, order: OrderStage.refusedForSessionKey, isLocked: true),
            (isRelinkRequired: false, order: OrderStage.refusedForSessionKey, isLocked: false),
            (isRelinkRequired: true, order: OrderStage.sent, isLocked: false),
        ]
    )
    func relinkLocksOnlyNewPurchases(isRelinkRequired: Bool, order: OrderStage, isLocked: Bool) async {
        let (sut, _, signer) = makeSUT(sendResults: [order.sendResult], reportResults: [.failure(Constants.error)])

        if order != .noOrder {
            _ = await failure(of: sut)
        }

        signer.setRelinkRequired(isRelinkRequired)

        #expect(sut.isPurchaseLocked(machineID: Constants.machineID) == isLocked)
    }

    @Test("A fresh read that fails stops the purchase before any order is created")
    func failedFreshReadStopsPurchase() async {
        let (sut, provider, signer) = makeSUT(freshReadError: Constants.error)

        let failure = await failure(of: sut)

        #expect(failure == .other)
        #expect(provider.generatedMachineIDs.isEmpty)
        #expect(signer.sentSignatures.isEmpty)
    }

    @Test("A relink found by the fresh read stops the purchase before any order is created, whatever the last known state says")
    func relinkStopsPurchaseBeforeOrder() async {
        let (sut, provider, signer) = makeSUT(relinkReads: [true])

        let failure = await failure(of: sut)

        #expect(failure == .relinkRequired)
        #expect(provider.generatedMachineIDs.isEmpty)
        #expect(signer.sentSignatures.isEmpty)
        #expect(!sut.hasUnfinishedPurchase(machineID: Constants.machineID))
    }

    @Test("A signing refused after a relink stops the purchase as a relink and leaves no order")
    func signingRefusedAfterRelink() async {
        let (sut, _, signer) = makeSUT(relinkReads: [false, true], signError: Constants.error)

        let failure = await failure(of: sut)

        #expect(failure == .relinkRequired)
        #expect(signer.sentSignatures.isEmpty)
        #expect(!sut.hasUnfinishedPurchase(machineID: Constants.machineID))
    }

    @Test("A machine out of cards fails as low inventory and leaves no unfinished purchase")
    func lowInventory() async {
        let (sut, _, signer) = makeSUT(generateError: CollectiblesPurchaseGenerationError.lowInventory)

        let failure = await failure(of: sut)

        #expect(failure == .lowInventory)
        #expect(signer.sentSignatures.isEmpty)
        #expect(!sut.hasUnfinishedPurchase(machineID: Constants.machineID))
    }

    @Test("A failed generation or signing leaves no unfinished purchase", arguments: FailingStep.allCases)
    func failedPreparationLeavesNothing(step: FailingStep) async {
        let (sut, _, signer) = makeSUT(
            generateError: step == .generation ? Constants.error : nil,
            signError: step == .signing ? Constants.error : nil
        )

        let failure = await failure(of: sut)

        #expect(failure == .other)
        #expect(signer.sentSignatures.isEmpty)
        #expect(!sut.hasUnfinishedPurchase(machineID: Constants.machineID))
    }

    @Test("A retry after the signer is replaced sends through the new signer")
    func retryUsesReplacedSigner() async throws {
        let (sut, _, signer) = makeSUT(sendResults: [.failure(.rejected(Constants.error))])
        _ = await failure(of: sut)

        let replacement = PurchaseSignerStub(addresses: Constants.addresses, sendResults: [.success(())])
        sut.update(signer: replacement)
        _ = try await purchase(sut)

        #expect(signer.sentSignatures.count == 1)
        #expect(replacement.sentSignatures == [Constants.signature])
    }

    // MARK: - Unknown send outcome

    @Test("An unknown or expired send outcome is left to the backend status", arguments: UndecidedSend.allCases)
    func undecidedSendGoesToBackend(outcome: UndecidedSend) async throws {
        let (sut, provider, _) = makeSUT(sendResults: [.failure(outcome.error)])

        let wonCard = try await purchase(sut)

        #expect(wonCard.gradingID == Constants.gradingID)
        #expect(provider.reportedHashes == [Constants.signature])
    }

    @Test("A failed report shows the unopened pack and its retry does not send the transaction again")
    func failedReportDoesNotResend() async throws {
        let (sut, provider, signer) = makeSUT(reportResults: [.failure(Constants.error), .success(.purchaseTxHash)])

        let failure = await failure(of: sut)
        #expect(failure == .packUnopened)
        #expect(sut.hasUnfinishedPurchase(machineID: Constants.machineID))

        var steps: [CollectiblesPackPurchaseStep] = []
        _ = try await purchase(sut) { steps.append($0) }

        #expect(steps == [.confirming, .opening])
        #expect(signer.sentSignatures.count == 1)
        #expect(provider.reportedHashes == [Constants.signature, Constants.signature])
    }

    // MARK: - Payment

    @Test("A payment that never confirms times out and the retry polls again without paying twice")
    func paymentTimeoutResumes() async throws {
        let (sut, provider, signer) = makeSUT(statuses: [Self.transaction(.waitingForPayment)])

        let failure = await failure(of: sut)

        #expect(failure == .paymentTimedOut)
        #expect(provider.statusLoadsCount == Constants.paymentChecks)
        #expect(sut.hasUnfinishedPurchase(machineID: Constants.machineID))

        provider.statuses = Self.paidAndDelivered
        var steps: [CollectiblesPackPurchaseStep] = []
        _ = try await purchase(sut) { steps.append($0) }

        #expect(steps == [.confirming, .opening])
        #expect(provider.generatedMachineIDs.count == 1)
        #expect(signer.sentSignatures.count == 1)
    }

    @Test("Network errors while the payment is awaited do not stop the polling")
    func pollingSurvivesErrors() async throws {
        let (sut, provider, _) = makeSUT(statusFailures: Constants.statusFailures)

        let wonCard = try await purchase(sut)

        #expect(wonCard.gradingID == Constants.gradingID)
        #expect(provider.statusLoadsCount == Constants.statusFailures + Self.paidAndDelivered.count)
    }

    @Test("A status that is still in progress keeps the payment awaited", arguments: Self.pendingStatuses)
    func pendingStatusKeepsWaiting(status: CollectiblesPurchaseStatus) async {
        let (sut, provider, _) = makeSUT(statuses: [Self.transaction(status)])

        let failure = await failure(of: sut)

        #expect(failure == .paymentTimedOut)
        #expect(provider.openedTxIDs.isEmpty)
    }

    @Test("A status that confirms the payment opens the pack", arguments: Self.paidStatuses)
    func paidStatusOpensPack(status: CollectiblesPurchaseStatus) async throws {
        let (sut, provider, _) = makeSUT(statuses: [Self.transaction(status), Self.deliveredTransaction])

        let wonCard = try await purchase(sut)

        #expect(wonCard.gradingID == Constants.gradingID)
        #expect(provider.openedTxIDs == [Constants.txID])
    }

    @Test("An unknown status stops the polling and lets the opening decide")
    func unknownStatusOpensPack() async throws {
        let statuses = [Self.transaction(.unknown("new-status")), Self.deliveredTransaction]
        let (sut, provider, _) = makeSUT(statuses: statuses)

        let wonCard = try await purchase(sut)

        #expect(wonCard.gradingID == Constants.gradingID)
        #expect(provider.openedTxIDs == [Constants.txID])
    }

    // MARK: - Opening

    @Test("The card from the open-pack answer is returned without polling the status again")
    func openedCardSkipsPolling() async throws {
        let (sut, provider, _) = makeSUT(
            statuses: [Self.transaction(.packPurchased)],
            openResults: [.success(Self.openedTransaction)]
        )

        let wonCard = try await purchase(sut)

        #expect(wonCard.gradingID == Constants.gradingID)
        #expect(provider.statusLoadsCount == 1)
        #expect(!sut.hasUnfinishedPurchase(machineID: Constants.machineID))
    }

    @Test("A pack that fails to open is opened again on retry after the payment is checked, without paying twice")
    func openFailureResumes() async throws {
        let (sut, provider, signer) = makeSUT(openResults: [.failure(Constants.error)])

        let failure = await failure(of: sut)

        #expect(failure == .openFailed)
        #expect(provider.openedTxIDs.count == Constants.openAttempts)

        let statusLoads = provider.statusLoadsCount
        provider.statuses = Self.paidAndDelivered
        provider.openResults = [.success(Self.transaction(.packOpened))]
        var steps: [CollectiblesPackPurchaseStep] = []
        _ = try await purchase(sut) { steps.append($0) }

        #expect(steps == [.confirming, .opening])
        #expect(provider.statusLoadsCount > statusLoads)
        #expect(signer.sentSignatures.count == 1)
        #expect(provider.openedTxIDs.last == Constants.txID)
    }

    @Test("A pack the backend opened while the answers were lost is not opened again on retry")
    func openedPackRetryAwaitsCard() async throws {
        let (sut, provider, _) = makeSUT(openResults: [.failure(Constants.error)])
        _ = await failure(of: sut)

        let openCalls = provider.openedTxIDs.count
        let statusLoads = provider.statusLoadsCount
        provider.statuses = [Self.deliveredTransaction]
        let wonCard = try await purchase(sut)

        #expect(wonCard.gradingID == Constants.gradingID)
        #expect(provider.openedTxIDs.count == openCalls)
        #expect(provider.statusLoadsCount == statusLoads + 1)
        #expect(!sut.hasUnfinishedPurchase(machineID: Constants.machineID))
    }

    @Test("A purchase closed while its pack failed to open ends on retry without opening again")
    func openFailureRetryEndsOnClosedPurchase() async {
        let (sut, provider, _) = makeSUT(openResults: [.failure(Constants.error)])
        _ = await failure(of: sut)

        let openCalls = provider.openedTxIDs.count
        provider.statuses = [Self.transaction(.expired)]
        let failure = await failure(of: sut)

        #expect(failure == .paymentFailed(.expired))
        #expect(provider.openedTxIDs.count == openCalls)
        #expect(!sut.hasUnfinishedPurchase(machineID: Constants.machineID))
    }

    @Test("A prize the backend never delivers is awaited again on retry without opening the pack twice")
    func missingPrizeResumes() async throws {
        let (sut, provider, _) = makeSUT(statuses: [Self.transaction(.packPurchased), Self.transaction(.packOpened)])

        let failure = await failure(of: sut)

        #expect(failure == .prizeNotDelivered)
        #expect(sut.hasUnfinishedPurchase(machineID: Constants.machineID))

        let openCalls = provider.openedTxIDs.count
        provider.statuses = [Self.deliveredTransaction]
        let wonCard = try await purchase(sut)

        #expect(wonCard.gradingID == Constants.gradingID)
        #expect(provider.openedTxIDs.count == openCalls)
    }

    // MARK: - Failed status

    @Test(
        "A failed status from the backend drops the order at any step",
        arguments: FailedStage.allCases, Self.failedStatuses
    )
    func failedStatusDropsOrder(stage: FailedStage, status: CollectiblesPurchaseStatus) async {
        let (sut, _, _) = makeSUT(failingAt: stage, with: status)

        let failure = await failure(of: sut)

        #expect(failure == .paymentFailed(status))
        #expect(!sut.hasUnfinishedPurchase(machineID: Constants.machineID))
    }

    // MARK: - Auto buyback

    @Test("An auto buyback at any step ends as sold with no unfinished purchase", arguments: FailedStage.allCases)
    func autoBuybackEndsAsSold(stage: FailedStage) async throws {
        let (sut, _, _) = makeSUT(failingAt: stage, with: .autoBuybacked)

        _ = try await sold(by: sut)

        #expect(!sut.hasUnfinishedPurchase(machineID: Constants.machineID))
    }

    @Test("An auto buyback returns the sold amount and card and does not open the pack")
    func autoBuybackReturnsAmountAndCard() async throws {
        let transaction = CollectiblesPurchaseTransaction(
            status: .autoBuybacked,
            wonCard: Self.deliveredTransaction.wonCard,
            buybackAmount: Constants.buybackAmount
        )
        let (sut, provider, _) = makeSUT(statuses: [transaction])

        let result = try await sold(by: sut)

        #expect(result.amount == Constants.buybackAmount)
        #expect(result.wonCard?.gradingID == Constants.gradingID)
        #expect(provider.openedTxIDs.isEmpty)
    }

    // MARK: - Paused status

    @Test("A closing status wins over a card that comes in the same answer", arguments: Self.closingStatuses)
    func closingStatusWinsOverDeliveredCard(status: CollectiblesPurchaseStatus) async {
        let closedWithCard = CollectiblesPurchaseTransaction(status: status, wonCard: Self.deliveredTransaction.wonCard)
        let (sut, _, _) = makeSUT(statuses: [Self.transaction(.packPurchased), closedWithCard])

        let failure = await failure(of: sut)
        let expected: Failure = status == .paused ? .packUnopened : .paymentFailed(status)

        #expect(failure == expected)
    }

    @Test("A paused purchase keeps the order as an unopened pack at any step", arguments: FailedStage.allCases)
    func pausedStatusKeepsOrder(stage: FailedStage) async {
        let (sut, _, _) = makeSUT(failingAt: stage, with: .paused)

        let failure = await failure(of: sut)

        #expect(failure == .packUnopened)
        #expect(sut.hasUnfinishedPurchase(machineID: Constants.machineID))
    }

    // MARK: - Another machine

    @Test("A sent order on one machine blocks a purchase on another")
    func sentOrderBlocksOtherMachine() async {
        let (sut, provider, _) = makeSUT(statuses: [Self.transaction(.waitingForPayment)])
        _ = await failure(of: sut)

        let failure = await failure(of: sut, machineID: Constants.otherMachineID)

        #expect(failure == .anotherPurchaseInProgress)
        #expect(provider.generatedMachineIDs == [Constants.machineID])
    }

    @Test("An order the backend closed no longer blocks another machine", arguments: [
        CollectiblesPurchaseStatus.expired,
        CollectiblesPurchaseStatus.refunded,
        CollectiblesPurchaseStatus.autoBuybacked,
    ])
    func closedOrderFreesOtherMachine(status: CollectiblesPurchaseStatus) async throws {
        let (sut, provider, _) = makeSUT(statuses: [Self.transaction(.waitingForPayment)])
        _ = await failure(of: sut)
        provider.statuses = [Self.transaction(status)] + Self.paidAndDelivered

        _ = try await purchase(sut, machineID: Constants.otherMachineID)

        #expect(provider.generatedMachineIDs == [Constants.machineID, Constants.otherMachineID])
        #expect(!sut.hasUnfinishedPurchase(machineID: Constants.machineID))
    }

    // MARK: - Restored purchase

    @Test("A purchase does not start while the unfinished purchases cannot be read")
    func unreadablePendingPurchasesStopPurchase() async {
        let (sut, provider, _) = makeSUT()
        provider.pendingPurchaseError = Constants.error

        let failure = await failure(of: sut)

        #expect(failure == .other)
        #expect(provider.generatedMachineIDs.isEmpty)
    }

    @Test("An order that never left the device gives way to the purchase the backend holds")
    func unsentOrderGivesWayToBackendPurchase() async {
        let (sut, provider, _) = makeSUT(sendResults: [.failure(.rejected(Constants.error))])
        _ = await failure(of: sut)
        provider.pendingPurchase = Self.pendingPurchase(.packPurchased, machineID: Constants.otherMachineID)

        let failure = await failure(of: sut)

        #expect(failure == .anotherPurchaseInProgress)
        #expect(sut.hasUnfinishedPurchase(machineID: Constants.otherMachineID))
        #expect(provider.generatedMachineIDs == [Constants.machineID])
    }

    @Test("A purchase that just ended is not brought back while the backend still lists it", arguments: [
        Constants.machineID,
        Constants.otherMachineID,
    ])
    func endedPurchaseIsNotRestored(nextMachineID: String) async throws {
        let (sut, provider, _) = makeSUT()
        _ = try await purchase(sut)
        provider.statuses = Self.paidAndDelivered
        provider.pendingPurchase = Self.pendingPurchase(.packOpened, txID: Constants.txID)

        _ = try await purchase(sut, machineID: nextMachineID)

        #expect(provider.generatedMachineIDs == [Constants.machineID, nextMachineID])
    }

    @Test("A purchase the backend holds replaces an older order kept on this device")
    func backendPurchaseReplacesKeptOrder() async throws {
        let (sut, provider, _) = makeSUT(statuses: [Self.transaction(.waitingForPayment)])
        _ = await failure(of: sut)
        provider.statuses = Self.paidAndDelivered
        provider.pendingPurchase = Self.pendingPurchase(.packPurchased, machineID: Constants.otherMachineID)

        let wonCard = try await purchase(sut, machineID: Constants.otherMachineID)

        #expect(wonCard.gradingID == Constants.gradingID)
        #expect(provider.generatedMachineIDs == [Constants.machineID])
        #expect(provider.openedTxIDs == [Constants.restoredTxID])
    }

    @Test(
        "A lookup that answers after the purchase finished does not bring that purchase back",
        arguments: [false, true]
    )
    func lateLookupDoesNotRestoreFinishedPurchase(isScreenReopened: Bool) async throws {
        let (sut, provider, _) = makeSUT(pendingPurchase: Self.pendingPurchase(.packPurchased))
        let gate = LookupGate()
        defer { gate.open() }
        provider.pendingLookupGate = gate
        var arrivals = gate.arrivals.makeAsyncIterator()
        let preload = Task { await sut.restorePendingPurchase() }
        await arrivals.next()

        if isScreenReopened {
            await sut.restorePendingPurchase()
        }

        _ = try await purchase(sut)
        gate.open()
        await preload.value

        #expect(!sut.hasUnfinishedPurchase(machineID: Constants.machineID))
    }

    @Test("An order started on this device takes the creation date the backend reports for it")
    func keptOrderTakesBackendCreationDate() async {
        let (sut, provider, _) = makeSUT(statuses: [Self.transaction(.waitingForPayment)])
        _ = await failure(of: sut)
        provider.pendingPurchase = Self.pendingPurchase(
            .waitingForPayment,
            txID: Constants.txID,
            createdAt: Constants.now.addingTimeInterval(-300)
        )

        let failure = await failure(of: sut)

        #expect(failure == .paymentTimedOut)
        #expect(provider.statusLoadsCount == Constants.paymentChecks + 1)
    }

    @Test("A purchase restored from the backend resumes from its status without ordering again", arguments: [
        (CollectiblesPurchaseStatus.waitingForPayment, true),
        (CollectiblesPurchaseStatus.packPurchased, true),
        (CollectiblesPurchaseStatus.packOpeningError, true),
        (CollectiblesPurchaseStatus.packOpened, false),
        (CollectiblesPurchaseStatus.unknown("pack-stuck"), true),
    ])
    func resumesRestoredPurchase(status: CollectiblesPurchaseStatus, opensPack: Bool) async throws {
        let (sut, provider, signer) = makeSUT(pendingPurchase: Self.pendingPurchase(status))

        let wonCard = try await purchase(sut)

        #expect(wonCard.gradingID == Constants.gradingID)
        #expect(provider.generatedMachineIDs.isEmpty)
        #expect(signer.sentSignatures.isEmpty)
        let expectedOpenedTxIDs = opensPack ? [Constants.restoredTxID] : []
        #expect(provider.openedTxIDs == expectedOpenedTxIDs)
    }

    @Test("A purchase restored on another machine blocks a new order, also when its status cannot be read", arguments: [
        0,
        1,
    ])
    func restoredPurchaseBlocksOtherMachine(statusFailures: Int) async {
        let pendingPurchase = Self.pendingPurchase(.packPurchased, machineID: Constants.otherMachineID)
        let (sut, provider, _) = makeSUT(statusFailures: statusFailures, pendingPurchase: pendingPurchase)

        let failure = await failure(of: sut)

        #expect(failure == .anotherPurchaseInProgress)
        #expect(provider.generatedMachineIDs.isEmpty)
        #expect(sut.hasUnfinishedPurchase(machineID: Constants.otherMachineID))
    }

    @Test("A restored purchase awaits the payment until 100 seconds after the pack was created", arguments: [
        (secondsAgo: 300.0, expectedChecks: 1),
        (secondsAgo: 92.0, expectedChecks: 4),
    ])
    func restoredPaymentWaitCountsFromCreation(secondsAgo: TimeInterval, expectedChecks: Int) async {
        let createdAt = Constants.now.addingTimeInterval(-secondsAgo)
        let (sut, provider, _) = makeSUT(
            statuses: [Self.transaction(.waitingForPayment)],
            pendingPurchase: Self.pendingPurchase(.waitingForPayment, createdAt: createdAt)
        )

        let failure = await failure(of: sut)

        #expect(failure == .paymentTimedOut)
        #expect(provider.statusLoadsCount == expectedChecks)
    }

    @Test("A spin the partner no longer knows is a refund and frees the purchase")
    func unknownSpinIsRefund() async {
        let (sut, _, _) = makeSUT(
            statuses: [Self.transaction(.packPurchased)],
            openResults: [.failure(CollectiblesPackOpeningError.spinNotFound)]
        )

        let failure = await failure(of: sut)

        #expect(failure == .paymentFailed(.refunded))
        #expect(!sut.hasUnfinishedPurchase(machineID: Constants.machineID))
    }

    @Test("A restored purchase that is already over leaves the next order untouched", arguments: [
        CollectiblesPurchaseStatus.expired,
        CollectiblesPurchaseStatus.refunded,
    ])
    func finishedRestoredPurchaseIsIgnored(status: CollectiblesPurchaseStatus) async {
        let (sut, _, _) = makeSUT(pendingPurchase: Self.pendingPurchase(status))

        await sut.restorePendingPurchase()

        #expect(!sut.hasUnfinishedPurchase(machineID: Constants.machineID))
    }

    @Test("An order that never left the device does not block another machine")
    func unsentOrderDoesNotBlockOtherMachine() async throws {
        let (sut, provider, _) = makeSUT(sendResults: [.failure(.rejected(Constants.error)), .success(())])
        _ = await failure(of: sut)

        _ = try await purchase(sut, machineID: Constants.otherMachineID)

        #expect(provider.generatedMachineIDs == [Constants.machineID, Constants.otherMachineID])
        #expect(!sut.hasUnfinishedPurchase(machineID: Constants.machineID))
    }
}

// MARK: - Arguments

extension RemoteCollectiblesPackPurchaseInteractorTests {
    struct Units: Sendable {
        let amount: UInt64
        let feeAmount: UInt64
    }

    enum FailedStage: CaseIterable, Sendable {
        case payment
        case opening
        case prizeDelivery
    }

    enum FailingStep: CaseIterable, Sendable {
        case generation
        case signing
    }

    enum UndecidedSend: CaseIterable, Sendable {
        case expired
        case unknown

        var error: CollectiblesSendError {
            switch self {
            case .expired: .transactionExpired
            case .unknown: .outcomeUnknown
            }
        }
    }

    nonisolated static let priceArguments: [(price: Decimal, platformFee: Decimal, expected: Units)] = [
        (price: 25, platformFee: 1, expected: Units(amount: 25_000_000, feeAmount: 1_000_000)),
        (
            price: Decimal(sign: .plus, exponent: -1, significand: 255),
            platformFee: 0,
            expected: Units(amount: 25_500_000, feeAmount: 0)
        ),
    ]

    nonisolated static let invalidPriceArguments: [(price: Decimal, platformFee: Decimal)] = [
        (price: -1, platformFee: 1),
        (price: 25, platformFee: -1),
        (price: Decimal(UInt64.max), platformFee: 0),
    ]

    nonisolated static let failedStatuses: [CollectiblesPurchaseStatus] = [
        .expired,
        .refunded,
        .manuallyBuybacked,
    ]

    nonisolated static let closingStatuses: [CollectiblesPurchaseStatus] = [.paused] + failedStatuses

    nonisolated static let pendingStatuses: [CollectiblesPurchaseStatus] = [
        .created,
        .waitingTxHash,
        .purchaseTxHash,
        .waitingForPayment,
    ]

    nonisolated static let paidStatuses: [CollectiblesPurchaseStatus] = [.packPurchased, .packOpeningError]

    nonisolated static let rejections: [CollectiblesSendError] = [
        .rejected(Constants.error),
        .rejected(CollectiblesProgramRejection.paused),
    ]

    enum OrderStage: Sendable {
        case noOrder
        case signedOnly
        case refusedForSessionKey
        case sent

        var sendResult: Result<Void, CollectiblesSendError> {
            switch self {
            case .signedOnly: .failure(.rejected(Constants.error))
            case .refusedForSessionKey: .failure(.rejected(CollectiblesProgramRejection.unauthorized))
            case .noOrder, .sent: .success(())
            }
        }
    }
}

// MARK: - Helpers

private extension RemoteCollectiblesPackPurchaseInteractorTests {
    struct UnexpectedResult: Error {}

    enum Failure: Equatable {
        case accountNotReady
        case relinkRequired
        case lowInventory
        case invalidPrice
        case paymentFailed(CollectiblesPurchaseStatus)
        case paymentTimedOut
        case packUnopened
        case openFailed
        case prizeNotDelivered
        case anotherPurchaseInProgress
        case other
    }

    enum Constants {
        static let machineID = "pokemon_25"
        static let otherMachineID = "pokemon_50"
        static let txID = "01a119ee-18f5-72d1-8e0f-ed2518b4e1dc"
        static let restoredTxID = "02b229ff-29a6-83e2-9f1a-fe3629c5f2ed"
        static let now = Date(timeIntervalSince1970: 1_793_750_400)
        static let signature = "purchase-signature"
        static let gradingID = "63181346"
        static let price: Decimal = 25
        static let platformFee: Decimal = 1
        static let buybackAmount: Decimal = 35.6
        static let addresses = CollectiblesPurchaseAddresses(player: "player", prizeRecipient: "recipient")
        static let error = URLError(.timedOut)
        static let statusFailures = 3
        static let paymentChecks = 50
        static let openAttempts = 5
    }

    nonisolated static let deliveredTransaction = CollectiblesPurchaseTransaction(
        status: .nftReceived,
        wonCard: CollectiblesWonCard(
            nftAddress: "nft-1",
            imageFrontURL: nil,
            imageBackURL: nil,
            gradingCompany: "PSA",
            grade: "GEM-MT 10",
            gradingID: Constants.gradingID,
            rarity: .common,
            year: "2005",
            set: nil,
            serialNumber: nil,
            insuredValue: 49
        )
    )

    nonisolated static let paidAndDelivered = [transaction(.packPurchased), deliveredTransaction]

    static let openedTransaction = CollectiblesPurchaseTransaction(
        status: .packOpened,
        wonCard: deliveredTransaction.wonCard
    )

    nonisolated static func transaction(_ status: CollectiblesPurchaseStatus) -> CollectiblesPurchaseTransaction {
        CollectiblesPurchaseTransaction(status: status, wonCard: nil)
    }

    static func pendingPurchase(
        _ status: CollectiblesPurchaseStatus,
        txID: String = Constants.restoredTxID,
        machineID: String = Constants.machineID,
        createdAt: Date = Constants.now
    ) -> CollectiblesPendingPurchase {
        CollectiblesPendingPurchase(
            txID: txID,
            machineID: machineID,
            status: status,
            createdAt: createdAt
        )
    }

    func makeSUT(
        addresses: CollectiblesPurchaseAddresses? = Constants.addresses,
        relinkReads: [Bool] = [false],
        freshReadError: (any Error)? = nil,
        generateError: (any Error)? = nil,
        signError: (any Error)? = nil,
        sendResults: [Result<Void, CollectiblesSendError>] = [.success(())],
        reportResults: [Result<CollectiblesPurchaseStatus, any Error>] = [.success(.purchaseTxHash)],
        statuses: [CollectiblesPurchaseTransaction] = paidAndDelivered,
        statusFailures: Int = 0,
        openResults: [Result<CollectiblesPurchaseTransaction, any Error>] = [.success(transaction(.packOpened))],
        pendingPurchase: CollectiblesPendingPurchase? = nil
    ) -> (SUT, PurchaseProviderStub, PurchaseSignerStub) {
        let provider = PurchaseProviderStub(
            generateError: generateError,
            reportResults: reportResults,
            statuses: statuses,
            statusFailures: statusFailures,
            openResults: openResults,
            pendingPurchase: pendingPurchase
        )
        let signer = PurchaseSignerStub(
            addresses: addresses,
            relinkReads: relinkReads,
            freshReadError: freshReadError,
            signError: signError,
            sendResults: sendResults
        )
        let sut = SUT(
            generator: provider,
            signer: signer,
            sentReporter: provider,
            statusProvider: provider,
            opener: provider,
            pendingPurchaseProvider: provider,
            delayProvider: InstantPollDelayProvider(),
            dateProvider: FixedDateProvider(now: Constants.now)
        )
        return (trackForMemoryLeaks(sut), provider, signer)
    }

    func makeSUT(
        failingAt stage: FailedStage,
        with status: CollectiblesPurchaseStatus
    ) -> (SUT, PurchaseProviderStub, PurchaseSignerStub) {
        switch stage {
        case .payment:
            makeSUT(statuses: [Self.transaction(status)])
        case .opening:
            makeSUT(openResults: [.success(Self.transaction(status))])
        case .prizeDelivery:
            makeSUT(statuses: [Self.transaction(.packPurchased), Self.transaction(status)])
        }
    }

    func purchase(
        _ sut: SUT,
        machineID: String = Constants.machineID,
        price: Decimal = Constants.price,
        platformFee: Decimal = Constants.platformFee,
        isTurboModeOn: Bool = false,
        onStep: @escaping (CollectiblesPackPurchaseStep) -> Void = { _ in }
    ) async throws -> CollectiblesWonCard {
        let result = try await sut.purchase(
            machineID: machineID,
            price: price,
            platformFee: platformFee,
            isTurboModeOn: isTurboModeOn,
            onStep: onStep
        )

        guard case .wonCard(let wonCard) = result else {
            throw UnexpectedResult()
        }

        return wonCard
    }

    func sold(by sut: SUT) async throws -> (amount: Decimal?, wonCard: CollectiblesWonCard?) {
        let result = try await sut.purchase(
            machineID: Constants.machineID,
            price: Constants.price,
            platformFee: Constants.platformFee,
            isTurboModeOn: true,
            onStep: { _ in }
        )

        guard case .autoSold(let amount, let wonCard) = result else {
            throw UnexpectedResult()
        }

        return (amount: amount, wonCard: wonCard)
    }

    func failure(
        of sut: SUT,
        machineID: String = Constants.machineID,
        price: Decimal = Constants.price,
        platformFee: Decimal = Constants.platformFee
    ) async -> Failure? {
        do {
            _ = try await purchase(sut, machineID: machineID, price: price, platformFee: platformFee)
            return nil
        } catch let error as CollectiblesPackPurchaseError {
            switch error {
            case .accountNotReady: return .accountNotReady
            case .relinkRequired: return .relinkRequired
            case .lowInventory: return .lowInventory
            case .invalidPrice: return .invalidPrice
            case .paymentFailed(let status): return .paymentFailed(status)
            case .paymentTimedOut: return .paymentTimedOut
            case .packUnopened: return .packUnopened
            case .openFailed: return .openFailed
            case .prizeNotDelivered: return .prizeNotDelivered
            case .anotherPurchaseInProgress: return .anotherPurchaseInProgress
            }
        } catch {
            return .other
        }
    }
}

// MARK: - Stubs

@MainActor
private final class PurchaseProviderStub: CollectiblesPurchaseGenerator, CollectiblesPurchaseSentReporter,
    CollectiblesPurchaseStatusProvider, CollectiblesPackOpener, CollectiblesPendingPurchaseProvider {
    var statuses: [CollectiblesPurchaseTransaction]
    var openResults: [Result<CollectiblesPurchaseTransaction, any Error>]
    var pendingPurchase: CollectiblesPendingPurchase?
    var pendingPurchaseError: (any Error)?
    var pendingLookupGate: LookupGate?

    private(set) var generatedMachineIDs: [String] = []
    private(set) var generatedAddresses: [CollectiblesPurchaseAddresses] = []
    private(set) var generatedTurboModes: [CollectiblesTurboMode] = []
    private(set) var reportedHashes: [String] = []
    private(set) var openedTxIDs: [String] = []
    private(set) var statusLoadsCount = 0

    private let generateError: (any Error)?
    private var reportResults: [Result<CollectiblesPurchaseStatus, any Error>]
    private var statusFailures: Int

    init(
        generateError: (any Error)?,
        reportResults: [Result<CollectiblesPurchaseStatus, any Error>],
        statuses: [CollectiblesPurchaseTransaction],
        statusFailures: Int,
        openResults: [Result<CollectiblesPurchaseTransaction, any Error>],
        pendingPurchase: CollectiblesPendingPurchase?
    ) {
        self.generateError = generateError
        self.reportResults = reportResults
        self.statuses = statuses
        self.statusFailures = statusFailures
        self.openResults = openResults
        self.pendingPurchase = pendingPurchase
    }

    func load() async throws -> CollectiblesPendingPurchase? {
        let pendingPurchase = pendingPurchase

        if let gate = pendingLookupGate {
            pendingLookupGate = nil
            await gate.pass()
        }

        if let pendingPurchaseError {
            throw pendingPurchaseError
        }

        return pendingPurchase
    }

    func generate(
        machineID: String,
        fromAddress: String,
        toAddress: String,
        turboMode: CollectiblesTurboMode
    ) async throws -> CollectiblesGeneratedPurchase {
        generatedMachineIDs.append(machineID)
        generatedTurboModes.append(turboMode)
        generatedAddresses.append(CollectiblesPurchaseAddresses(player: fromAddress, prizeRecipient: toAddress))

        if let generateError {
            throw generateError
        }

        return CollectiblesGeneratedPurchase(
            txID: RemoteCollectiblesPackPurchaseInteractorTests.Constants.txID,
            purchase: CollectiblesPackPurchase(memo: "memo", usdcMint: "mint", amount: 0, feeAmount: 0)
        )
    }

    func report(txID: String, txHash: String) async throws -> CollectiblesPurchaseStatus {
        reportedHashes.append(txHash)
        return try Self.next(from: &reportResults).get()
    }

    func load(txID: String) async throws -> CollectiblesPurchaseTransaction {
        statusLoadsCount += 1

        guard statusFailures == 0 else {
            statusFailures -= 1
            throw RemoteCollectiblesPackPurchaseInteractorTests.Constants.error
        }

        return Self.next(from: &statuses)
    }

    func open(txID: String) async throws -> CollectiblesPurchaseTransaction {
        openedTxIDs.append(txID)
        return try Self.next(from: &openResults).get()
    }

    private static func next<T>(from script: inout [T]) -> T {
        script.count > 1 ? script.removeFirst() : script[0]
    }
}

@MainActor
private final class PurchaseSignerStub: CollectiblesPurchaseSigner {
    nonisolated let purchaseAddresses: CollectiblesPurchaseAddresses?

    nonisolated var isRelinkRequired: Bool {
        isRelinkRequiredState.withLock { $0 }
    }

    private(set) var confirmedPrices: [CollectiblesConfirmedPrice] = []
    private(set) var sentSignatures: [String] = []

    private let isRelinkRequiredState = OSAllocatedUnfairLock(initialState: false)
    private let freshReadError: (any Error)?
    private let signError: (any Error)?
    private var relinkReads: [Bool]
    private var sendResults: [Result<Void, CollectiblesSendError>]

    init(
        addresses: CollectiblesPurchaseAddresses?,
        relinkReads: [Bool] = [false],
        freshReadError: (any Error)? = nil,
        signError: (any Error)? = nil,
        sendResults: [Result<Void, CollectiblesSendError>]
    ) {
        purchaseAddresses = addresses
        self.relinkReads = relinkReads
        self.freshReadError = freshReadError
        self.signError = signError
        self.sendResults = sendResults
    }

    func resolveRelinkRequirement() async throws -> Bool {
        if let freshReadError {
            throw freshReadError
        }

        return relinkReads.count > 1 ? relinkReads.removeFirst() : relinkReads[0]
    }

    func setRelinkRequired(_ isRelinkRequired: Bool) {
        isRelinkRequiredState.withLock { $0 = isRelinkRequired }
    }

    func signPurchase(
        _ purchase: CollectiblesPackPurchase,
        confirmedPrice: CollectiblesConfirmedPrice
    ) async throws -> CollectiblesSignedPurchase {
        confirmedPrices.append(confirmedPrice)

        if let signError {
            throw signError
        }

        return CollectiblesSignedPurchase(
            signature: RemoteCollectiblesPackPurchaseInteractorTests.Constants.signature,
            amount: confirmedPrice.amount,
            feeAmount: confirmedPrice.feeAmount,
            serializedTransaction: Data(),
            blockhashFetchedAt: Date(timeIntervalSince1970: 0)
        )
    }

    func sendPurchase(_ signedPurchase: CollectiblesSignedPurchase) async throws(CollectiblesSendError) {
        sentSignatures.append(signedPurchase.signature)

        let result = sendResults.count > 1 ? sendResults.removeFirst() : sendResults[0]

        if case .failure(let error) = result {
            throw error
        }
    }
}

@MainActor
private final class LookupGate {
    let arrivals: AsyncStream<Void>

    private let arrival: AsyncStream<Void>.Continuation
    private var isOpen = false
    private var waiter: CheckedContinuation<Void, Never>?

    init() {
        (arrivals, arrival) = AsyncStream.makeStream(of: Void.self)
    }

    func pass() async {
        arrival.yield()

        guard !isOpen else {
            return
        }

        await withCheckedContinuation { waiter = $0 }
    }

    func open() {
        isOpen = true
        waiter?.resume()
        waiter = nil
    }
}
