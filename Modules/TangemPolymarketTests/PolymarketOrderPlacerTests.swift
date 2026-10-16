//
//  PolymarketOrderPlacerTests.swift
//  TangemPolymarketTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemPolymarket

@Suite("PolymarketOrderPlacer")
struct PolymarketOrderPlacerTests {
    @Test("The quote's exchange domain reaches the digest, the wrapping and the wire", arguments: QuotedMarket.allCases)
    func domainReachesEveryStage(_ market: QuotedMarket) async throws {
        let signer = StubDigestSigner()
        let clobService = StubCLOBService()
        let placer = PolymarketOrderPlacer(clobService: clobService, digestSigner: signer)

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
        let placer = PolymarketOrderPlacer(clobService: clobService, digestSigner: signer)

        await #expect(throws: PolymarketOrderPlacementError.self) {
            try await placer.place(mismatch.options)
        }

        #expect(signer.signedDigest == nil)
        #expect(clobService.placedOrder == nil)
        #expect(clobService.refreshedAssets.isEmpty)
    }

    @Test("A refusal on the way to the card is reported as never sent")
    func signingFailureIsNotSent() async {
        let placer = PolymarketOrderPlacer(clobService: StubCLOBService(), digestSigner: FailingDigestSigner())

        await #expect(throws: PolymarketOrderPlacementError.self) {
            try await placer.place(Self.options(.v1))
        }
    }

    @Test("A sale refreshes the exchange's view of the sold token first", arguments: [
        (QuotedMarket.v1, PolymarketBalanceAllowanceAsset.conditional(tokenId: PolymarketOrderPlacerTests.assetId)),
        (QuotedMarket.v1NegRisk, PolymarketBalanceAllowanceAsset.conditional(tokenId: PolymarketOrderPlacerTests.assetId)),
        (QuotedMarket.v2, PolymarketBalanceAllowanceAsset.conditionalV2(tokenId: PolymarketOrderPlacerTests.assetId)),
    ])
    func sellRefreshesThePosition(_ market: QuotedMarket, _ expected: PolymarketBalanceAllowanceAsset) async throws {
        let clobService = StubCLOBService()
        let placer = PolymarketOrderPlacer(clobService: clobService, digestSigner: StubDigestSigner())

        _ = try await placer.place(Self.options(market, side: .sell))

        #expect(clobService.refreshedAssets == [expected])
        #expect(clobService.events == [.refresh, .place])
    }

    @Test("A purchase leaves the position balance alone")
    func buyDoesNotRefreshThePosition() async throws {
        let clobService = StubCLOBService()
        let placer = PolymarketOrderPlacer(clobService: clobService, digestSigner: StubDigestSigner())

        _ = try await placer.place(Self.options(.v2, side: .buy))

        #expect(clobService.refreshedAssets.isEmpty)
    }

    @Test("A failed refresh does not stop the sale")
    func failedRefreshStillSells() async throws {
        let clobService = StubCLOBService()
        clobService.refreshFails = true
        let placer = PolymarketOrderPlacer(clobService: clobService, digestSigner: StubDigestSigner())

        _ = try await placer.place(Self.options(.v1, side: .sell))

        #expect(clobService.placedOrder != nil)
    }
}

// MARK: - Fixtures

private extension PolymarketOrderPlacerTests {
    static let depositWallet = "0x5A057dc6394196fBa51D84457DA3FB8FA241Fc20"
    static let assetId = "1116017998421700000000000000000000000000000000000000000000000000047"

    static func options(_ market: QuotedMarket, side: PolymarketOrderSide = .buy) -> PolymarketOrderPlacer.Options {
        options(quote: market.quote(side: side), isNegRisk: market.isNegRisk)
    }

    static func options(quote: PolymarketOrderQuote, isNegRisk: Bool) -> PolymarketOrderPlacer.Options {
        PolymarketOrderPlacer.Options(
            quote: quote,
            assetId: assetId,
            isNegRisk: isNegRisk,
            ownerAddress: "0x4130efa9e628a991520be60f2e948a4f9be52fbc",
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

// MARK: - Doubles

private final class StubDigestSigner: PolymarketOrderDigestSigning, @unchecked Sendable {
    static let signature = "0x" + String(repeating: "11", count: 65)

    private(set) var signedDigest: Data?

    func sign(digest: Data) async throws -> String {
        signedDigest = digest

        return Self.signature
    }
}

private struct FailingDigestSigner: PolymarketOrderDigestSigning {
    struct Refused: Error {}

    func sign(digest: Data) async throws -> String {
        throw Refused()
    }
}

private final class StubCLOBService: PolymarketCLOBService, @unchecked Sendable {
    enum Event {
        case refresh
        case place
    }

    struct RefreshFailed: Error {}

    func price(tokenId: String, side: PolymarketOrderSide) async throws -> Decimal {
        0
    }

    private(set) var placedOrder: PolymarketSignedOrder?
    private(set) var refreshedAssets: [PolymarketBalanceAllowanceAsset] = []
    private(set) var events: [Event] = []
    var refreshFails = false

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
        refreshedAssets.append(asset)
        events.append(.refresh)

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

    func placeOrder(
        _ signedOrder: PolymarketSignedOrder,
        credentials: PolymarketL2Credentials,
        ownerAddress: String
    ) async throws -> PolymarketOrderPlacement {
        placedOrder = signedOrder
        events.append(.place)

        return PolymarketOrderPlacement(
            orderId: "0xf1503cb4",
            status: .matched,
            makingAmount: 72,
            takingAmount: Decimal(string: "97.95918")!,
            transactionHashes: []
        )
    }
}
