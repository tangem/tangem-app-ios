//
//  RemoteCollectiblesBuybackInteractorTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import TangemCollectibles
@testable import Tangem

@Suite("RemoteCollectiblesBuybackInteractor", .timeLimit(.minutes(1)))
@MainActor
struct RemoteCollectiblesBuybackInteractorTests {
    typealias SUT = RemoteCollectiblesBuybackInteractor

    // MARK: - Happy path

    @Test("Walks every step: builds, checks the size, signs, sends, reports and waits for the confirmation")
    func completesSale() async throws {
        let (sut, backend, signer, limits) = makeSUT()

        try await sell(sut)

        #expect(backend.generations == [Constants.generation])
        #expect(limits.checkedTransactions == [Constants.transaction])
        #expect(signer.signedTransactions == [Constants.transaction])
        #expect(signer.sentSignatures == [Constants.signature])
        #expect(backend.reports == [Constants.report])
        #expect(backend.statusLoadsCount == 1)
    }

    @Test("The card and the shown price in USDC base units are the terms the signer verifies")
    func signsShownPrice() async throws {
        let (sut, _, signer, _) = makeSUT()

        try await sell(sut)

        let terms = try #require(signer.terms.first)
        #expect(terms.nftAddress == Constants.nftAddress)
        #expect(terms.minimumPayoutInBaseUnits == Constants.offerInBaseUnits)
    }

    // MARK: - Before the transaction

    @Test("Refuses to start while the account has no buyback addresses")
    func refusesWithoutAddresses() async {
        let (sut, backend, _, _) = makeSUT(addresses: nil)

        await #expect(throws: CollectiblesBuybackSaleError.accountNotReady) {
            try await sell(sut)
        }
        #expect(backend.generations.isEmpty)
    }

    @Test("Refuses an offer without a positive price", arguments: [Decimal(0), Decimal(-1)])
    func refusesOfferWithoutPrice(amount: Decimal) async {
        let (sut, backend, _, _) = makeSUT()

        await #expect(throws: CollectiblesBuybackSaleError.failed) {
            try await sell(sut, offer: Self.offer(amount))
        }
        #expect(backend.generations.isEmpty)
    }

    @Test("A transaction the backend fails to build ends the sale before signing")
    func failedGenerationEndsSale() async {
        let (sut, _, signer, _) = makeSUT(generateError: Constants.error)

        await #expect(throws: CollectiblesBuybackSaleError.failed) {
            try await sell(sut)
        }
        #expect(signer.signedTransactions.isEmpty)
    }

    @Test("A transaction the card cannot sign is not sent to it", arguments: SizeVerdict.allCases)
    func refusesTransactionBeyondCardLimit(verdict: SizeVerdict) async {
        let (sut, _, signer, limits) = makeSUT(sizeVerdict: verdict.result)

        await #expect(throws: CollectiblesBuybackSaleError.failed) {
            try await sell(sut)
        }
        #expect(limits.checkedTransactions == [Constants.transaction])
        #expect(signer.signedTransactions.isEmpty)
    }

    @Test("A signing failure ends the sale without sending anything")
    func failedSigningEndsSale() async {
        let (sut, _, signer, _) = makeSUT(signError: Constants.error)

        await #expect(throws: CollectiblesBuybackSaleError.failed) {
            try await sell(sut)
        }
        #expect(signer.sentSignatures.isEmpty)
    }

    @Test("A cancelled step ends the sale as a cancellation, not as a failure", arguments: CancelledStep.allCases)
    func cancellationIsPassedThrough(step: CancelledStep) async {
        let (sut, _, _, _) = makeSUT(
            generateError: step == .generation ? CancellationError() : nil,
            signError: step == .signing ? CancellationError() : nil,
            reportError: step == .report ? CancellationError() : nil
        )

        await #expect(throws: CancellationError.self) {
            try await sell(sut)
        }
    }

    @Test("A cancelled network request counts as a cancellation too")
    func cancelledRequestIsPassedThrough() async {
        let (sut, _, _, _) = makeSUT(generateError: URLError(.cancelled))

        await #expect(throws: CancellationError.self) {
            try await sell(sut)
        }
    }

    // MARK: - Sending

    @Test("An expired or unknown send outcome is left to the backend status", arguments: UndecidedSend.allCases)
    func undecidedSendIsLeftToStatus(send: UndecidedSend) async throws {
        let (sut, backend, _, _) = makeSUT(sendResult: .failure(send.error))

        try await sell(sut)

        #expect(backend.reports == [Constants.report])
        #expect(backend.statusLoadsCount == 1)
    }

    @Test("A node rejection ends the sale before the backend hears about it")
    func rejectedSendEndsSale() async {
        let (sut, backend, _, _) = makeSUT(sendResult: .failure(.rejected(Constants.error)))

        await #expect(throws: CollectiblesBuybackSaleError.failed) {
            try await sell(sut)
        }
        #expect(backend.reports.isEmpty)
        #expect(backend.statusLoadsCount == 0)
    }

    @Test("A lost report does not stop the sale: the status decides")
    func lostReportIsNotFatal() async throws {
        let (sut, backend, _, _) = makeSUT(reportError: Constants.error)

        try await sell(sut)

        #expect(backend.reports == [Constants.report])
        #expect(backend.statusLoadsCount == 1)
    }

    // MARK: - Confirmation

    @Test("A status that is still in progress keeps the confirmation awaited", arguments: Self.pendingStatuses)
    func waitsThroughPendingStatus(status: CollectiblesBuybackStatus) async throws {
        let (sut, backend, _, _) = makeSUT(statuses: [status, .confirmed])

        try await sell(sut)

        #expect(backend.statusLoadsCount == 2)
    }

    @Test("An expired buyback ends the sale as not confirmed at once")
    func expiredStatusEndsSale() async {
        let (sut, backend, _, _) = makeSUT(statuses: [.expired, .confirmed])

        await #expect(throws: CollectiblesBuybackSaleError.notConfirmed) {
            try await sell(sut)
        }
        #expect(backend.statusLoadsCount == 1)
    }

    @Test("A buyback that never confirms in time ends the sale as not confirmed")
    func unconfirmedStatusTimesOut() async {
        let (sut, backend, _, _) = makeSUT(statuses: [.confirming])

        await #expect(throws: CollectiblesBuybackSaleError.notConfirmed) {
            try await sell(sut)
        }
        #expect(backend.statusLoadsCount == Constants.statusChecks)
    }

    @Test("Status request failures are retried, not taken for a lost sale")
    func statusFailuresAreRetried() async throws {
        let (sut, backend, _, _) = makeSUT(statusFailures: 2)

        try await sell(sut)

        #expect(backend.statusLoadsCount == 3)
    }

    @Test("Cancelling the sale while the status is awaited ends it as a cancellation")
    func cancelledWhileAwaitingStatus() async {
        let (sut, backend, _, _) = makeSUT(statuses: [.confirming], holdsStatus: true)
        let sale = Task { try await sell(sut) }

        await waitUntil { backend.statusLoadsCount == 1 }
        sale.cancel()

        await #expect(throws: CancellationError.self) {
            try await sale.value
        }
    }
}

