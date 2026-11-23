//
//  PolymarketOrderPlacerTests.swift
//  TangemPolymarketTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
@testable import TangemPolymarket

@Suite("PolymarketOrderPlacer", .timeLimit(.minutes(1)))
struct PolymarketOrderPlacerTests {
    @Test("The quote's exchange domain reaches the digest, the wrapping and the wire", arguments: QuotedMarket.allCases)
    func domainReachesEveryStage(_ market: QuotedMarket) async throws {
        let signer = StubDigestSigner()
        let clobService = StubCLOBService()
        let placer = PolymarketOrderPlacer(clobService: clobService, signing: .depositWallet(signer))

        _ = try await placer.place(Self.options(market))

        let signedOrder = try #require(clobService.placedOrder)

        let expectedDigest = try PolymarketOrderSigning.digest(
            order: signedOrder.order,
            domain: market.domain,
            depositWalletAddress: Self.depositWallet
        )

        let expectedSignature = try PolymarketOrderSigning.wrap(
            signature: StubDigestSigner.signature,
            order: signedOrder.order,
            domain: market.domain
        )

        #expect(signer.signedDigest == expectedDigest)
        #expect(signedOrder.signature == expectedSignature)
    }

    @Test("A quote that does not match the table is refused before the card is asked", arguments: MismatchedQuote.allCases)
    func mismatchedQuoteIsNeverSigned(_ mismatch: MismatchedQuote) async {
        let signer = StubDigestSigner()
        let clobService = StubCLOBService()
        let placer = PolymarketOrderPlacer(clobService: clobService, signing: .depositWallet(signer))

        let error = await #expect(throws: PolymarketOrderPlacementError.self) {
            try await placer.place(mismatch.options)
        }

        guard case .notSent(let underlying) = error else {
            Issue.record("Expected a not-sent failure, got \(String(describing: error))")
            return
        }

