//
//  PolymarketOrderPlacementServiceTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Combine
import Foundation
import Testing
import TangemFoundation
import TangemPolymarket
@testable import Tangem

@MainActor
@Suite("Polymarket delayed order settlement", .timeLimit(.minutes(1)))
struct PolymarketOrderPlacementServiceTests {
    @Test("An order the exchange took at once is handed back as it is, without reading it again")
    func immediatePlacementIsReturnedAsIs() async throws {
        let placement = PolymarketOrderPlacement(
            orderId: Self.orderId,
            status: .matched,
            makingAmount: 100,
            takingAmount: 138,
            transactionHashes: ["0xhash"]
        )
        let placer = OrderPlacerSpy(placement: .success(placement))

        let result = try await place(with: placer)

        #expect(result == placement)
        #expect(placer.orderReads == 0)
    }

    @Test("A delayed order that later matches is reported with what it filled")
    func delayedOrderSettles() async throws {
        let record = PolymarketOrderRecord(status: .matched, originalSize: 138, matchedSize: 138, price: Decimal(string: "0.72")!)
        let placer = OrderPlacerSpy(records: [.success(Self.record(.live)), .success(record)])

        let result = try await place(with: placer)

        #expect(result == .settled(record, orderId: Self.orderId, side: Self.quote.side))
        #expect(result.takingAmount == 138)
        #expect(placer.orderReads == 2)
    }

    @Test(
        "A delayed order the exchange dropped is a rejection, not an unknown outcome",
        arguments: [PolymarketOrderRecordStatus.canceled, .canceledMarketResolved, .invalid]
    )
    func droppedDelayedOrderIsRejected(_ status: PolymarketOrderRecordStatus) async throws {
        let placer = OrderPlacerSpy(records: [.success(Self.record(status))])

        let error = try await #require(throws: PolymarketOrderPlacementError.self) {
            try await place(with: placer)
        }

        #expect(error.isRejected)
    }

    @Test("A delayed order that can't be read back has an unknown outcome")
    func unreadableDelayedOrderIsAmbiguous() async throws {
        let placer = OrderPlacerSpy(records: [.failure(StubError())])

        let error = try await #require(throws: PolymarketOrderPlacementError.self) {
            try await place(with: placer)
        }

        #expect(error.isAmbiguous)
        #expect(placer.orderReads == 1)
    }

    @Test(
        "A read the network or the server failed, timed out or throttled is repeated within the wait",
        arguments: [
            PolymarketAPIError.connection(underlying: URLError(.timedOut)),
            .connection(underlying: URLError(.notConnectedToInternet)),
            .http(statusCode: 503, problemDetail: nil),
            .http(statusCode: 408, problemDetail: nil),
            .http(statusCode: 429, problemDetail: nil),
        ]
    )
    func failedReadIsRepeated(_ failure: PolymarketAPIError) async throws {
        let record = PolymarketOrderRecord(status: .matched, originalSize: 138, matchedSize: 138, price: Decimal(string: "0.72")!)
        let placer = OrderPlacerSpy(records: [.failure(failure), .success(record)])

        let result = try await place(with: placer)

        #expect(result == .settled(record, orderId: Self.orderId, side: Self.quote.side))
        #expect(placer.orderReads == 2)
    }

    @Test("Reads that keep failing on the server end with an unknown outcome once the wait runs out")
    func failingReadsEndAmbiguous() async throws {
        let placer = OrderPlacerSpy(records: [.failure(PolymarketAPIError.http(statusCode: 502, problemDetail: nil))])

        let error = try await #require(throws: PolymarketOrderPlacementError.self) {
            try await place(with: placer)
        }

        #expect(error.isAmbiguous)
        #expect(placer.orderReads == 3)
    }

    @Test("A delayed order the exchange refuses to show is a rejection", arguments: [400, 404])
    func refusedReadIsRejected(_ statusCode: Int) async throws {
        let placer = OrderPlacerSpy(records: [.failure(PolymarketAPIError.http(statusCode: statusCode, problemDetail: nil))])

        let error = try await #require(throws: PolymarketOrderPlacementError.self) {
            try await place(with: placer)
        }

        #expect(error.isRejected)
        #expect(placer.orderReads == 1)
    }

    @Test("A delayed order still open when the wait runs out has an unknown outcome")
    func neverSettledDelayedOrderIsAmbiguous() async throws {
        let placer = OrderPlacerSpy(records: [.success(Self.record(.live))])

        let error = try await #require(throws: PolymarketOrderPlacementError.self) {
            try await place(with: placer)
        }

        #expect(error.isAmbiguous)
        #expect(placer.orderReads == 3)
    }

    @Test("Leaving while a delayed order settles cancels the wait instead of reporting a failure")
    func cancellationStaysACancellation() async throws {
        let delays = PolymarketSteppedDelayProvider()
        let placer = OrderPlacerSpy(records: [.success(Self.record(.matched))])
        let task = Task {
            try await place(with: placer, delays: delays)
        }

        try await delays.waitUntilParked(Self.pollInterval)
        task.cancel()

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        #expect(placer.orderReads == 0)
    }
}