// MARK: - Arguments

extension RemoteCollectiblesBuybackInteractorTests {
    enum SizeVerdict: CaseIterable, Sendable {
        case tooLarge
        case unreadable

        var result: Result<Bool, any Error> {
            switch self {
            case .tooLarge: .success(false)
            case .unreadable: .failure(Constants.error)
            }
        }
    }

    enum CancelledStep: CaseIterable, Sendable {
        case generation
        case signing
        case report
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
}

// MARK: - Helpers

private extension RemoteCollectiblesBuybackInteractorTests {
    struct Generation: Equatable {
        let nftAddress: String
        let fromAddress: String
        let toAddress: String
    }

    struct Report: Equatable {
        let buybackID: String
        let txHash: String
    }

    enum Constants {
        static let nftAddress = "nft-1"
        static let addresses = CollectiblesBuybackAddresses(owner: "owner-1", payoutRecipient: "vault-1")
        static let offer = CollectiblesBuybackOffer(amount: Decimal(string: "12.75")!, expiresAt: nil)
        static let offerInBaseUnits: UInt64 = 12_750_000
        static let backendAmount: Decimal = 1
        static let transaction = Data([1, 2, 3])
        static let buybackID = "buyback-1"
        static let signature = "signature-1"
        static let statusChecks = 5
        static let error = URLError(.badServerResponse)
        static let generation = Generation(
            nftAddress: nftAddress,
            fromAddress: addresses.owner,
            toAddress: addresses.payoutRecipient
        )
        static let report = Report(buybackID: buybackID, txHash: signature)
    }

    nonisolated static let pendingStatuses: [CollectiblesBuybackStatus] = [
        .created,
        .waitingTxHash,
        .buybackTxSent,
        .confirming,
        .unknown("manually-buybacked"),
    ]

    static func offer(_ amount: Decimal) -> CollectiblesBuybackOffer {
        CollectiblesBuybackOffer(amount: amount, expiresAt: nil)
    }

    func makeSUT(
        addresses: CollectiblesBuybackAddresses? = Constants.addresses,
        generateError: (any Error)? = nil,
        sizeVerdict: Result<Bool, any Error> = .success(true),
        signError: (any Error)? = nil,
        sendResult: Result<Void, CollectiblesSendError> = .success(()),
        reportError: (any Error)? = nil,
        statuses: [CollectiblesBuybackStatus] = [.confirmed],
        statusFailures: Int = 0,
        holdsStatus: Bool = false
    ) -> (SUT, BuybackBackendStub, BuybackSignerStub, SigningLimitsStub) {
        let backend = BuybackBackendStub(
            generateError: generateError,
            reportError: reportError,
            statuses: statuses,
            statusFailures: statusFailures,
            holdsStatus: holdsStatus
        )
        let signer = BuybackSignerStub(addresses: addresses, signError: signError, sendResult: sendResult)
        let limits = SigningLimitsStub(verdict: sizeVerdict)
        let sut = SUT(
            generator: backend,
            signer: signer,
            signingLimits: limits,
            sentReporter: backend,
            statusProvider: backend,
            delayProvider: InstantPollDelayProvider()
        )
        return (sut, backend, signer, limits)
    }