        #expect(underlying is PolymarketExchangeDomainError)
        #expect(signer.signedDigest == nil)
        #expect(clobService.placedOrder == nil)
        #expect(clobService.refreshedAssets.isEmpty)
    }

    @Test("A refusal on the way to the card is reported as never sent")
    func signingFailureIsNotSent() async {
        let clobService = StubCLOBService()
        let placer = PolymarketOrderPlacer(clobService: clobService, signing: .depositWallet(FailingDigestSigner()))

        let error = await #expect(throws: PolymarketOrderPlacementError.self) {
            try await placer.place(Self.options(.v1))
        }

        guard case .notSent(let underlying) = error else {
            Issue.record("Expected a not-sent failure, got \(String(describing: error))")
            return
        }

        #expect(underlying is FailingDigestSigner.Refused)
        #expect(clobService.placedOrder == nil)
    }

    @Test("A sale refreshes the exchange's view of the sold token first", arguments: [
        (QuotedMarket.v1, PolymarketBalanceAllowanceAsset.conditional(tokenId: PolymarketOrderPlacerTests.assetId)),
        (QuotedMarket.v1NegRisk, PolymarketBalanceAllowanceAsset.conditional(tokenId: PolymarketOrderPlacerTests.assetId)),
        (QuotedMarket.v2, PolymarketBalanceAllowanceAsset.conditionalV2(tokenId: PolymarketOrderPlacerTests.assetId)),
    ])
    func sellRefreshesThePosition(_ market: QuotedMarket, _ expected: PolymarketBalanceAllowanceAsset) async throws {
        let clobService = StubCLOBService()
        let placer = PolymarketOrderPlacer(clobService: clobService, signing: .depositWallet(StubDigestSigner()))

        _ = try await placer.place(Self.options(market, side: .sell))

        #expect(clobService.refreshedAssets == [expected])
        #expect(clobService.events == [.refresh, .place])
    }

    @Test("A purchase leaves the position balance alone")
    func buyDoesNotRefreshThePosition() async throws {
        let clobService = StubCLOBService()
        let placer = PolymarketOrderPlacer(clobService: clobService, signing: .depositWallet(StubDigestSigner()))

        _ = try await placer.place(Self.options(.v2, side: .buy))

        #expect(clobService.refreshedAssets.isEmpty)
    }

    @Test("A failed refresh does not stop the sale")
    func failedRefreshStillSells() async throws {
        let clobService = StubCLOBService(refreshFails: true)
        let placer = PolymarketOrderPlacer(clobService: clobService, signing: .depositWallet(StubDigestSigner()))

        _ = try await placer.place(Self.options(.v1, side: .sell))

        #expect(clobService.placedOrder != nil)
    }

    @Test("An order signed by a session key carries the key's wrapped signature inside the session envelope and still names the deposit wallet as the signer")
    func sessionKeyOrderIsEnveloped() async throws {
        let clobService = StubCLOBService()
        let sessionKeySigner = StubDigestSigner(signature: Self.sessionKeySignature)
        let placer = PolymarketOrderPlacer(clobService: clobService, signing: .sessionKey(sessionKeySigner))

        _ = try await placer.place(Self.sessionKeyOptions)

        let signedOrder = try #require(clobService.placedOrder)

        let wrapped = try PolymarketOrderSigning.wrap(
            signature: Self.sessionKeySignature,
            order: signedOrder.order,
            domain: QuotedMarket.v2.domain
        )

        let expected = try PolymarketSessionKeySignature.envelope(depositWalletSignature: wrapped, sessionKeyAddress: Self.sessionKey)

        #expect(signedOrder.signature == expected)
        #expect(signedOrder.order.signer == Self.depositWallet)
        #expect(sessionKeySigner.signCount == 1)
    }

    @Test("A session key order that never reached the exchange is sent again after a wait, byte for byte, without asking the signer again")
    func sessionKeyOrderIsResentUnchanged() async throws {
        let clobService = StubCLOBService(placeFailures: [Self.unreached, Self.unreached])
        let sessionKeySigner = StubDigestSigner()
        let delays = DelayProviderSpy()
        let placer = PolymarketOrderPlacer(clobService: clobService, signing: .sessionKey(sessionKeySigner), delayProvider: delays)

        _ = try await placer.place(Self.sessionKeyOptions)

        #expect(clobService.placedOrders.count == 3)
        #expect(Set(clobService.placedOrders).count == 1)
        #expect(sessionKeySigner.signCount == 1)
        #expect(delays.waits == [1, 1])
    }

    @Test("A session key order gives up after the second resend and reports that it never reached the exchange")
    func sessionKeyResendIsBounded() async {
        let clobService = StubCLOBService(placeFailures: [Self.unreached, Self.unreached, Self.unreached])
        let delays = DelayProviderSpy()
        let placer = PolymarketOrderPlacer(clobService: clobService, signing: .sessionKey(StubDigestSigner()), delayProvider: delays)

        let error = await #expect(throws: PolymarketOrderPlacementError.self) {
            try await placer.place(Self.sessionKeyOptions)
        }

        guard case .notSent = error else {
            Issue.record("Expected a not-sent failure, got \(String(describing: error))")
            return
        }

        #expect(clobService.placedOrders.count == 3)
        #expect(delays.waits == [1, 1])
    }

    @Test("A card order that never reached the exchange is not resent")
    func cardOrderIsNeverResent() async {
        let clobService = StubCLOBService(placeFailures: [Self.unreached])
        let delays = DelayProviderSpy()
        let placer = PolymarketOrderPlacer(clobService: clobService, signing: .depositWallet(StubDigestSigner()), delayProvider: delays)

        await #expect(throws: PolymarketOrderPlacementError.self) {
            try await placer.place(Self.options(.v2))
        }

        #expect(clobService.placedOrders.count == 1)
        #expect(delays.waits.isEmpty)
    }

    @Test("A session key order is resent only after a failure that proves it never reached the exchange", arguments: UnrepeatableFailure.allCases)
    func sessionKeyOrderIsNotResentOnOtherFailures(_ failure: UnrepeatableFailure) async {
        let clobService = StubCLOBService(placeFailures: [failure.error])
        let delays = DelayProviderSpy()
        let placer = PolymarketOrderPlacer(clobService: clobService, signing: .sessionKey(StubDigestSigner()), delayProvider: delays)

        await #expect(throws: PolymarketOrderPlacementError.self) {
            try await placer.place(Self.sessionKeyOptions)
        }

        #expect(clobService.placedOrders.count == 1)
        #expect(delays.waits.isEmpty)
    }

    @Test("A refusal of a resent order is an unknown outcome, because an earlier copy may already be on the book")
    func refusedResendIsAmbiguous() async {
        let clobService = StubCLOBService(placeFailures: [Self.unreached, PolymarketOrderPlacementError.rejected(message: Self.duplicateRefusal)])
        let placer = PolymarketOrderPlacer(clobService: clobService, signing: .sessionKey(StubDigestSigner()), delayProvider: DelayProviderSpy())

        let error = await #expect(throws: PolymarketOrderPlacementError.self) {
            try await placer.place(Self.sessionKeyOptions)
        }

        #expect(error?.isAmbiguous == true)
        #expect(clobService.placedOrders.count == 2)
    }

    @Test("A refusal of the first send stays a refusal")
    func refusedFirstSendIsRejected() async {
        let clobService = StubCLOBService(placeFailures: [PolymarketOrderPlacementError.rejected(message: Self.duplicateRefusal)])
        let placer = PolymarketOrderPlacer(clobService: clobService, signing: .sessionKey(StubDigestSigner()), delayProvider: DelayProviderSpy())

        let error = await #expect(throws: PolymarketOrderPlacementError.self) {
            try await placer.place(Self.sessionKeyOptions)
        }

        guard case .rejected = error else {
            Issue.record("Expected a refusal, got \(String(describing: error))")
            return
        }
    }

    @Test("Cancelling the order while it waits to be resent ends it without another send", arguments: CancelledWait.allCases)
    func cancellationDuringTheResendWaitStopsTheOrder(_ cancelledWait: CancelledWait) async {
        let clobService = StubCLOBService(placeFailures: [Self.unreached])
        let delays = DelayProviderSpy(cancelledWait: cancelledWait)
        let placer = PolymarketOrderPlacer(clobService: clobService, signing: .sessionKey(StubDigestSigner()), delayProvider: delays)

        let order = Task {
            _ = try await placer.place(Self.sessionKeyOptions)
        }

        await #expect(throws: CancellationError.self) {
            try await order.value
        }

        #expect(clobService.placedOrders.count == 1)
        #expect(delays.waits == [1])
    }
}

