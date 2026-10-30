//
//  PolymarketOrderSigningTests.swift
//  TangemPolymarketTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemFoundation
import TangemSdk
@testable import TangemPolymarket

@Suite("PolymarketOrderSigning")
struct PolymarketOrderSigningTests {
    // MARK: - Digest

    @Test("The nested digest matches the vector the Android build signs")
    func digestMatchesVector() throws {
        let digest = try PolymarketOrderSigning.digest(
            order: Self.order,
            domain: .ctfExchange,
            depositWalletAddress: Self.depositWallet
        )

        #expect(digest.hexString.lowercased() == "c36551f13eb9491a93253a7125e9d72b9dee9b7a1bc1c4d2f0c33c684d566324")
    }

    @Test("A neg-risk market only changes the outer domain")
    func negRiskDigestMatchesVector() throws {
        let digest = try PolymarketOrderSigning.digest(
            order: Self.order,
            domain: .negRiskCtfExchange,
            depositWalletAddress: Self.depositWallet
        )

        #expect(digest.hexString.lowercased() == "97d4ba244f6511157a7682dbe340477437aa5db39aa5ccd87b221604164dbeca")
    }

    @Test("A V2 order signs for ExchangeV3 under domain version 3")
    func exchangeV3DigestMatchesVector() throws {
        let digest = try PolymarketOrderSigning.digest(
            order: Self.order,
            domain: .exchangeV3,
            depositWalletAddress: Self.depositWallet
        )

        #expect(digest.hexString.lowercased() == "c6aa11eb9fb04bbc85c50287c29ac221b06515f7d6462525be1d9785d7745f5d")
    }

    @Test("The domain version is part of what is signed, not only the exchange address")
    func domainVersionChangesTheDigest() throws {
        let wrongVersion = PolymarketExchangeDomain(address: PolymarketApprovalContracts.exchangeV3, version: "2")

        let digest = try PolymarketOrderSigning.digest(
            order: Self.order,
            domain: wrongVersion,
            depositWalletAddress: Self.depositWallet
        )

        #expect(digest.hexString.lowercased() == "b7661215cb5b2a3b49271317da518711f8030aed787bea880513d313583d922a")
    }

    @Test("The V2 tail carries the ExchangeV3 domain separator and the same order hash")
    func exchangeV3WrapCarriesTheTail() throws {
        let wrapped = try PolymarketOrderSigning.wrap(
            signature: Self.innerSignature,
            order: Self.order,
            domain: .exchangeV3
        )

        let tail = Self.tail(of: wrapped)

        #expect(tail.prefix(Self.wordDigits) == "466c63910185bbd55e8679264200c4e0abdcbb0c6264eb3d41d13326022e095b")
        #expect(tail.dropFirst(Self.wordDigits).prefix(Self.wordDigits) == "345bc1910f4a991a6b3deb33f798f6fbb2536a185d922c896dd8daee671bcd05")
    }

    @Test("The two exchanges never produce the same digest for one order")
    func exchangesDoNotCollide() throws {
        let standard = try PolymarketOrderSigning.digest(
            order: Self.order,
            domain: .ctfExchange,
            depositWalletAddress: Self.depositWallet
        )

        let negRisk = try PolymarketOrderSigning.digest(
            order: Self.order,
            domain: .negRiskCtfExchange,
            depositWalletAddress: Self.depositWallet
        )

        #expect(standard != negRisk)
    }

    @Test("The deposit wallet is part of what is signed")
    func depositWalletChangesTheDigest() throws {
        let mine = try PolymarketOrderSigning.digest(
            order: Self.order,
            domain: .ctfExchange,
            depositWalletAddress: Self.depositWallet
        )

        let other = try PolymarketOrderSigning.digest(
            order: Self.order,
            domain: .ctfExchange,
            depositWalletAddress: "0x4130efa9e628a991520be60f2e948a4f9be52fbc"
        )

        #expect(mine != other)
    }

    @Test("Every leg of the order is part of what is signed", arguments: PolymarketOrderMutation.allCases)
    func everyFieldChangesTheDigest(_ mutation: PolymarketOrderMutation) throws {
        let original = try PolymarketOrderSigning.digest(
            order: Self.order,
            domain: .ctfExchange,
            depositWalletAddress: Self.depositWallet
        )

        let mutated = try PolymarketOrderSigning.digest(
            order: mutation.apply(to: Self.order),
            domain: .ctfExchange,
            depositWalletAddress: Self.depositWallet
        )

        #expect(original != mutated)
    }

