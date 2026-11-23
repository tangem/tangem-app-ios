//
//  PolymarketBatchSignerTests.swift
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

@Suite("Polymarket batch signer")
struct PolymarketBatchSignerTests {
    @Test("The batches and the owner's CLOB sign-in are signed in one card session, the sign-in last and each signature on its own payload")
    func ownerSignInIsSignedLast() async throws {
        let (sut, signer) = try makeSUT()

        let signed = try await sut.sign([Self.firstBatch, Self.secondBatch], ownerAuthTimestamp: Self.timestamp, as: Self.ownerAddress)
        let firstDigest = try PolymarketRelayedBatchSigning.digest(for: Self.firstBatch)
        let secondDigest = try PolymarketRelayedBatchSigning.digest(for: Self.secondBatch)
        let authDigest = PolymarketClobAuth.digest(ownerAddress: Self.ownerAddress, timestamp: Self.timestamp)
        let firstSignature = try #require(signer.signature(over: firstDigest))
        let secondSignature = try #require(signer.signature(over: secondDigest))
        let authSignature = try #require(signer.signature(over: authDigest))

        #expect(signer.signCalls == 1)
        #expect(signer.requestedHashes == [firstDigest, secondDigest, authDigest])
        #expect(signed.batches == [
            Self.firstBatch.signed(by: Self.ownerAddress, signature: firstSignature),
            Self.secondBatch.signed(by: Self.ownerAddress, signature: secondSignature),
        ])
        #expect(signed.ownerAuthHeaders == PolymarketCLOBAuthHeaders(
            ownerAddress: Self.ownerAddress,
            signature: authSignature,
            timestamp: Self.timestamp,
            nonce: PolymarketClobAuth.nonce
        ))
    }

    @Test("Without an owner sign-in only the batches reach the card and no CLOB headers come back")
    func batchesAloneAreSigned() async throws {
        let (sut, signer) = try makeSUT()

        let signed = try await sut.sign([Self.firstBatch, Self.secondBatch], ownerAuthTimestamp: nil, as: Self.ownerAddress)
        let firstDigest = try PolymarketRelayedBatchSigning.digest(for: Self.firstBatch)
        let secondDigest = try PolymarketRelayedBatchSigning.digest(for: Self.secondBatch)

        #expect(signer.requestedHashes == [firstDigest, secondDigest])
        #expect(signed.ownerAuthHeaders == nil)
    }
}

// MARK: - Helpers

private extension PolymarketBatchSignerTests {
    static let ownerAddress = PolymarketOwnerAddressProviderStub.ownerAddress
    static let timestamp = "1789430400"
    static let chainCode = Data(repeating: 0x11, count: 32)

    static let firstBatch = PolymarketRelayedBatch.Unsigned(
        depositWalletAddress: "0xfAeA0f08159fcF2f573fE24E9E989B0d48f7651B",
        nonce: "7",
        deadline: "1789431000",
        calls: PolymarketApprovalCalls.make()
    )

    static let secondBatch = PolymarketRelayedBatch.Unsigned(
        depositWalletAddress: "0xfAeA0f08159fcF2f573fE24E9E989B0d48f7651B",
        nonce: "8",
        deadline: "1789431600",
        calls: PolymarketApprovalCalls.make()
    )

    func makeSUT() throws -> (sut: PolymarketBatchSigner, signer: PolymarketCardSignerStub) {
        let signer = try PolymarketCardSignerStub()
        let keysRepository = KeysRepositoryTestsMock(keys: [
            KeyInfo(
                publicKey: signer.publicKey,
                chainCode: Self.chainCode,
                curve: .secp256k1,
                isImported: false,
                derivedKeys: [
                    PolymarketUtilities.derivationPath: ExtendedPublicKey(publicKey: signer.publicKey, chainCode: Self.chainCode),
                ]
            ),
        ])

        return (PolymarketBatchSigner(keysRepository: keysRepository, signer: signer), signer)
    }
}
