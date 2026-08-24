//
//  PolymarketDepositWalletDeriverTests.swift
//  TangemPolymarketTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
@testable import TangemPolymarket

@Suite("Deposit wallet derivation")
struct PolymarketDepositWalletDeriverTests {
    static let vectors: [(owner: String, depositWallet: String)] = [
        ("0x0491eb219E3D2d05aEF0C35D1079c0a55b19bd2B", "0xdf1a31b50D3F99d4460ACC1Bc99aB2e09BCcC538"),
        ("0xd22b712FAA5f28ebCc3D75aE5356ce8ea2D18F71", "0x5B69409F9bF5034107D361ab3Ac944CF3C74f7D3"),
        ("0x47b7eBE053a75d81cb6F2CC815d077e5057345e5", "0xD6aCb4e9B654e2fD440f490977ED9b686D5D86eb"),
    ]

    @Test("An owner derives the wallet the factory deployed for it", arguments: vectors)
    func matchesTheDeployedWallet(vector: (owner: String, depositWallet: String)) throws {
        #expect(try PolymarketDepositWalletDeriver.derive(ownerAddress: vector.owner) == vector.depositWallet)
    }

    @Test("The derived address is ERC-55 checksummed, not lowercase")
    func isChecksummed() throws {
        let derived = try PolymarketDepositWalletDeriver.derive(ownerAddress: Self.vectors[0].owner)

        #expect(derived != derived.lowercased())
    }

    @Test("The owner address is read regardless of its case")
    func acceptsEitherCase() throws {
        let owner = Self.vectors[0].owner
        let expected = Self.vectors[0].depositWallet

        #expect(try PolymarketDepositWalletDeriver.derive(ownerAddress: owner.lowercased()) == expected)
        #expect(try PolymarketDepositWalletDeriver.derive(ownerAddress: owner.uppercased()) == expected)
    }

    @Test("Anything that is not a twenty byte address is rejected", arguments: [
        "",
        "0x",
        "0491eb219E3D2d05aEF0C35D1079c0a55b19bd2B",
        "0x0491eb219E3D2d05aEF0C35D1079c0a55b19bd",
        "0x0491eb219E3D2d05aEF0C35D1079c0a55b19bd2B00",
        "0x0491eb219E3D2d05aEF0C35D1079c0a55b19bdZZ",
        "0x+491eb219E3D2d05aEF0C35D1079c0a55b19bd2B",
    ])
    func rejectsMalformedOwners(owner: String) {
        #expect(throws: PolymarketDepositWalletError.invalidOwnerAddress) {
            try PolymarketDepositWalletDeriver.derive(ownerAddress: owner)
        }
    }
}