// MARK: - Fixtures

private extension PolymarketOrderPlacerTests {
    static let depositWallet = "0x5A057dc6394196fBa51D84457DA3FB8FA241Fc20"
    static let ownerAddress = "0x4130efa9e628a991520be60f2e948a4f9be52fbc"
    static let assetId = "1116017998421700000000000000000000000000000000000000000000000000047"
    static let sessionKey = "0x5e5500000000000000000000000000000000f001"
    static let sessionKeySignature = "0x" + String(repeating: "22", count: 65)
    static let duplicateRefusal = "order 0xf1503cb4 is invalid. Duplicated."

    static var sessionKeyOptions: PolymarketOrderPlacer.Options {
        options(.v2, signingKeyAddress: sessionKey)
    }

    static let unreached = PolymarketOrderPlacementError.notSent(
        underlying: PolymarketAPIError.connection(underlying: URLError(.notConnectedToInternet))
    )

    static func options(
        _ market: QuotedMarket,
        side: PolymarketOrderSide = .buy,
        signingKeyAddress: String = PolymarketOrderPlacerTests.ownerAddress
    ) -> PolymarketOrderPlacer.Options {
        options(quote: market.quote(side: side), isNegRisk: market.isNegRisk, signingKeyAddress: signingKeyAddress)
    }

    static func options(
        quote: PolymarketOrderQuote,
        isNegRisk: Bool,
        signingKeyAddress: String = PolymarketOrderPlacerTests.ownerAddress
    ) -> PolymarketOrderPlacer.Options {
        PolymarketOrderPlacer.Options(
            quote: quote,
            assetId: assetId,
            isNegRisk: isNegRisk,
            signingKeyAddress: signingKeyAddress,
            depositWalletAddress: depositWallet,
            credentials: PolymarketL2Credentials(apiKey: "api-key", secret: "secret", passphrase: "passphrase")
        )
    }
}

enum QuotedMarket: CaseIterable {
    case v1
    case v1NegRisk
    case v2
    case v2NegRisk

    var isNegRisk: Bool {
        switch self {
        case .v1, .v2: false
        case .v1NegRisk, .v2NegRisk: true
        }
    }

    var domain: PolymarketExchangeDomain {
        switch self {
        case .v1: .ctfExchange
        case .v1NegRisk: .negRiskCtfExchange
        case .v2, .v2NegRisk: .exchangeV3
        }
    }

    func quote(side: PolymarketOrderSide) -> PolymarketOrderQuote {
        .stub(
            side: side,
            notional: 72,
            shares: Decimal(string: "97.95918")!,
            version: self == .v2 || self == .v2NegRisk ? .v2 : .v1,
            exchange: domain.address.lowercased(),
            signingDomainVersion: domain.version
        )
    }
}

