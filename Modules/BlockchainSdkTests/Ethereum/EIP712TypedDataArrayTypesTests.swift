//
//  EIP712TypedDataArrayTypesTests.swift
//  BlockchainSdkTests
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import TangemSdk
import Testing
@testable import BlockchainSdk

/// Expected hashes are produced by `@metamask/eth-sig-util` (`TypedDataUtils.eip712Hash`, version V4) for the same payloads.
struct EIP712TypedDataArrayTypesTests {
    private let domain: JSON = .object([
        "name": .string("Test"),
        "version": .string("1"),
        "chainId": .number(1),
        "verifyingContract": .string("0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC"),
    ])

    private let domainType = [
        EIP712Type(name: "name", type: "string"),
        EIP712Type(name: "version", type: "string"),
        EIP712Type(name: "chainId", type: "uint256"),
        EIP712Type(name: "verifyingContract", type: "address"),
    ]

    private let itemType = [
        EIP712Type(name: "id", type: "uint256"),
        EIP712Type(name: "name", type: "string"),
    ]

    /// `Item[2]` / `uint256[2]` fields must contribute to the hash; two orders that differ only inside them hash differently.
    @Test
    func fixedSizeArraysAreEncoded() {
        let types: [String: [EIP712Type]] = [
            "Order": [
                EIP712Type(name: "items", type: "Item[2]"),
                EIP712Type(name: "amounts", type: "uint256[2]"),
                EIP712Type(name: "note", type: "string"),
            ],
            "Item": itemType,
        ]

        let order = makeTypedData(types: types, primaryType: "Order", message: makeOrder(itemIDs: [1, 2], amounts: [10, 20]))
        let orderWithOtherItem = makeTypedData(types: types, primaryType: "Order", message: makeOrder(itemIDs: [1, 3], amounts: [10, 20]))
        let orderWithOtherAmount = makeTypedData(types: types, primaryType: "Order", message: makeOrder(itemIDs: [1, 2], amounts: [10, 21]))

        let typeData = String(decoding: order.makeTypeData(primaryType: "Order"), as: UTF8.self)
        #expect(typeData == "Order(Item[2] items,uint256[2] amounts,string note)Item(uint256 id,string name)")

        #expect(order.signHash.hexString.lowercased() == "352498179f3432e8d31d8a34332565aa0547ca27337eeed5140cf58e61074efc")
        #expect(orderWithOtherItem.signHash.hexString.lowercased() == "5c484d7df3213cf72a30ff775683f175ac235333e57c53e28aec8858226222f6")
        #expect(orderWithOtherAmount.signHash.hexString.lowercased() == "814d4f0830f0bf8b1bc16a4553c5d80b5343fedadbe00aa62dbff1de5377b9de")
        #expect(order.signHash != orderWithOtherItem.signHash)
        #expect(order.signHash != orderWithOtherAmount.signHash)
    }

    /// Dynamic struct arrays keep the hash they had before fixed-size arrays were supported.
    @Test
    func dynamicStructArrayIsUnchanged() {
        let types: [String: [EIP712Type]] = [
            "Order": [
                EIP712Type(name: "items", type: "Item[]"),
                EIP712Type(name: "note", type: "string"),
            ],
            "Item": itemType,
        ]
        let message: JSON = .object([
            "items": .array([makeItem(id: 1, name: "a"), makeItem(id: 2, name: "b")]),
            "note": .string("n"),
        ])

        let typedData = makeTypedData(types: types, primaryType: "Order", message: message)
        #expect(typedData.signHash.hexString.lowercased() == "b49f532e37dd95bcbfc314e944678a4f953d21fce4fb31a5dfb3d00bf0d7f39e")
    }

    /// Nested arrays are encoded level by level.
    @Test
    func nestedPrimitiveArrayIsEncoded() {
        let types: [String: [EIP712Type]] = [
            "Grid": [EIP712Type(name: "cells", type: "uint256[2][]")],
        ]
        let message: JSON = .object([
            "cells": .array([
                .array([.number(1), .number(2)]),
                .array([.number(3), .number(4)]),
            ]),
        ])

        let typedData = makeTypedData(types: types, primaryType: "Grid", message: message)
        #expect(typedData.signHash.hexString.lowercased() == "a034fbf04063a221f478cbbc6b25e7fd76b6e17fedd7c97a90a3458f38dde2c2")
    }

    /// A struct whose name merely starts with a primitive name (`stringData`) is a struct, not a primitive.
    @Test
    func structNamedLikePrimitiveIsEncodedAsStruct() {
        let types: [String: [EIP712Type]] = [
            "Mail": [
                EIP712Type(name: "payload", type: "stringData"),
                EIP712Type(name: "to", type: "address"),
            ],
            "stringData": [EIP712Type(name: "x", type: "string")],
        ]
        let message: JSON = .object([
            "payload": .object(["x": .string("hello")]),
            "to": .string("0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB"),
        ])

        let typedData = makeTypedData(types: types, primaryType: "Mail", message: message)

        let typeData = String(decoding: typedData.makeTypeData(primaryType: "Mail"), as: UTF8.self)
        #expect(typeData == "Mail(stringData payload,address to)stringData(string x)")
        #expect(typedData.signHash.hexString.lowercased() == "9e749ce1a2d685e23a7c6afd66d426074207dc21ce88a74dc9ca56a77aea8153")
    }

    private func makeTypedData(types: [String: [EIP712Type]], primaryType: String, message: JSON) -> EIP712TypedData {
        var allTypes = types
        allTypes["EIP712Domain"] = domainType
        return EIP712TypedData(types: allTypes, primaryType: primaryType, domain: domain, message: message)
    }

    private func makeItem(id: Int, name: String) -> JSON {
        .object(["id": .number(id), "name": .string(name)])
    }

    private func makeOrder(itemIDs: [Int], amounts: [Int]) -> JSON {
        .object([
            "items": .array([makeItem(id: itemIDs[0], name: "a"), makeItem(id: itemIDs[1], name: "b")]),
            "amounts": .array(amounts.map { .number($0) }),
            "note": .string("n"),
        ])
    }
}