    // MARK: - Wrapping

    @Test("The wrapped signature keeps the card's own signature at the front")
    func wrapKeepsInnerSignature() throws {
        let wrapped = try PolymarketOrderSigning.wrap(
            signature: Self.innerSignature,
            order: Self.order,
            domain: .ctfExchange
        )

        #expect(wrapped.hasPrefix(Self.innerSignature))
    }

    @Test("The tail carries the domain separator and the order hash")
    func wrapCarriesTheTail() throws {
        let wrapped = try PolymarketOrderSigning.wrap(
            signature: Self.innerSignature,
            order: Self.order,
            domain: .ctfExchange
        )

        #expect(wrapped.contains("3264e159346253e26a64e00b69032db0e7d32f94628de3e6eecb50304d7af3d2"))
        #expect(wrapped.contains("345bc1910f4a991a6b3deb33f798f6fbb2536a185d922c896dd8daee671bcd05"))
    }

    @Test("The tail ends with the length of the type description")
    func wrapEndsWithTheDescriptionLength() throws {
        let wrapped = try PolymarketOrderSigning.wrap(
            signature: Self.innerSignature,
            order: Self.order,
            domain: .ctfExchange
        )

        #expect(wrapped.hasSuffix("00ba"))
    }

    @Test("The tail after the signature is 252 bytes")
    func wrapTailSize() throws {
        let wrapped = try PolymarketOrderSigning.wrap(
            signature: Self.innerSignature,
            order: Self.order,
            domain: .ctfExchange
        )

        let tail = wrapped.removeHexPrefix().count - Self.innerSignature.removeHexPrefix().count

        #expect(tail / 2 == 252)
    }

    @Test("The tail carries the domain of the exchange the order goes to")
    func wrapCarriesTheNegRiskDomain() throws {
        let standard = try PolymarketOrderSigning.wrap(
            signature: Self.innerSignature,
            order: Self.order,
            domain: .ctfExchange
        )

        let negRisk = try PolymarketOrderSigning.wrap(
            signature: Self.innerSignature,
            order: Self.order,
            domain: .negRiskCtfExchange
        )

        let standardTail = Self.tail(of: standard)
        let negRiskTail = Self.tail(of: negRisk)

        #expect(standardTail.prefix(Self.wordDigits) != negRiskTail.prefix(Self.wordDigits))
        #expect(standardTail.dropFirst(Self.wordDigits) == negRiskTail.dropFirst(Self.wordDigits))
    }

    @Test("A wrapped signature reads as prefixed lowercase hex")
    func wrapIsPrefixedHex() throws {
        let wrapped = try PolymarketOrderSigning.wrap(
            signature: Self.innerSignature.uppercased(),
            order: Self.order,
            domain: .ctfExchange
        )

        #expect(wrapped.hasPrefix("0x"))
        #expect(wrapped == wrapped.lowercased())
    }

    // MARK: - Refusals

    @Test("An address that is not twenty bytes is refused", arguments: [
        "0x4130efa9e628a991520be60f2e948a4f9be52fb",
        "0x4130efa9e628a991520be60f2e948a4f9be52fbcaa",
        "",
    ])
    func invalidAddressIsRefused(_ address: String) {
        #expect(throws: PolymarketOrderSigningError.invalidAddress(address)) {
            try PolymarketOrderSigning.digest(
                order: Self.order,
                domain: .ctfExchange,
                depositWalletAddress: address
            )
        }
    }

    @Test("A word that is not thirty two bytes is refused")
    func invalidWordIsRefused() {
        let order = Self.order.replacing(builder: "0x00aa")

        #expect(throws: PolymarketOrderSigningError.invalidWord("0x00aa")) {
            try PolymarketOrderSigning.digest(
                order: order,
                domain: .ctfExchange,
                depositWalletAddress: Self.depositWallet
            )
        }
    }

    @Test("An amount that is not a decimal number is refused", arguments: ["", "12.5", "-1", "0x10", "1e5"])
    func invalidAmountIsRefused(_ amount: String) {
        let order = Self.order.replacing(makerAmount: amount)

        #expect(throws: PolymarketOrderSigningError.invalidAmount(amount)) {
            try PolymarketOrderSigning.digest(
                order: order,
                domain: .ctfExchange,
                depositWalletAddress: Self.depositWallet
            )
        }
    }

    @Test("A number wider than a word is refused")
    func oversizedAmountIsRefused() {
        let amount = String(repeating: "9", count: 78)
        let order = Self.order.replacing(makerAmount: amount)

        #expect(throws: PolymarketOrderSigningError.invalidAmount(amount)) {
            try PolymarketOrderSigning.digest(
                order: order,
                domain: .ctfExchange,
                depositWalletAddress: Self.depositWallet
            )
        }
    }

    @Test("Zero and its padded spellings are the same word")
    func zeroIsEncodedOnce() throws {
        let plain = try PolymarketOrderSigning.digest(
            order: Self.order.replacing(makerAmount: "0"),
            domain: .ctfExchange,
            depositWalletAddress: Self.depositWallet
        )

        let padded = try PolymarketOrderSigning.digest(
            order: Self.order.replacing(makerAmount: "0000"),
            domain: .ctfExchange,
            depositWalletAddress: Self.depositWallet
        )

        #expect(plain == padded)
    }

    @Test("The widest number a word holds is accepted")
    func maxWordIsAccepted() throws {
        let amount = "115792089237316195423570985008687907853269984665640564039457584007913129639935"

        let digest = try PolymarketOrderSigning.digest(
            order: Self.order.replacing(makerAmount: amount),
            domain: .ctfExchange,
            depositWalletAddress: Self.depositWallet
        )

        #expect(!digest.isEmpty)
    }
}