enum MismatchedQuote: CaseIterable {
    case unknownVersion
    case missingExchange
    case missingDomainVersion
    case v1WithNegRiskExchange
    case v1NegRiskWithStandardExchange
    case v1WithExchangeV3
    case v1WithDomainThree
    case v2WithCtfExchange
    case v2WithDomainTwo
    case foreignExchange

    var options: PolymarketOrderPlacer.Options {
        switch self {
        case .unknownVersion:
            Self.options(.unknown("v3"), PolymarketApprovalContracts.exchangeV3, "3", isNegRisk: false)
        case .missingExchange:
            Self.options(.v1, nil, "2", isNegRisk: false)
        case .missingDomainVersion:
            Self.options(.v2, PolymarketApprovalContracts.exchangeV3, nil, isNegRisk: false)
        case .v1WithNegRiskExchange:
            Self.options(.v1, PolymarketApprovalContracts.negRiskCtfExchange, "2", isNegRisk: false)
        case .v1NegRiskWithStandardExchange:
            Self.options(.v1, PolymarketApprovalContracts.ctfExchange, "2", isNegRisk: true)
        case .v1WithExchangeV3:
            Self.options(.v1, PolymarketApprovalContracts.exchangeV3, "2", isNegRisk: false)
        case .v1WithDomainThree:
            Self.options(.v1, PolymarketApprovalContracts.ctfExchange, "3", isNegRisk: false)
        case .v2WithCtfExchange:
            Self.options(.v2, PolymarketApprovalContracts.ctfExchange, "3", isNegRisk: false)
        case .v2WithDomainTwo:
            Self.options(.v2, PolymarketApprovalContracts.exchangeV3, "2", isNegRisk: true)
        case .foreignExchange:
            Self.options(.v2, "0x4130efa9e628a991520be60f2e948a4f9be52fbc", "3", isNegRisk: false)
        }
    }

    private static func options(
        _ version: PolymarketMarketVersion,
        _ exchange: String?,
        _ signingDomainVersion: String?,
        isNegRisk: Bool
    ) -> PolymarketOrderPlacer.Options {
        PolymarketOrderPlacerTests.options(
            quote: .stub(
                side: .buy,
                notional: 72,
                shares: 100,
                version: version,
                exchange: exchange,
                signingDomainVersion: signingDomainVersion
            ),
            isNegRisk: isNegRisk
        )
    }
}

enum UnrepeatableFailure: CaseIterable {
    case ambiguousTimeout
    case notSentTimeout
    case notSentConnectionLoss
    case notSentServerError
    case notSentUnreadableAnswer
    case notSentUnbuiltRequest
    case rejected
    case unauthorized
    case noLiquidity

    struct RequestNotBuilt: Error {}

    var error: PolymarketOrderPlacementError {
        switch self {
        case .ambiguousTimeout:
            .ambiguous(underlying: PolymarketAPIError.connection(underlying: URLError(.timedOut)))
        case .notSentTimeout:
            .notSent(underlying: PolymarketAPIError.connection(underlying: URLError(.timedOut)))
        case .notSentConnectionLoss:
            .notSent(underlying: PolymarketAPIError.connection(underlying: URLError(.networkConnectionLost)))
        case .notSentServerError:
            .notSent(underlying: PolymarketAPIError.http(statusCode: 502, problemDetail: nil))
        case .notSentUnreadableAnswer:
            .notSent(underlying: PolymarketAPIError.decoding(field: "orderID", value: ""))
        case .notSentUnbuiltRequest:
            .notSent(underlying: RequestNotBuilt())
        case .rejected:
            .rejected(message: nil)
        case .unauthorized:
            .unauthorized(message: nil)
        case .noLiquidity:
            .noLiquidity(message: nil)
        }
    }
}

enum CancelledWait: CaseIterable {
    case thrownByTheWait
    case unnoticedByTheWait
}

// MARK: - Doubles

private final class StubDigestSigner: PolymarketOrderDigestSigning, @unchecked Sendable {
    static let signature = "0x" + String(repeating: "11", count: 65)

    private let signature: String

    private(set) var signedDigest: Data?
    private(set) var signCount = 0

    init(signature: String = StubDigestSigner.signature) {
        self.signature = signature
    }

