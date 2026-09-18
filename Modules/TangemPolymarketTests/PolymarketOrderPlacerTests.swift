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
    @Test("The market kind reaches the digest, the wrapping and the wire", arguments: [false, true])
    func marketKindReachesEveryStage(_ isNegRisk: Bool) async throws {
        let signer = StubDigestSigner()
        let clobService = StubCLOBService()
        let placer = PolymarketOrderPlacer(clobService: clobService, digestSigner: signer)

        _ = try await placer.place(Self.options(isNegRisk: isNegRisk))

        let signedOrder = try #require(clobService.placedOrder)

        #expect(signedOrder.isNegRisk == isNegRisk)

        let expectedDigest = try PolymarketOrderSigning.digest(
            order: signedOrder.order,
            isNegRisk: isNegRisk,
            depositWalletAddress: Self.depositWallet
        )

        let expectedSignature = try PolymarketOrderSigning.wrap(
            signature: StubDigestSigner.signature,
            order: signedOrder.order,
            isNegRisk: isNegRisk
        )

        #expect(signer.signedDigest == expectedDigest)
        #expect(signedOrder.signature == expectedSignature)
    }

    @Test("A refusal on the way to the card is reported as never sent")
    func signingFailureIsNotSent() async {
        let placer = PolymarketOrderPlacer(clobService: StubCLOBService(), digestSigner: FailingDigestSigner())

        await #expect(throws: PolymarketOrderPlacementError.self) {
            try await placer.place(Self.options(isNegRisk: false))
        }
    }
}

// MARK: - Fixtures

private extension PolymarketOrderPlacerTests {
    static let depositWallet = "0x5A057dc6394196fBa51D84457DA3FB8FA241Fc20"

    static func options(isNegRisk: Bool) -> PolymarketOrderPlacer.Options {
        PolymarketOrderPlacer.Options(
            quote: .stub(side: .buy, notional: 72, shares: Decimal(string: "97.95918")!),
            assetId: "1116017998421700000000000000000000000000000000000000000000000000047",
            isNegRisk: isNegRisk,
            ownerAddress: "0x4130efa9e628a991520be60f2e948a4f9be52fbc",
            depositWalletAddress: depositWallet,
            credentials: PolymarketL2Credentials(apiKey: "api-key", secret: "secret", passphrase: "passphrase")
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
    func price(tokenId: String, side: PolymarketOrderSide) async throws -> Decimal {
        0
    }

    private(set) var placedOrder: PolymarketSignedOrder?

    func createCredentials(authHeaders: PolymarketCLOBAuthHeaders) async throws -> PolymarketL2Credentials {
        fatalError("Not reachable from the placer")
    }

    func deriveCredentials(authHeaders: PolymarketCLOBAuthHeaders) async throws -> PolymarketL2Credentials {
        fatalError("Not reachable from the placer")
    }

    func updateBalanceAllowance(credentials: PolymarketL2Credentials, ownerAddress: String) async throws {
        fatalError("Not reachable from the placer")
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

        return PolymarketOrderPlacement(
            orderId: "0xf1503cb4",
            status: .matched,
            makingAmount: 72,
            takingAmount: Decimal(string: "97.95918")!,
            transactionHashes: []
        )
    }
}
