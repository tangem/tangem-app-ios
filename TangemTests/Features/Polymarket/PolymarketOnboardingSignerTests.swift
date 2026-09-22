//
//  PolymarketOnboardingSignerTests.swift
//  TangemTests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemPolymarket
import TangemSdk
@testable import Tangem

@Suite("Polymarket onboarding signatures")
struct PolymarketOnboardingSignerTests {
    @Test("Both digests reach the card in a single session")
    func bothDigestsAreSignedInOneSession() async throws {
        let context = try Context()

        _ = try await context.sut.sign(approvals: Self.approvals)

        #expect(context.signer.signCalls == 1)
        #expect(context.signer.requestedHashes.count == 2)
    }

    @Test("The headers carry the timestamp and nonce that went into the signed digest")
    func headersMatchTheSignedDigest() async throws {
        let context = try Context()

        let signatures = try await context.sut.sign(approvals: Self.approvals)
        let headers = signatures.authHeaders.values
        let expected = PolymarketClobAuth.digest(
            ownerAddress: try #require(headers["POLY_ADDRESS"]),
            timestamp: try #require(headers["POLY_TIMESTAMP"])
        )

        #expect(context.signer.requestedHashes.first == expected)
        #expect(headers["POLY_NONCE"] == PolymarketClobAuth.nonce)
    }

    @Test("The batch digest is the one built from the batch that gets submitted")
    func batchDigestMatchesTheSubmittedBatch() async throws {
        let context = try Context()

        let signatures = try await context.sut.sign(approvals: Self.approvals)
        let expected = try PolymarketRelayedBatchSigning.digest(for: Self.approvals)

        #expect(context.signer.requestedHashes.last == expected)
        #expect(signatures.approvals.nonce == Self.approvals.nonce)
        #expect(signatures.approvals.deadline == Self.approvals.deadline)
        #expect(signatures.approvals.calls == Self.approvals.calls)
    }

    @Test("Neither signature ends up on the other payload")
    func signaturesAreNotSwapped() async throws {
        let context = try Context()

        let signatures = try await context.sut.sign(approvals: Self.approvals)
        let headers = signatures.authHeaders.values
        let authDigest = PolymarketClobAuth.digest(
            ownerAddress: try #require(headers["POLY_ADDRESS"]),
            timestamp: try #require(headers["POLY_TIMESTAMP"])
        )
        let batchDigest = try PolymarketRelayedBatchSigning.digest(for: Self.approvals)

        #expect(headers["POLY_SIGNATURE"] == context.signer.signature(over: authDigest))
        #expect(signatures.approvals.signature == context.signer.signature(over: batchDigest))
        #expect(headers["POLY_SIGNATURE"] != signatures.approvals.signature)
    }

    @Test("Both signatures are attributed to the address the stored key resolves to")
    func ownerAddressIsConsistent() async throws {
        let context = try Context()

        let signatures = try await context.sut.sign(approvals: Self.approvals)
        let ownerKey = try #require(PolymarketUtilities.getKey(from: context.keysRepository))
        let expected = try PolymarketUtilities.makeAddress(using: ownerKey)

        #expect(signatures.authHeaders.values["POLY_ADDRESS"] == expected)
        #expect(signatures.approvals.ownerAddress == expected)
    }

    @Test("A wallet without the owner key never reaches the card")
    func aMissingKeyNeverReachesTheCard() async throws {
        let context = try Context(storeOwnerKey: false)

        await #expect(throws: PolymarketSigningError.notDerived) {
            try await context.sut.sign(approvals: Self.approvals)
        }

        #expect(context.signer.signCalls == 0)
    }
}

// MARK: - Fixtures

private extension PolymarketOnboardingSignerTests {
    static let approvals = PolymarketRelayedBatch.Unsigned(
        depositWalletAddress: "0xfAeA0f08159fcF2f573fE24E9E989B0d48f7651B",
        nonce: "7",
        deadline: "1735690200",
        calls: PolymarketApprovalCalls.make()
    )

    static let chainCode = Data(repeating: 0x11, count: 32)
    static let foreignPath = try! DerivationPath(rawPath: "m/44'/60'/0'/0/0")

    struct Context {
        let sut: CommonPolymarketOnboardingSigner
        let signer: PolymarketCardSignerStub
        let keysRepository: KeysRepositoryTestsMock

        init(storeOwnerKey: Bool = true) throws {
            let path = storeOwnerKey ? PolymarketUtilities.derivationPath : foreignPath
            let signer = try PolymarketCardSignerStub()

            self.signer = signer
            keysRepository = KeysRepositoryTestsMock(keys: [
                KeyInfo(
                    publicKey: signer.publicKey,
                    chainCode: chainCode,
                    curve: .secp256k1,
                    isImported: false,
                    derivedKeys: [path: ExtendedPublicKey(publicKey: signer.publicKey, chainCode: chainCode)]
                ),
            ])
            sut = CommonPolymarketOnboardingSigner(keysRepository: keysRepository, signer: signer)
        }
    }
}