    func sign(digest: Data) async throws -> String {
        signedDigest = digest
        signCount += 1

        return signature
    }
}

private struct FailingDigestSigner: PolymarketOrderDigestSigning {
    struct Refused: Error {}

    func sign(digest: Data) async throws -> String {
        throw Refused()
    }
}

private final class DelayProviderSpy: PollDelayProvider, Sendable {
    private let cancelledWait: CancelledWait?
    private let recordedWaits = OSAllocatedUnfairLock(initialState: [TimeInterval]())

    init(cancelledWait: CancelledWait? = nil) {
        self.cancelledWait = cancelledWait
    }

    var waits: [TimeInterval] {
        recordedWaits.withLock { $0 }
    }

    func wait(for seconds: TimeInterval) async throws {
        recordedWaits.withLock { $0.append(seconds) }

        switch cancelledWait {
        case .none:
            return
        case .thrownByTheWait:
            throw CancellationError()
        case .unnoticedByTheWait:
            withUnsafeCurrentTask { $0?.cancel() }
        }
    }
}

private final class StubCLOBService: PolymarketCLOBService, Sendable {
    enum Event {
        case refresh
        case place
    }

    struct RefreshFailed: Error {}

    private let state: OSAllocatedUnfairLock<State>

    init(placeFailures: [any Error] = [], refreshFails: Bool = false) {
        state = OSAllocatedUnfairLock(initialState: State(placeFailures: placeFailures, refreshFails: refreshFails))
    }

    var placedOrders: [PolymarketSignedOrder] {
        state.withLock { $0.placedOrders }
    }

    var placedOrder: PolymarketSignedOrder? {
        placedOrders.last
    }

    var refreshedAssets: [PolymarketBalanceAllowanceAsset] {
        state.withLock { $0.refreshedAssets }
    }

    var events: [Event] {
        state.withLock { $0.events }
    }

    func price(tokenId: String, side: PolymarketOrderSide) async throws -> Decimal {
        0
    }

    func priceHistory(tokenId: String, query: PolymarketPriceHistoryQuery) async throws -> [PolymarketPricePoint] {
        []
    }

    func createCredentials(authHeaders: PolymarketCLOBAuthHeaders) async throws -> PolymarketL2Credentials {
        fatalError("Not reachable from the placer")
    }

    func deriveCredentials(authHeaders: PolymarketCLOBAuthHeaders) async throws -> PolymarketL2Credentials {
        fatalError("Not reachable from the placer")
    }

    func updateBalanceAllowance(
        _ asset: PolymarketBalanceAllowanceAsset,
        credentials: PolymarketL2Credentials,
        ownerAddress: String
    ) async throws {
        let refreshFails = state.withLock { state in
            state.refreshedAssets.append(asset)
            state.events.append(.refresh)

            return state.refreshFails
        }

        if refreshFails {
            throw RefreshFailed()
        }
    }

    func balanceAllowance(
        credentials: PolymarketL2Credentials,
        ownerAddress: String
    ) async throws -> PolymarketBalanceAllowance {
        fatalError("Not reachable from the placer")
    }

    func order(
        id: String,
        credentials: PolymarketL2Credentials,
        ownerAddress: String
    ) async throws -> PolymarketOrderRecord {
        fatalError("Not reachable from this test")
    }

    func sessionSigners(
        credentials: PolymarketL2Credentials,
        ownerAddress: String
    ) async throws -> [PolymarketSessionSigner] {
        fatalError("Not reachable from the placer")
    }

    func placeOrder(
        _ signedOrder: PolymarketSignedOrder,
        credentials: PolymarketL2Credentials,
        ownerAddress: String
    ) async throws -> PolymarketOrderPlacement {
        let failure = state.withLock { state -> (any Error)? in
            state.placedOrders.append(signedOrder)
            state.events.append(.place)

            return state.placeFailures.isEmpty ? nil : state.placeFailures.removeFirst()
        }

        if let failure {
            throw failure
        }

        return PolymarketOrderPlacement(
            orderId: "0xf1503cb4",
            status: .matched,
            makingAmount: 72,
            takingAmount: Decimal(string: "97.95918")!,
            transactionHashes: []
        )
    }

    private struct State {
        var placeFailures: [any Error]
        var refreshFails: Bool
        var placedOrders: [PolymarketSignedOrder] = []
        var refreshedAssets: [PolymarketBalanceAllowanceAsset] = []
        var events: [Event] = []
    }
}
