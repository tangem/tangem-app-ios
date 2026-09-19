//
//  ArrayExtensionsTests.swift
//  TangemTests
//
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Foundation
import Testing
import BlockchainSdk
@testable import Tangem

@Suite("Array.insert(_:) / Array.remove(_:)")
struct ArrayExtensionsTests {
    @Test("insert appends a new element at the end and keeps the existing order")
    func insertAppendsNewElement() {
        var array = ["a", "b", "c"]

        array.insert("d")

        #expect(array == ["a", "b", "c", "d"])
    }

    @Test("insert is a no-op when an equal element is already present")
    func insertIgnoresExistingElement() {
        var array = ["a", "b", "c"]

        array.insert("b")

        #expect(array == ["a", "b", "c"])
    }

    @Test("insert into an empty array")
    func insertIntoEmptyArray() {
        var array: [Int] = []

        array.insert(42)

        #expect(array == [42])
    }

    @Test("remove drops the element and keeps the remaining elements in place")
    func removeKeepsOrder() {
        var array = ["a", "b", "c", "d"]

        array.remove("b")

        #expect(array == ["a", "c", "d"])
    }

    @Test("remove drops every equal element")
    func removeDropsAllOccurrences() {
        var array = ["a", "b", "a", "c", "a"]

        array.remove("a")

        #expect(array == ["b", "c"])
    }

    @Test("remove is a no-op when the element is absent")
    func removeIgnoresAbsentElement() {
        var array = ["a", "b", "c"]

        array.remove("z")

        #expect(array == ["a", "b", "c"])
    }

    @Test("insert followed by remove restores the original array")
    func insertThenRemoveRoundTrip() {
        let original = ["a", "b", "c"]
        var array = original

        array.insert("x")
        array.remove("x")

        #expect(array == original)
    }

    @Test("[TokenItem] keeps its selection order after removing a pending item")
    func tokenItemsKeepOrder() {
        let bitcoin = TokenItem.blockchain(.init(.bitcoin(testnet: false), derivationPath: nil))
        let ethereum = TokenItem.blockchain(.init(.ethereum(testnet: false), derivationPath: nil))
        let solana = TokenItem.blockchain(.init(.solana(curve: .ed25519, testnet: false), derivationPath: nil))
        var pending = [bitcoin, ethereum, solana]

        pending.remove(ethereum)

        #expect(pending == [bitcoin, solana])
    }
}