@Suite("Polymarket order placement with a session key")
struct PolymarketSessionKeyPlacementTests {
    @Test("An order routed to the session key is placed for the owner's deposit wallet under the key's address and credentials and signed by it in the envelope")
    func sessionKeyPlacesTheOrder() async throws {
        let signer = SessionKeyDigestSignerStub()
        let (sut, ownerPlacer, sessionPlacer, _) = makeSUT(route: .sessionKey(Self.session), signer: signer)

        _ = try await sut.place(signing: .sessionKey)

        let options = try #require(sessionPlacer.placed.first)
        let ownerDepositWalletAddress = try PolymarketDepositWalletDeriver.derive(ownerAddress: PolymarketOwnerAddressProviderStub.ownerAddress)

        #expect(options.ownerAddress == Self.session.sessionKeyAddress)
        #expect(options.depositWalletAddress == ownerDepositWalletAddress)
        #expect(options.credentials == Self.session.credentials)
        #expect(options.signing.sessionKeyAddress == Self.session.sessionKeyAddress)
        #expect(options.signing.sessionKeySigner as? SessionKeyDigestSignerStub === signer)
        #expect(ownerPlacer.placed.isEmpty)
    }

    @Test("An order signed with the owner key is placed under the owner's address and credentials")
    func ownerKeyPlacesTheOrder() async throws {
        let (sut, ownerPlacer, sessionPlacer, _) = makeSUT(route: .sessionKey(Self.session))

        _ = try await sut.place(signing: .ownerKey)

        let options = try #require(ownerPlacer.placed.first)

        #expect(options.ownerAddress == PolymarketOwnerAddressProviderStub.ownerAddress)
        #expect(options.credentials == PolymarketCredentialsRepositoryStub.credentials)
        #expect(options.signing.sessionKeyAddress == nil)
        #expect(sessionPlacer.placed.isEmpty)
    }

    @Test("An order meant for the session key the router no longer allows waits for the owner's signature")
    func unroutedSessionKeyIsNotPlaced() async {
        let (sut, ownerPlacer, sessionPlacer, _) = makeSUT(route: .ownerKey)

        await #expect(throws: PolymarketOrderPlacementSetupError.sessionKeyUnavailable) {
            try await sut.place(signing: .sessionKey)
        }

