//
//  TangemPayOfframpOptionsStoreTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import TangemUI
@testable import Tangem

@Suite("TangemPayOfframpOptionsStore")
struct TangemPayOfframpOptionsStoreTests {
    @Test("Available tokens come before unavailable ones")
    func sortedForSelection_availableFirst() {
        let items = [
            makeItem(symbol: "USDT", chainId: 137, isAvailable: false),
            makeItem(symbol: "USDC", chainId: 137, isAvailable: true),
            makeItem(symbol: "USDC", chainId: 8453, isAvailable: false),
            makeItem(symbol: "USDT", chainId: 8453, isAvailable: true),
        ]

        let sorted = TangemPayOfframpOptionsStore.sortedForSelection(items)

        #expect(sorted.map(\.id) == ["137-usdc", "8453-usdt", "8453-usdc", "137-usdt"])
    }

    @Test("Within an availability group USDC goes first and the original order is kept")
    func sortedForSelection_symbolMajorWithinGroup() {
        let items = [
            makeItem(symbol: "USDT", chainId: 137, isAvailable: true),
            makeItem(symbol: "USDC", chainId: 8453, isAvailable: true),
            makeItem(symbol: "USDT", chainId: 56, isAvailable: true),
            makeItem(symbol: "USDC", chainId: 42161, isAvailable: true),
        ]

        let sorted = TangemPayOfframpOptionsStore.sortedForSelection(items)

        #expect(sorted.map(\.id) == ["8453-usdc", "42161-usdc", "137-usdt", "56-usdt"])
    }

    @Test("Unavailable tokens keep the symbol-major order among themselves")
    func sortedForSelection_unavailableGroupOrder() {
        let items = [
            makeItem(symbol: "USDT", chainId: 137, isAvailable: false),
            makeItem(symbol: "USDC", chainId: 56, isAvailable: false),
            makeItem(symbol: "USDC", chainId: 8453, isAvailable: true),
            makeItem(symbol: "USDT", chainId: 8453, isAvailable: false),
        ]

        let sorted = TangemPayOfframpOptionsStore.sortedForSelection(items)

        #expect(sorted.map(\.id) == ["8453-usdc", "56-usdc", "137-usdt", "8453-usdt"])
    }
}

// MARK: - Helpers

private extension TangemPayOfframpOptionsStoreTests {
    func makeItem(symbol: String, chainId: Int, isAvailable: Bool) -> TransferInputTokenItem {
        TransferInputTokenItem(
            id: "\(chainId)-\(symbol.lowercased())",
            tokenIconInfo: .remote(name: symbol, imageURL: nil),
            symbol: symbol,
            networkName: "\(chainId)",
            balance: 100,
            balanceText: "$100",
            chainId: chainId,
            contractAddress: "0x\(symbol.lowercased())",
            isOfframpAvailable: isAvailable
        )
    }
}
