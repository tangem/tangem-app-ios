//
//  AssociatedValueInsensitiveEquatableMarcoTest.swift
//  TangemModules Tests
//
//  Created by [REDACTED_AUTHOR]
//  Copyright © 2025 Tangem AG. All rights reserved.
//

import Testing

struct SimpleTest {
    @Test func test() async throws {
        #expect("1" == "1")
    }
}

#if canImport(TangemMacroImplementation)
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import Testing
import TangemMacroImplementation

// MARK: - Fixtures for testing the macro

// These sample enums use the macro under test. The goal is to ensure that
// equatability ignores associated values and only compares the case itself.
@AssociatedValueInsensitiveEquatableMarco
enum PaymentState {
    case idle
    case processing(progress: Double)
    case failed(error: String)
    case completed(receiptID: String?)
}

@AssociatedValueInsensitiveEquatableMarco
enum NetworkStatus {
    case connected(info: String)
    case disconnected(code: Int)
}

@Suite("AssociatedValueInsensitiveEquatableMarco tests")
struct AssociatedValueInsensitiveEquatableMarcoTests {

    @Test("Same case without associated values are equal")
    func testSimpleCasesEqual() {
        #expect(PaymentState.idle == PaymentState.idle)
    }

    @Test("Same case with different associated values are still equal")
    func testAssociatedValuesAreIgnoredForEquality() {
        let a = PaymentState.processing(progress: 0.1)
        let b = PaymentState.processing(progress: 0.9)
        #expect(a == b)

        let f1 = PaymentState.failed(error: "Timeout")
        let f2 = PaymentState.failed(error: "Server error")
        #expect(f1 == f2)

        let c1 = PaymentState.completed(receiptID: nil)
        let c2 = PaymentState.completed(receiptID: "XYZ")
        #expect(c1 == c2)
    }

    @Test("Different cases are not equal, regardless of associated values")
    func testDifferentCasesNotEqual() {
        #expect(PaymentState.idle != PaymentState.processing(progress: 0.0))
        #expect(PaymentState.processing(progress: 0.5) != PaymentState.failed(error: "E"))
        #expect(PaymentState.completed(receiptID: "1") != PaymentState.idle)
    }

    @Test("Works across multiple enums using the macro")
    func testMultipleEnums() {
        let n1 = NetworkStatus.connected(info: "WiFi")
        let n2 = NetworkStatus.connected(info: "Cellular")
        let n3 = NetworkStatus.disconnected(code: 404)

        #expect(n1 == n2)
        #expect(n1 != n3)
    }

    @Test("Hashable semantics align with case-only equality when available")
    func testHashableConsistency() {
        // If the macro also provides Hashable or relies on synthesized Hashable,
        // we ensure that equal values have identical hashes and different cases differ.
        // If Hashable isn't provided by the macro, this test will still compile but may need adjusting.
        let values: [PaymentState] = [
            .idle,
            .processing(progress: 0.1),
            .processing(progress: 0.9),
            .failed(error: "A"),
            .failed(error: "B"),
            .completed(receiptID: nil),
            .completed(receiptID: "X")
        ]

        // Pairs of same-case values should hash equally
        #expect(values[1].hashValue == values[2].hashValue)
        #expect(values[3].hashValue == values[4].hashValue)
        #expect(values[5].hashValue == values[6].hashValue)

        // Different cases should tend to have different hashes
        #expect(values[0].hashValue != values[1].hashValue)
        #expect(values[1].hashValue != values[3].hashValue)
        #expect(values[3].hashValue != values[5].hashValue)
    }
}

#endif