        #expect(ownerPlacer.placed.isEmpty)
        #expect(sessionPlacer.placed.isEmpty)
    }

    @Test(
        "An order the exchange refused for the session key's sake is not signed by the owner key behind the user's back",
        arguments: [
            PolymarketOrderPlacementError.unauthorized(message: nil),
            .rejected(message: "invalid signature"),
            .notSent(underlying: CommonPolymarketSessionKeyStore.KeyError.signingFailed),
            .notSent(underlying: PolymarketSessionKeySignatureError.invalidSignature),
            .notSent(underlying: PolymarketL2AuthError.invalidSecret),
        ]
    )
    func refusedSessionKeyWaitsForTheOwner(_ refusal: PolymarketOrderPlacementError) async {
        let (sut, ownerPlacer, _, router) = makeSUT(route: .sessionKey(Self.session), sessionPlacement: .failure(refusal))

        await #expect(throws: PolymarketOrderPlacementSetupError.sessionKeyUnavailable) {
            try await sut.place(signing: .sessionKey)
        }

        #expect(ownerPlacer.placed.isEmpty)
        #expect(await router.refusedAddresses == [Self.session.sessionKeyAddress])
    }

    @Test(
        "A failure the session key didn't cause neither blames the key nor retries with the owner key",
        arguments: [
            PolymarketOrderPlacementError.noLiquidity(message: nil),
            .rejected(message: "not enough balance"),
            .ambiguous(underlying: CancellationError()),
            .ambiguous(underlying: PolymarketOrderPlacementError.rejected(message: "invalid signature")),
            .notSent(underlying: PolymarketAPIError.connection(underlying: URLError(.notConnectedToInternet))),
            .notSent(underlying: PolymarketExchangeDomainError.mismatch(exchange: nil, signingDomainVersion: nil)),
        ]
    )
    func unrelatedFailureNeitherBlamesNorRetries(_ failure: PolymarketOrderPlacementError) async {
        let (sut, ownerPlacer, _, router) = makeSUT(route: .sessionKey(Self.session), sessionPlacement: .failure(failure))

        await #expect(throws: PolymarketOrderPlacementError.self) {
            try await sut.place(signing: .sessionKey)
        }

        #expect(ownerPlacer.placed.isEmpty)
        #expect(await router.refusedAddresses.isEmpty)
    }

    @Test("A delayed order the exchange refuses to show neither blames the session key nor is signed again by the owner")
    func refusedReadOfDelayedOrderKeepsTheKey() async {
        let unauthorized = PolymarketProblemDetail(status: 401, detail: "Unauthorized/Invalid api key")
        let (sut, ownerPlacer, _, router) = makeSUT(
            route: .sessionKey(Self.session),
            sessionPlacement: .success(Self.delayedPlacement),
            sessionRecords: [.failure(PolymarketAPIError.http(statusCode: 401, problemDetail: unauthorized))]
        )

        await #expect(throws: PolymarketOrderPlacementError.self) {
            try await sut.place(signing: .sessionKey)
        }

        #expect(ownerPlacer.placed.isEmpty)
        #expect(await router.refusedAddresses.isEmpty)
    }
}

// MARK: - Helpers

private extension PolymarketOrderPlacementServiceTests {
    static let orderId = "order"
    static let pollInterval: TimeInterval = 10
    static let quote = PolymarketOrderQuote.stub(status: .full)

    struct StubError: Error {}

    static func record(_ status: PolymarketOrderRecordStatus) -> PolymarketOrderRecord {
        PolymarketOrderRecord(status: status, originalSize: 138, matchedSize: 0, price: Decimal(string: "0.72")!)
    }

    func place(
        with placer: OrderPlacerSpy,
        delays: PollDelayProvider = PolymarketSteppedDelayProvider(passing: { _ in true })
    ) async throws -> PolymarketOrderPlacement {
        let sut = CommonPolymarketOrderPlacementService(
            userWalletId: UserWalletId(value: Data([0x01, 0x02, 0x03])),
            ownerAddressProvider: PolymarketOwnerAddressProviderStub(derived: PolymarketOwnerAddressProviderStub.ownerAddress),
            credentialsRepository: PolymarketCredentialsRepositoryStub(stored: PolymarketCredentialsRepositoryStub.credentials),
            placer: placer,
            delayProvider: delays
        )

        return try await sut.place(quote: Self.quote, market: .fixture, outcome: .fixture, signing: .ownerKey)
    }
}

private extension PolymarketSessionKeyPlacementTests {
    static let session = PolymarketSessionCredentials(
        sessionKeyAddress: "0x5e55000000000000000000000000000000000001",
        credentials: PolymarketL2Credentials(apiKey: "session", secret: "c2VjcmV0", passphrase: "phrase")
    )

    static let matchedPlacement = PolymarketOrderPlacement(
        orderId: "0xf1503cb4",
        status: .matched,
        makingAmount: 72,
        takingAmount: 100,
        transactionHashes: []
    )

    static let delayedPlacement = PolymarketOrderPlacement(
        orderId: "0xf1503cb4",
        status: .delayed,
        makingAmount: nil,
        takingAmount: nil,
        transactionHashes: []
    )