    func sell(_ sut: SUT, offer: CollectiblesBuybackOffer = Constants.offer) async throws {
        try await sut.sell(nftAddress: Constants.nftAddress, offer: offer)
    }

    func waitUntil(timeout: Duration = .seconds(5), _ condition: @escaping @MainActor () -> Bool) async {
        let deadline = ContinuousClock.now + timeout
        while !condition() {
            if ContinuousClock.now >= deadline {
                Issue.record("waitUntil timed out")
                return
            }

            do {
                try await Task.sleep(for: .milliseconds(10))
            } catch {
                return
            }
        }
    }
}

// MARK: - Stubs

@MainActor
private final class BuybackBackendStub: CollectiblesBuybackTransactionGenerator, CollectiblesBuybackSentReporter,
    CollectiblesBuybackStatusProvider {
    typealias Constants = RemoteCollectiblesBuybackInteractorTests.Constants

    private(set) var generations: [RemoteCollectiblesBuybackInteractorTests.Generation] = []
    private(set) var reports: [RemoteCollectiblesBuybackInteractorTests.Report] = []
    private(set) var statusLoadsCount = 0

    private let generateError: (any Error)?
    private let reportError: (any Error)?
    private var statuses: [CollectiblesBuybackStatus]
    private var statusFailures: Int
    private let holdsStatus: Bool

    init(
        generateError: (any Error)?,
        reportError: (any Error)?,
        statuses: [CollectiblesBuybackStatus],
        statusFailures: Int,
        holdsStatus: Bool
    ) {
        self.generateError = generateError
        self.reportError = reportError
        self.statuses = statuses
        self.statusFailures = statusFailures
        self.holdsStatus = holdsStatus
    }

    func generate(
        nftAddress: String,
        fromAddress: String,
        toAddress: String
    ) async throws -> CollectiblesBuybackTransaction {
        generations.append(.init(nftAddress: nftAddress, fromAddress: fromAddress, toAddress: toAddress))

        if let generateError {
            throw generateError
        }

        return CollectiblesBuybackTransaction(
            buybackID: Constants.buybackID,
            memo: "memo",
            amount: Constants.backendAmount,
            transaction: Constants.transaction
        )
    }

    func report(buybackID: String, txHash: String) async throws {
        reports.append(.init(buybackID: buybackID, txHash: txHash))

        if let reportError {
            throw reportError
        }
    }

    func load(buybackID: String) async throws -> CollectiblesBuybackStatus {
        statusLoadsCount += 1

        if holdsStatus {
            try await Task.sleep(for: .seconds(60))
        }

        guard statusFailures == 0 else {
            statusFailures -= 1
            throw Constants.error
        }

        return statuses.count > 1 ? statuses.removeFirst() : statuses[0]
    }
}

@MainActor
private final class BuybackSignerStub: CollectiblesBuybackSigner {
    typealias Constants = RemoteCollectiblesBuybackInteractorTests.Constants

    nonisolated let buybackAddresses: CollectiblesBuybackAddresses?

    private(set) var signedTransactions: [Data] = []
    private(set) var terms: [CollectiblesBuybackTerms] = []
    private(set) var sentSignatures: [String] = []

    private let signError: (any Error)?
    private let sendResult: Result<Void, CollectiblesSendError>

    init(
        addresses: CollectiblesBuybackAddresses?,
        signError: (any Error)?,
        sendResult: Result<Void, CollectiblesSendError>
    ) {
        buybackAddresses = addresses
        self.signError = signError
        self.sendResult = sendResult
    }

    func signBuyback(
        _ preparedTransaction: Data,
        terms: CollectiblesBuybackTerms
    ) async throws -> CollectiblesSignedBuyback {
        signedTransactions.append(preparedTransaction)
        self.terms.append(terms)

        if let signError {
            throw signError
        }

        return CollectiblesSignedBuyback(
            signature: Constants.signature,
            serializedTransaction: preparedTransaction,
            receivedAt: Date(timeIntervalSince1970: 0)
        )
    }

    func sendBuyback(_ signedBuyback: CollectiblesSignedBuyback) async throws(CollectiblesSendError) {
        sentSignatures.append(signedBuyback.signature)

        if case .failure(let error) = sendResult {
            throw error
        }
    }
}

private final class SigningLimitsStub: CollectiblesBuybackSigningLimits {
    private let state: OSAllocatedUnfairLock<[Data]>
    private let verdict: Result<Bool, any Error>

    var checkedTransactions: [Data] {
        state.withLock { $0 }
    }

    init(verdict: Result<Bool, any Error>) {
        self.verdict = verdict
        state = OSAllocatedUnfairLock(initialState: [])
    }

    func canSign(_ transaction: Data) throws -> Bool {
        state.withLock { $0.append(transaction) }
        return try verdict.get()
    }
}
