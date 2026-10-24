//
//  CommonCollectiblesPackPurchaseInteractorTests.swift
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

@Suite("CommonCollectiblesPackPurchaseInteractor", .timeLimit(.minutes(1)))
@MainActor
final class CommonCollectiblesPackPurchaseInteractorTests: LeakTrackingTestSuite {
    typealias SUT = CommonCollectiblesPackPurchaseInteractor

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

    @Test("A node rejection keeps the signed order, the retry sends the same transaction")
    func rejectionResendsSameOrder() async throws {
        let (sut, provider, signer) = makeSUT(sendResults: [.failure(.rejected(Constants.error)), .success(())])

        let failure = await failure(of: sut)
        #expect(failure == .other)

        _ = try await purchase(sut)

        #expect(provider.generatedMachineIDs.count == 1)
        #expect(signer.sentSignatures == [Constants.signature, Constants.signature])
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

    @Test("A failed report is retried without sending the transaction again")
    func failedReportDoesNotResend() async throws {
        let (sut, provider, signer) = makeSUT(reportResults: [.failure(Constants.error), .success(.purchaseTxHash)])

        let failure = await failure(of: sut)
        #expect(failure == .other)
        #expect(sut.hasUnfinishedPurchase(machineID: Constants.machineID))

        var steps: [CollectiblesPackPurchaseStep] = []
        _ = try await purchase(sut) { steps.append($0) }

        #expect(steps == [.generating, .confirming, .opening])
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

        #expect(steps == [.generating, .confirming, .opening])
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

    // MARK: - Opening

    @Test("A pack that fails to open is opened again on retry without paying twice")
    func openFailureResumes() async throws {
        let (sut, provider, signer) = makeSUT(openResults: [.failure(Constants.error)])

        let failure = await failure(of: sut)

        #expect(failure == .openFailed)
        #expect(provider.openedTxIDs.count == Constants.openAttempts)

        provider.openResults = [.success(.packOpened)]
        var steps: [CollectiblesPackPurchaseStep] = []
        _ = try await purchase(sut) { steps.append($0) }

        #expect(steps == [.generating, .opening])
        #expect(signer.sentSignatures.count == 1)
        #expect(provider.openedTxIDs.last == Constants.txID)
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

    // MARK: - Another machine

    @Test("A sent order on one machine blocks a purchase on another")
    func sentOrderBlocksOtherMachine() async {
        let (sut, provider, _) = makeSUT(statuses: [Self.transaction(.waitingForPayment)])
        _ = await failure(of: sut)

        let failure = await failure(of: sut, machineID: Constants.otherMachineID)

        #expect(failure == .anotherPurchaseInProgress)
        #expect(provider.generatedMachineIDs == [Constants.machineID])
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

extension CommonCollectiblesPackPurchaseInteractorTests {
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

        var error: CollectiblesPurchaseError {
            switch self {
            case .expired: .transactionExpired
            case .unknown: .sendOutcomeUnknown
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

    nonisolated static let failedStatuses: [CollectiblesPurchaseStatus] = [.expired, .refunded]

    nonisolated static let pendingStatuses: [CollectiblesPurchaseStatus] = [
        .created,
        .waitingTxHash,
        .purchaseTxHash,
        .waitingForPayment,
        .paused,
        .unknown("new-status"),
    ]

    nonisolated static let paidStatuses: [CollectiblesPurchaseStatus] = [.packPurchased, .packOpeningError]
}

// MARK: - Helpers

private extension CommonCollectiblesPackPurchaseInteractorTests {
    enum Failure: Equatable {
        case accountNotReady
        case invalidPrice
        case paymentFailed(CollectiblesPurchaseStatus)
        case paymentTimedOut
        case openFailed
        case prizeNotDelivered
        case anotherPurchaseInProgress
        case other
    }

    enum Constants {
        static let machineID = "pokemon_25"
        static let otherMachineID = "pokemon_50"
        static let txID = "01a119ee-18f5-72d1-8e0f-ed2518b4e1dc"
        static let signature = "purchase-signature"
        static let gradingID = "63181346"
        static let price: Decimal = 25
        static let platformFee: Decimal = 1
        static let addresses = CollectiblesPurchaseAddresses(payer: "payer", prizeRecipient: "recipient")
        static let error = URLError(.timedOut)
        static let statusFailures = 3
        static let paymentChecks = 50
        static let openAttempts = 5
    }

    nonisolated static let deliveredTransaction = CollectiblesPurchaseTransaction(
        status: .nftReceived,
        wonCard: CollectiblesWonCard(
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

    nonisolated static func transaction(_ status: CollectiblesPurchaseStatus) -> CollectiblesPurchaseTransaction {
        CollectiblesPurchaseTransaction(status: status, wonCard: nil)
    }

    func makeSUT(
        addresses: CollectiblesPurchaseAddresses? = Constants.addresses,
        generateError: (any Error)? = nil,
        signError: (any Error)? = nil,
        sendResults: [Result<Void, CollectiblesPurchaseError>] = [.success(())],
        reportResults: [Result<CollectiblesPurchaseStatus, any Error>] = [.success(.purchaseTxHash)],
        statuses: [CollectiblesPurchaseTransaction] = paidAndDelivered,
        statusFailures: Int = 0,
        openResults: [Result<CollectiblesPurchaseStatus, any Error>] = [.success(.packOpened)]
    ) -> (SUT, PurchaseProviderStub, PurchaseSignerStub) {
        let provider = PurchaseProviderStub(
            generateError: generateError,
            reportResults: reportResults,
            statuses: statuses,
            statusFailures: statusFailures,
            openResults: openResults
        )
        let signer = PurchaseSignerStub(addresses: addresses, signError: signError, sendResults: sendResults)
        let sut = SUT(
            generator: provider,
            signer: signer,
            sentReporter: provider,
            statusProvider: provider,
            opener: provider,
            delayProvider: InstantPollDelayProvider()
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
            makeSUT(openResults: [.success(status)])
        case .prizeDelivery:
            makeSUT(statuses: [Self.transaction(.packPurchased), Self.transaction(status)])
        }
    }

    func purchase(
        _ sut: SUT,
        machineID: String = Constants.machineID,
        price: Decimal = Constants.price,
        platformFee: Decimal = Constants.platformFee,
        onStep: @escaping (CollectiblesPackPurchaseStep) -> Void = { _ in }
    ) async throws -> CollectiblesWonCard {
        try await sut.purchase(
            machineID: machineID,
            price: price,
            platformFee: platformFee,
            turboMode: .off,
            onStep: onStep
        )
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
            case .invalidPrice: return .invalidPrice
            case .paymentFailed(let status): return .paymentFailed(status)
            case .paymentTimedOut: return .paymentTimedOut
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
    CollectiblesPurchaseStatusProvider, CollectiblesPackOpener {
    var statuses: [CollectiblesPurchaseTransaction]
    var openResults: [Result<CollectiblesPurchaseStatus, any Error>]

    private(set) var generatedMachineIDs: [String] = []
    private(set) var generatedAddresses: [CollectiblesPurchaseAddresses] = []
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
        openResults: [Result<CollectiblesPurchaseStatus, any Error>]
    ) {
        self.generateError = generateError
        self.reportResults = reportResults
        self.statuses = statuses
        self.statusFailures = statusFailures
        self.openResults = openResults
    }

    func generate(
        machineID: String,
        fromAddress: String,
        toAddress: String,
        turboMode: CollectiblesTurboMode
    ) async throws -> CollectiblesGeneratedPurchase {
        generatedMachineIDs.append(machineID)
        generatedAddresses.append(CollectiblesPurchaseAddresses(payer: fromAddress, prizeRecipient: toAddress))

        if let generateError {
            throw generateError
        }

        return CollectiblesGeneratedPurchase(
            txID: CommonCollectiblesPackPurchaseInteractorTests.Constants.txID,
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
            throw CommonCollectiblesPackPurchaseInteractorTests.Constants.error
        }

        return Self.next(from: &statuses)
    }

    func open(txID: String) async throws -> CollectiblesPurchaseStatus {
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

    private(set) var confirmedPrices: [CollectiblesConfirmedPrice] = []
    private(set) var sentSignatures: [String] = []

    private let signError: (any Error)?
    private var sendResults: [Result<Void, CollectiblesPurchaseError>]

    init(
        addresses: CollectiblesPurchaseAddresses?,
        signError: (any Error)? = nil,
        sendResults: [Result<Void, CollectiblesPurchaseError>]
    ) {
        purchaseAddresses = addresses
        self.signError = signError
        self.sendResults = sendResults
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
            signature: CommonCollectiblesPackPurchaseInteractorTests.Constants.signature,
            amount: confirmedPrice.amount,
            feeAmount: confirmedPrice.feeAmount,
            serializedTransaction: Data(),
            blockhashFetchedAt: Date(timeIntervalSince1970: 0)
        )
    }

    func sendPurchase(_ signedPurchase: CollectiblesSignedPurchase) async throws(CollectiblesPurchaseError) {
        sentSignatures.append(signedPurchase.signature)

        let result = sendResults.count > 1 ? sendResults.removeFirst() : sendResults[0]

        if case .failure(let error) = result {
            throw error
        }
    }
}