    func makeSUT(
        route: PolymarketOrderSigningRoute,
        sessionPlacement: Result<PolymarketOrderPlacement, PolymarketOrderPlacementError> = .success(Self.matchedPlacement),
        sessionRecords: [Result<PolymarketOrderRecord, Error>] = [],
        signer: SessionKeyDigestSignerStub = SessionKeyDigestSignerStub()
    ) -> (sut: CommonPolymarketOrderPlacementService, ownerPlacer: OrderPlacerSpy, sessionPlacer: OrderPlacerSpy, router: RouterSpy) {
        let ownerPlacer = OrderPlacerSpy(placement: .success(Self.matchedPlacement))
        let sessionPlacer = OrderPlacerSpy(placement: sessionPlacement, records: sessionRecords)
        let router = RouterSpy(route: route)

        let sut = CommonPolymarketOrderPlacementService(
            userWalletId: UserWalletId(value: Data([0x01, 0x02, 0x03])),
            ownerAddressProvider: PolymarketOwnerAddressProviderStub(derived: PolymarketOwnerAddressProviderStub.ownerAddress),
            credentialsRepository: PolymarketCredentialsRepositoryStub(stored: PolymarketCredentialsRepositoryStub.credentials),
            placer: ownerPlacer,
            delayProvider: PolymarketSteppedDelayProvider(passing: { _ in true }),
            sessionKeyPlacement: CommonPolymarketOrderPlacementService.SessionKeyPlacement(
                placer: sessionPlacer,
                signer: signer,
                router: router
            )
        )

        return (sut, ownerPlacer, sessionPlacer, router)
    }
}

private extension CommonPolymarketOrderPlacementService {
    func place(signing: PolymarketOrderSigningMethod) async throws -> PolymarketOrderPlacement {
        try await place(quote: .stub(status: .full), market: .fixture, outcome: .fixture, signing: signing)
    }
}

private extension PolymarketOrderPlacer.Signing {
    var sessionKeyAddress: String? {
        guard case .sessionKey(let address, _) = self else { return nil }

        return address
    }

    var sessionKeySigner: (any PolymarketOrderDigestSigning)? {
        guard case .sessionKey(_, let signer) = self else { return nil }

        return signer
    }
}

private extension PolymarketOrderPlacementError {
    var isRejected: Bool {
        if case .rejected = self { return true }

        return false
    }
}

// MARK: - Stubs

private final class OrderPlacerSpy: PolymarketOrderPlacing {
    private let placement: Result<PolymarketOrderPlacement, PolymarketOrderPlacementError>
    private let state: OSAllocatedUnfairLock<State>

    init(
        placement: Result<PolymarketOrderPlacement, PolymarketOrderPlacementError> = .success(
            PolymarketOrderPlacement(
                orderId: "order",
                status: .delayed,
                makingAmount: nil,
                takingAmount: nil,
                transactionHashes: []
            )
        ),
        records: [Result<PolymarketOrderRecord, Error>] = []
    ) {
        self.placement = placement
        state = OSAllocatedUnfairLock(uncheckedState: State(records: records))
    }

    var placed: [PolymarketOrderPlacer.Options] {
        state.withLockUnchecked { $0.placed }
    }

    var orderReads: Int {
        state.withLock { $0.orderReads }
    }

    func place(_ options: PolymarketOrderPlacer.Options) async throws -> PolymarketOrderPlacement {
        state.withLockUnchecked { $0.placed.append(options) }

        return try placement.get()
    }

    func order(id: String, credentials: PolymarketL2Credentials, ownerAddress: String) async throws -> PolymarketOrderRecord {
        try state.withLockUnchecked { state in
            state.orderReads += 1

            let result = state.records.count > 1 ? state.records.removeFirst() : state.records.first

            guard let result else {
                throw PolymarketOrderPlacementServiceTests.StubError()
            }

            return try result.get()
        }
    }

    private struct State {
        var records: [Result<PolymarketOrderRecord, Error>]
        var placed: [PolymarketOrderPlacer.Options] = []
        var orderReads = 0
    }
}

private final class SessionKeyDigestSignerStub: PolymarketOrderDigestSigning {
    func sign(digest: Data) async throws -> String {
        "0x"
    }
}

private actor RouterSpy: PolymarketOrderSigningRouting {
    private(set) var refusedAddresses: [String] = []

    private let fixedRoute: PolymarketOrderSigningRoute

    init(route: PolymarketOrderSigningRoute) {
        fixedRoute = route
    }

    func route() -> PolymarketOrderSigningRoute {
        refusedAddresses.isEmpty ? fixedRoute : .ownerKey
    }

    nonisolated var refusalsPublisher: AnyPublisher<Void, Never> {
        Empty().eraseToAnyPublisher()
    }

    func reportRefused(sessionKeyAddress: String) {
        refusedAddresses.append(sessionKeyAddress)
    }

    func invalidate(sessionKeyAddress: String) {}

    func forgetReadiness() {}

    nonisolated func isRefused(sessionKeyAddress: String) -> Bool {
        false
    }
}