// MARK: - Fixtures

private extension PolymarketOrderSigningTests {
    static let depositWallet = "0x5A057dc6394196fBa51D84457DA3FB8FA241Fc20"
    static let innerSignature = "0x" + String(repeating: "11", count: 65)
    static let wordDigits = 64

    static func tail(of wrapped: String) -> Substring {
        wrapped.removeHexPrefix().dropFirst(innerSignature.removeHexPrefix().count)
    }

    static let order = PolymarketOrder(
        salt: 1_234_567_890,
        maker: depositWallet,
        signer: "0x4130efa9e628a991520be60f2e948a4f9be52fbc",
        tokenId: "1116017998421700000000000000000000000000000000000000000000000000047",
        makerAmount: "72000000",
        takerAmount: "97959180",
        side: .buy,
        timestampMillis: 1_787_300_000_000,
        builder: "0x00000000000000000000000000000000000000000000000000000000000000aa"
    )
}

// MARK: - Mutations

enum PolymarketOrderMutation: CaseIterable {
    case salt
    case maker
    case signer
    case tokenId
    case makerAmount
    case takerAmount
    case side
    case timestamp
    case metadata
    case builder

    func apply(to order: PolymarketOrder) -> PolymarketOrder {
        switch self {
        case .salt: order.replacing(salt: order.salt + 1)
        case .maker: order.replacing(maker: "0x4130efa9e628a991520be60f2e948a4f9be52fbc")
        case .signer: order.replacing(signer: "0x5A057dc6394196fBa51D84457DA3FB8FA241Fc20")
        case .tokenId: order.replacing(tokenId: "48")
        case .makerAmount: order.replacing(makerAmount: "72000001")
        case .takerAmount: order.replacing(takerAmount: "97959181")
        case .side: order.replacing(side: .sell)
        case .timestamp: order.replacing(timestampMillis: order.timestampMillis + 1)
        case .metadata: order.replacing(metadata: "0x" + String(repeating: "0", count: 63) + "1")
        case .builder: order.replacing(builder: PolymarketExchange.emptyWord)
        }
    }
}

// MARK: - Replacing

extension PolymarketOrder {
    func replacing(
        salt: UInt64? = nil,
        maker: String? = nil,
        signer: String? = nil,
        tokenId: String? = nil,
        makerAmount: String? = nil,
        takerAmount: String? = nil,
        side: PolymarketOrderSide? = nil,
        timestampMillis: UInt64? = nil,
        metadata: String? = nil,
        builder: String? = nil
    ) -> PolymarketOrder {
        PolymarketOrder(
            salt: salt ?? self.salt,
            maker: maker ?? self.maker,
            signer: signer ?? self.signer,
            tokenId: tokenId ?? self.tokenId,
            makerAmount: makerAmount ?? self.makerAmount,
            takerAmount: takerAmount ?? self.takerAmount,
            side: side ?? self.side,
            signatureType: signatureType,
            timestampMillis: timestampMillis ?? self.timestampMillis,
            metadata: metadata ?? self.metadata,
            builder: builder ?? self.builder
        )
    }
}
