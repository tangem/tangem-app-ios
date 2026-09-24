//
//  EIP712TypedDataDependenciesTests.swift
//  BlockchainSdkTests
//
//  Created by Dean Rie
//  Copyright © 2026 Tangem AG. All rights reserved.
//

import Testing
@testable import BlockchainSdk

struct EIP712TypedDataDependenciesTests {
    private let domain: JSON = .object([
        "name": .string("Test"),
        "version": .string("1"),
        "chainId": .number(1),
        "verifyingContract": .string("0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC"),
    ])

    /// A dApp-supplied `types` dictionary with a 30_000-deep chain T0 -> T1 -> ... must not overflow the stack.
    @Test
    func deepLinearChainDoesNotOverflowTheStack() throws {
        let depth = 30_000
        var types: [String: [EIP712Type]] = [
            "EIP712Domain": [
                EIP712Type(name: "name", type: "string"),
                EIP712Type(name: "version", type: "string"),
                EIP712Type(name: "chainId", type: "uint256"),
                EIP712Type(name: "verifyingContract", type: "address"),
            ],
        ]
        for index in 0 ..< depth {
            types["T\(index)"] = [EIP712Type(name: "next", type: "T\(index + 1)")]
        }
        types["T\(depth)"] = [EIP712Type(name: "value", type: "uint256")]

        let typedData = EIP712TypedData(
            types: types,
            primaryType: "T0",
            domain: domain,
            message: .object(["next": .object([:])])
        )

        let typeData = String(decoding: typedData.makeTypeData(primaryType: "T0"), as: UTF8.self)
        #expect(typeData.hasPrefix("T0(T1 next)T1(T2 next)"))
        #expect(typeData.hasSuffix("T\(depth)(uint256 value)"))
        #expect(typedData.typeHash.count == 32)
        #expect(typedData.signHash.count == 32)
    }

    /// Mutually recursive types (A <-> B) are listed exactly once each.
    @Test
    func cyclicTypesAreResolvedOnce() throws {
        let types: [String: [EIP712Type]] = [
            "A": [
                EIP712Type(name: "b", type: "B"),
                EIP712Type(name: "name", type: "string"),
            ],
            "B": [
                EIP712Type(name: "a", type: "A"),
                EIP712Type(name: "items", type: "A[]"),
            ],
        ]
        let typedData = EIP712TypedData(types: types, primaryType: "A", domain: .null, message: .null)

        let typeData = String(decoding: typedData.makeTypeData(primaryType: "A"), as: UTF8.self)
        #expect(typeData == "A(B b,string name)B(A a,A[] items)")

        let typeDataFromB = String(decoding: typedData.makeTypeData(primaryType: "B"), as: UTF8.self)
        #expect(typeDataFromB == "B(A a,A[] items)A(B b,string name)")
    }
}
